import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/file_bytes_cache.dart';
import 'package:daily_you/utils/file_layer.dart';
import 'package:logging/logging.dart';
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

  final Logger _logger = Logger('ImageStorage');

  final FileBytesCache imageCache =
      FileBytesCache(maxCacheSize: 10 * 1024 * 1024);
  final Pool imgFetchPool = Pool(3);

  bool usingExternalLocation() {
    return ConfigProvider.instance.get(ConfigKey.useExternalImg) ?? false;
  }

  Future<String> getInternalFolder() async {
    final basePath = await getApplicationSupportDirectory();
    final imagesDir = Directory('${basePath.path}/Images');
    if (!imagesDir.existsSync()) imagesDir.createSync(recursive: true);
    return imagesDir.path;
  }

  Future<Directory?> _oldExternalImagesDirectory() async {
    if (!Platform.isAndroid) return null;
    final oldBaseDir = await getExternalStorageDirectory();
    if (oldBaseDir == null) return null;
    final oldImagesDir = Directory('${oldBaseDir.path}/Images');
    if (!oldImagesDir.existsSync()) return null;
    return oldImagesDir;
  }

  Future<bool> needsImageMigration() async {
    final oldImagesDir = await _oldExternalImagesDirectory();
    if (oldImagesDir == null) return false;
    return oldImagesDir.list().any((entity) => entity is File);
  }

  Future<void> migrateImagesFromExternalStorage(
      {Function(int migrated, int total)? updateStatus}) async {
    final oldImagesDir = await _oldExternalImagesDirectory();
    if (oldImagesDir == null) return;

    final newImagesDir = Directory(await getInternalFolder());

    final imageFiles =
        await oldImagesDir.list().where((entity) => entity is File).toList();

    final totalImages = imageFiles.length;
    var migratedImages = 0;
    var failedImages = 0;
    updateStatus?.call(migratedImages, totalImages);

    _logger.info(
        'Image migration started: $totalImages file(s) in ${oldImagesDir.path} -> ${newImagesDir.path}');

    for (final entity in imageFiles) {
      final imageFile = entity as File;
      try {
        final dest = File('${newImagesDir.path}/${basename(imageFile.path)}');
        final sourceLength = await imageFile.length();

        // Image names are immutable, so a same-name file that differs in size
        // is a corrupt copy from an interrupted run. Trust the external
        // original in that case and repair the internal copy.
        if (!dest.existsSync() || await dest.length() != sourceLength) {
          // Copy to a temp file first, then rename so a partial copy is never
          // mistaken for a finished one.
          final temp = File('${dest.path}.migrating');
          if (temp.existsSync()) await temp.delete();
          await imageFile.copy(temp.path);
          if (await temp.length() != sourceLength) {
            if (temp.existsSync()) await temp.delete();
            failedImages += 1;
            _logger.warning(
                'Image migration: size mismatch after copy, will retry ${basename(imageFile.path)}');
            continue;
          }
          await temp.rename(dest.path);
        }

        // A confirmed, size-matching copy now exists internally; the external
        // original is a duplicate and can be removed so migration terminates.
        if (dest.existsSync() && await dest.length() == sourceLength) {
          await imageFile.delete();
        }
      } catch (error, stackTrace) {
        // Skip this file; a later launch will retry it.
        failedImages += 1;
        _logger.severe('Image migration failed for ${basename(imageFile.path)}',
            error, stackTrace);
      } finally {
        migratedImages += 1;
        updateStatus?.call(migratedImages, totalImages);
      }
    }

    // Remove the old folder after a complete migration
    try {
      if (await oldImagesDir.list().isEmpty) {
        await oldImagesDir.delete();
      }
    } catch (error) {
      // Directory not empty or inaccessible; leave it in place.
      _logger.warning('Image migration: could not remove old directory', error);
    }

    _logger.info(
        'Image migration finished: ${totalImages - failedImages}/$totalImages migrated, $failedImages failed');
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
      return await garbageCollectImages();
    }
    return true;
  }

  Future<bool> garbageCollectImages() async {
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
