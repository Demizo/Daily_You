import 'dart:async';
import 'dart:io';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/file_bytes_cache.dart';
import 'package:daily_you/storage/external_sync_health.dart';
import 'package:daily_you/storage/file_store.dart';
import 'package:daily_you/storage/local_file_store.dart';
import 'package:daily_you/storage/storage_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
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

  final ExternalSyncHealth externalSyncHealth =
      ExternalSyncHealth('ImageStorage');

  FileStore? _internalStore;
  FileStore? _externalStoreOverride;

  Future<FileStore> internalStore() async =>
      _internalStore ??= LocalFileStore(await getInternalFolder());

  FileStore? get externalStore =>
      _externalStoreOverride ??
      (usingExternalLocation()
          ? FileStore.external(_getExternalFolder())
          : null);

  @visibleForTesting
  void overrideStores(FileStore internal, FileStore external) {
    _internalStore = internal;
    _externalStoreOverride = external;
  }

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
    return await externalStore?.isAvailable() ?? false;
  }

  Future<bool> selectExternalLocation(Function(String) updateStatus) async {
    try {
      var selectedDirectory = await StoragePicker.pickDirectory();
      if (selectedDirectory == null) return false;

      // Save Old Settings
      var oldExternalImgUri =
          ConfigProvider.instance.get(ConfigKey.externalImgUri);
      var oldUseExternalImg = usingExternalLocation();

      await ConfigProvider.instance
          .set(ConfigKey.externalImgUri, selectedDirectory.uri);
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
    final internal = await internalStore();
    bytes = await imgFetchPool.withResource(() => internal.read(imageName));

    // Attempt to fetch file externally
    final external = externalStore;
    if (bytes == null && external != null) {
      // Get and cache external image
      bytes = await external.read(imageName);
      if (bytes != null) {
        await internal.write(imageName, bytes);
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

    final internal = await internalStore();

    // Don't make a copy of files already in the folder
    if (imageName != null && await internal.exists(imageName)) {
      return imageName;
    }

    var fileExtension = imageName != null ? extension(imageName) : ".jpg";

    final timestamp =
        currTime.toIso8601String().split('.').first.replaceAll(':', '-');

    var newImageName = "daily_you_$timestamp$fileExtension";

    // Ensure unique name
    int index = 1;
    while (await internal.exists(newImageName)) {
      newImageName = "daily_you_${timestamp}_$index$fileExtension";
      index += 1;
    }

    // Do not await operation
    unawaited(_createExternal(newImageName, bytes));

    if (!await internal.write(newImageName, bytes)) return null;
    return newImageName;
  }

  Future<void> _createExternal(String name, Uint8List bytes) async {
    final external = externalStore;
    if (external == null || await external.exists(name)) return;

    await externalSyncHealth.record(
        "external image write", () => external.write(name, bytes));
  }

  Future<bool> delete(String imageName) async {
    final internal = await internalStore();
    await internal.delete(imageName);

    final external = externalStore;
    if (external != null) {
      // Do not await operation
      unawaited(externalSyncHealth.record(
          "external image delete", () => external.delete(imageName)));
    }

    return true;
  }

  Future<bool> syncImageFolder(bool garbageCollect,
      {Function(String)? updateStatus}) async {
    final external = externalStore;
    if (external == null) return false;
    final internal = await internalStore();

    List<Entry> entries = EntriesProvider.instance.entries;
    updateStatus?.call("0/${entries.length}");

    List<String> externalImages = await external.list();
    List<String> internalImages = await internal.list();

    int syncedEntries = 0;
    for (Entry entry in entries) {
      var images = EntryImagesProvider.instance.getForEntry(entry);
      for (final image in images) {
        var entryImage = image.imgPath;

        // Export
        if (internalImages.contains(entryImage) &&
            !externalImages.contains(entryImage)) {
          var bytes = await internal.read(entryImage);
          if (bytes != null) {
            await externalSyncHealth.record("external image write",
                () => external.write(entryImage, bytes));
          }
        }

        // Import
        if (externalImages.contains(entryImage) &&
            !internalImages.contains(entryImage)) {
          var bytes = await external.read(entryImage);
          if (bytes != null) {
            await internal.write(entryImage, bytes);
          }
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
    return deleteUnreferencedImages(EntryImagesProvider.instance.images
        .map((entryImage) => entryImage.imgPath)
        .toSet());
  }

  Future<bool> deleteUnreferencedImages(Set<String> referencedNames) async {
    final internal = await internalStore();
    for (final name in await internal.list()) {
      if (!referencedNames.contains(name)) {
        await internal.delete(name);
      }
    }
    return true;
  }
}
