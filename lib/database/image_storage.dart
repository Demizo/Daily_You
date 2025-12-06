import 'dart:io';
import 'dart:typed_data';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/file_bytes_cache.dart';
import 'package:daily_you/file_layer.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pool/pool.dart';

class ImageStorage {
  static final ImageStorage instance = ImageStorage._init();

  ImageStorage._init();

  final FileBytesCache imageCache =
      FileBytesCache(maxCacheSize: 10 * 1024 * 1024);
  final Pool imgFetchPool = Pool(3);

  bool usingExternalLocation() {
    return ConfigProvider.instance.get(ConfigKey.useExternalImg) ?? false;
  }

  Future<String> getInternalFolder() async {
    Directory basePath;
    if (Platform.isAndroid) {
      basePath = (await getExternalStorageDirectory())!;
      basePath = Directory('${basePath.path}/Images');
      if (!basePath.existsSync()) {
        basePath.createSync(recursive: true);
      }
      return basePath.path;
    } else {
      basePath = await getApplicationSupportDirectory();
      basePath = Directory('${basePath.path}/Images');
      if (!basePath.existsSync()) {
        basePath.createSync(recursive: true);
      }

      return basePath.path;
    }
  }

  Future<String> getExternalFolder() async {
    final rootImgPath = ConfigProvider.instance.get(ConfigKey.externalImgUri);
    return rootImgPath;
  }

  Future<Uint8List?> getBytes(String imageName) async {
    // Fetch cache copy if present
    var bytes = imageCache.get(imageName);
    if (bytes != null) {
      return bytes;
    }
    // Fetch local copy if present
    var internalDir = await getInternalFolder();
    bytes = await imgFetchPool.withResource(() => FileLayer.getFileBytes(
        internalDir,
        name: imageName,
        useExternalPath: false));
    // Attempt to fetch file externally
    if (bytes == null && usingExternalLocation()) {
      // Get and cache external image
      bytes = await FileLayer.getFileBytes(await getExternalFolder(),
          name: imageName, useExternalPath: true);
      if (bytes != null) {
        await FileLayer.createFile(await getInternalFolder(), imageName, bytes,
            useExternalPath: false);
      }
    }
    if (bytes != null) {
      imageCache.put(imageName, bytes);
    }
    return bytes;
  }

  Future<String?> create(String? imageName, Uint8List bytes,
      {DateTime? currTime}) async {
    currTime ??= DateTime.now();

    // Don't make a copy of files already in the folder
    if (imageName != null && await getBytes(imageName) != null) {
      return imageName;
    }

    var extenstion = imageName != null ? extension(imageName) : ".jpg";

    final timestamp =
        currTime.toIso8601String().split('.').first.replaceAll(':', '-');

    var newImageName = "daily_you_$timestamp$extenstion";

    // Ensure unique name
    int index = 1;
    while (await FileLayer.exists(await getInternalFolder(),
        name: newImageName, useExternalPath: false)) {
      newImageName = "daily_you_${timestamp}_$index$extenstion";
      index += 1;
    }

    if (usingExternalLocation()) {
      FileLayer.createFile(await getExternalFolder(), newImageName, bytes,
          useExternalPath: true); //Background
    }
    var imageFilePath = await FileLayer.createFile(
        await getInternalFolder(), newImageName, bytes,
        useExternalPath: false);
    if (imageFilePath == null) return null;
    if (Platform.isAndroid) {
      // Add image to media store
      MediaScanner.loadMedia(path: imageFilePath);
    }
    return newImageName;
  }

  Future<bool> delete(String imageName) async {
    // Delete remote
    if (usingExternalLocation()) {
      await FileLayer.deleteFile(await getExternalFolder(),
          name: imageName, useExternalPath: true);
    }
    // Delete local
    return await FileLayer.deleteFile(await getInternalFolder(),
        name: imageName, useExternalPath: false);
  }
}
