import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/file_bytes_cache.dart';
import 'package:daily_you/file_layer.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
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

  String _getExternalFolder() {
    return ConfigProvider.instance.get(ConfigKey.externalImgUri);
  }

  /// Return whether the app has permission to access the external location
  Future<bool> hasExternalLocationPermission() async {
    return FileLayer.hasPermission(_getExternalFolder());
  }

  Future<bool> selectExternalLocation(Function(String) updateStatus) async {
    try {
      var selectedDirectory = await FileLayer.pickDirectory();
      if (selectedDirectory == null) return false;

      // Save Old Settings
      var oldExternalImgUri =
          ConfigProvider.instance.get(ConfigKey.externalImgUri);
      var oldUseExternalImg = usingExternalLocation();

      await ConfigProvider.instance
          .set(ConfigKey.externalImgUri, selectedDirectory);
      await ConfigProvider.instance.set(ConfigKey.useExternalImg, true);
      var synced = await syncImageFolder(true, updateStatus: updateStatus);
      if (synced) {
        return true;
      } else {
        // Restore Settings
        await ConfigProvider.instance
            .set(ConfigKey.externalImgUri, oldExternalImgUri);
        await ConfigProvider.instance
            .set(ConfigKey.useExternalImg, oldUseExternalImg);
        return false;
      }
    } catch (_) {
      return false;
    }
  }

  void resetImageFolderLocation() async {
    await ConfigProvider.instance.set(ConfigKey.useExternalImg, false);
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
      bytes = await FileLayer.getFileBytes(_getExternalFolder(),
          name: imageName, useExternalPath: true);
      if (bytes != null) {
        await FileLayer.createFile(internalDir, imageName, bytes,
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

    final internalFolder = await getInternalFolder();

    // Don't make a copy of files already in the folder
    if (imageName != null &&
        await FileLayer.exists(internalFolder,
            name: imageName, useExternalPath: false)) {
      return imageName;
    }

    var extenstion = imageName != null ? extension(imageName) : ".jpg";

    final timestamp =
        currTime.toIso8601String().split('.').first.replaceAll(':', '-');

    var newImageName = "daily_you_$timestamp$extenstion";

    // Ensure unique name
    int index = 1;
    while (await FileLayer.exists(internalFolder,
        name: newImageName, useExternalPath: false)) {
      newImageName = "daily_you_${timestamp}_$index$extenstion";
      index += 1;
    }

    // Do not await operation
    unawaited(_createRemote(newImageName, bytes));

    var imageFilePath = await FileLayer.createFile(
        internalFolder, newImageName, bytes,
        useExternalPath: false);
    if (imageFilePath == null) return null;
    if (Platform.isAndroid) {
      // Add image to media store
      MediaScanner.loadMedia(path: imageFilePath);
    }
    return newImageName;
  }

  Future<void> _createRemote(String name, Uint8List bytes) async {
    final externalFolder = _getExternalFolder();
    if (usingExternalLocation() &&
        !(await FileLayer.exists(externalFolder,
            name: name, useExternalPath: true))) {
      await FileLayer.createFile(externalFolder, name, bytes,
          useExternalPath: true);
    }
  }

  Future<bool> delete(String imageName) async {
    final internalFolder = await getInternalFolder();
    final externalFolder = _getExternalFolder();
    // Delete local
    await FileLayer.deleteFile(internalFolder,
        name: imageName, useExternalPath: false);

    // Delete remote
    if (usingExternalLocation()) {
      // Do not await operation
      unawaited(FileLayer.deleteFile(externalFolder,
          name: imageName, useExternalPath: true));
    }

    return true;
  }

  Future<bool> syncImageFolder(bool garbageCollect,
      {Function(String)? updateStatus}) async {
    List<Entry> entries = EntriesProvider.instance.entries;
    updateStatus?.call("0/${entries.length}");

    final internalFolder = await getInternalFolder();
    final externalFolder = _getExternalFolder();

    List<String> entryImages = List.empty(growable: true);

    List<String> externalImages =
        await FileLayer.listFiles(externalFolder, useExternalPath: true);
    List<String> internalImages =
        await FileLayer.listFiles(internalFolder, useExternalPath: false);

    int syncedEntries = 0;
    for (Entry entry in entries) {
      var images = EntryImagesProvider.instance.getForEntry(entry);
      for (final image in images) {
        var entryImg = image.imgPath;

        entryImages.add(entryImg);

        // Export
        if (internalImages.contains(entryImg) &&
            !externalImages.contains(entryImg)) {
          var bytes = await FileLayer.getFileBytes(internalFolder,
              name: entryImg, useExternalPath: false);
          await FileLayer.createFile(externalFolder, entryImg, bytes!,
              useExternalPath: true);
        }

        // Import
        if (externalImages.contains(entryImg) &&
            !internalImages.contains(entryImg)) {
          var bytes = await FileLayer.getFileBytes(externalFolder,
              name: entryImg, useExternalPath: true);
          await FileLayer.createFile(internalFolder, entryImg, bytes!,
              useExternalPath: false);
        }
        syncedEntries += 1;
        updateStatus?.call("$syncedEntries/${entries.length}");
      }
    }

    if (garbageCollect) {
      return await _garbageCollectImages();
    }
    return true;
  }

  Future<bool> _garbageCollectImages() async {
    var entryImages = EntryImagesProvider.instance.images;
    var entryImageNames =
        entryImages.map((entryImage) => entryImage.imgPath).toList();
    // Get all internal photos
    var internalImages = Directory(await getInternalFolder()).list();
    await for (FileSystemEntity fileEntity in internalImages) {
      if (fileEntity is File) {
        // Delete any that aren't used
        if (!entryImageNames.contains(basename(fileEntity.path))) {
          await File(fileEntity.path).delete();
        }
      }
    }
    return true;
  }
}
