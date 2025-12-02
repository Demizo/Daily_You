import 'dart:io';
import 'dart:isolate';

import 'package:daily_you/entries_database.dart';
import 'package:daily_you/file_bytes_cache.dart';
import 'package:daily_you/file_layer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pool/pool.dart';
import 'package:image/image.dart' as img;

class ResizeRequest {
  final String key;
  final String originalPath;
  final int width;

  ResizeRequest(this.key, this.originalPath, this.width);
}

class ResizeResponse {
  final String key;

  ResizeResponse(this.key);
}

class LocalImageCache {
  static final LocalImageCache instance = LocalImageCache._internal();

  final CacheManager _diskCache;
  String? tempImgFolderPath;
  final _pending = <String>{};
  final MemoryImageCache imageCache =
      MemoryImageCache(maxCacheSize: 10 * 1024 * 1024);
  final Pool imgFetchPool = Pool(5);

  SendPort? _resizeSendPort;

  LocalImageCache._internal()
      : _diskCache = CacheManager(
          Config(
            'resizedImages',
            stalePeriod: const Duration(days: 7),
            maxNrOfCacheObjects: 2000,
          ),
        ) {
    _initResizeIsolate();
  }

  Future<void> _initResizeIsolate() async {
    final imgFolderPath =
        await EntriesDatabase.instance.getInternalImgDatabasePath();
    tempImgFolderPath = (await getTemporaryDirectory()).path;

    final responsePort = ReceivePort();
    responsePort.listen(_listenForResults);
    RootIsolateToken isolateToken = RootIsolateToken.instance!;
    await Isolate.spawn(imageResizerIsolate, {
      "token": isolateToken,
      "port": responsePort.sendPort,
      "imgFolderPath": imgFolderPath,
      "tempImgFolderPath": tempImgFolderPath
    });
  }

  void _listenForResults(dynamic message) async {
    if (message is SendPort) {
      _resizeSendPort = message;
    } else if (message is ResizeResponse) {
      final key = message.key;
      final bytes = await FileLayer.getFileBytes(tempImgFolderPath!,
          name: "$key.jpg", useExternalPath: false);

      if (bytes != null) {
        // imageCache.put(key, MemoryImage(bytes));
        await _diskCache.putFile(key, bytes, fileExtension: 'jpg');
        await FileLayer.deleteFile(tempImgFolderPath!,
            name: "$key.jpg", useExternalPath: false);
      }

      _pending.remove(key);
    }
  }

  Future<void> primeCache(String originalPath, int width) async {
    final key = '${originalPath}_w$width';

    if (_resizeSendPort == null ||
        _pending.contains(key) ||
        _pending.length >= 30) {
      return;
    }

    _pending.add(key);
    final request = ResizeRequest(key, originalPath, width);
    _resizeSendPort!.send(request);
  }

  Future<MemoryImage?> getCachedImage(String originalPath, int width) async {
    final key = '${originalPath}_w$width';

    // Memory cache
    final image = imageCache.get(key);
    if (image != null) {
      return image;
    }

    return imgFetchPool.withResource(() async {
      // Don't cache GIFs on disk
      if (extension(originalPath).toLowerCase() == ".gif") {
        final bytes = await EntriesDatabase.instance.getImgBytes(originalPath);
        if (bytes != null) {
          final image = MemoryImage(bytes);
          imageCache.put(key, image);
          return image;
        } else {
          return null;
        }
      }

      // Disk cache
      final fileInfo = await _diskCache.getFileFromCache(key);
      if (fileInfo != null) {
        final bytes = await fileInfo.file.readAsBytes();
        final image = MemoryImage(bytes);
        imageCache.put(key, image);
        return image;
      }

      return null;
    });
  }

  Future<Uint8List?> getImageBytes(String originalPath, int width) async {
    // Prime cache in the background
    primeCache(originalPath, width);

    final originalBytes =
        await EntriesDatabase.instance.getImgBytes(originalPath);
    if (originalBytes == null) return null;

    return originalBytes;
  }
}

void imageResizerIsolate(Map<String, dynamic> args) async {
  // Allow for plugin usage in isolate
  BackgroundIsolateBinaryMessenger.ensureInitialized(args["token"]);

  final receivePort = ReceivePort();
  SendPort mainSendPort = args["port"];
  String imgFolderPath = args["imgFolderPath"];
  String tempImgFolderPath = args["tempImgFolderPath"];
  mainSendPort.send(receivePort.sendPort);

  await for (final dynamic message in receivePort) {
    if (message is ResizeRequest) {
      final key = message.key;
      try {
        final originalPath = message.originalPath;
        final width = message.width;

        if (Platform.isAndroid) {
          await FlutterImageCompress.compressAndGetFile(
              join(imgFolderPath, originalPath),
              join(tempImgFolderPath, "$key.jpg"),
              quality: 85,
              minWidth: width,
              minHeight: width);
        } else {
          final cmd = img.Command()
            ..decodeJpgFile(join(imgFolderPath, originalPath))
            ..copyResize(width: width, interpolation: img.Interpolation.average)
            ..encodeJpgFile(join(tempImgFolderPath, "$key.jpg"), quality: 85);
          await cmd.executeThread();
        }

        mainSendPort.send(ResizeResponse(key));
      } catch (_) {
        mainSendPort.send(ResizeResponse(key));
      }
    }
  }
}
