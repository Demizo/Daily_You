// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:async';
import 'dart:io';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/file_bytes_cache.dart';
import 'package:daily_you/storage/external_sync_health.dart';
import 'package:daily_you/storage/file_store.dart';
import 'package:daily_you/storage/local_file_store.dart';
import 'package:daily_you/storage/storage_picker.dart';
import 'package:daily_you/utils/operation_outcome.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
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

  // Bumped when new images are restored or synced. Forces UI to re-fetch images
  final ValueNotifier<int> cacheVersion = ValueNotifier(0);

  void invalidateCache() {
    imageCache.clear();
    cacheVersion.value++;
  }

  final ExternalSyncHealth externalSyncHealth =
      ExternalSyncHealth('ImageStorage');

  @visibleForTesting
  Duration externalTimeout = const Duration(seconds: 60);

  final Set<String> _uploadingNames = {};

  FileStore? _internalStore;
  FileStore? _externalStoreOverride;
  int _imageFolderRequests = 0;
  Future<void> _imageFolderWork = Future.value();

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

  @visibleForTesting
  void clearStoreOverrides() {
    _internalStore = null;
    _externalStoreOverride = null;
  }

  bool usingExternalLocation() {
    return ConfigProvider.instance.get(Settings.useExternalImg);
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
    return ConfigProvider.instance.get(Settings.externalImgUri);
  }

  /// Return whether the app has permission to access the external location
  Future<bool> hasExternalLocationPermission() async {
    return await externalStore?.isAvailable() ?? false;
  }

  Future<OperationOutcome> selectExternalLocation(
      Function(String) updateStatus) async {
    try {
      var selectedDirectory = await StoragePicker.pickDirectory();
      if (selectedDirectory == null) return const OperationOutcome.cancelled();

      // Save Old Settings
      var oldExternalImageUri =
          ConfigProvider.instance.get(Settings.externalImgUri);
      var oldUseExternalImage = usingExternalLocation();

      await ConfigProvider.instance
          .set(Settings.externalImgUri, selectedDirectory.uri);
      await ConfigProvider.instance.set(Settings.useExternalImg, true);
      if (await syncImageFolder(true, updateStatus: updateStatus)) {
        return const OperationOutcome.succeeded();
      }

      // Restore Settings
      await ConfigProvider.instance
          .set(Settings.externalImgUri, oldExternalImageUri);
      await ConfigProvider.instance
          .set(Settings.useExternalImg, oldUseExternalImage);
      return const OperationOutcome.failed();
    } catch (error, stackTrace) {
      _logger.severe(
          'Selecting an external image location failed', error, stackTrace);
      return OperationOutcome.failed(error);
    }
  }

  Future<void> resetImageFolderLocation() async {
    await ConfigProvider.instance.set(Settings.useExternalImg, false);
  }

  Future<Uint8List?> getBytes(String imageName) async {
    // Fetch cache copy if present
    var bytes = imageCache.get(imageName);
    if (bytes != null) {
      return bytes;
    }
    // Fetch local copy if present
    final internal = await internalStore();
    bytes = _nonEmpty(
        await imgFetchPool.withResource(() => internal.read(imageName)));

    final external = externalStore;
    if (bytes == null && external != null) {
      bytes = _nonEmpty(await external.read(imageName));
    }
    if (bytes != null) {
      imageCache.put(imageName, bytes);
    }
    return bytes;
  }

  Uint8List? _nonEmpty(Uint8List? bytes) =>
      bytes == null || bytes.isEmpty ? null : bytes;

  Future<String?> create(String? imageName, Uint8List bytes,
      {DateTime? currTime, bool skipExternalUpload = false}) async {
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

    if (!await internal.write(newImageName, bytes)) return null;

    final external = externalStore;
    if (external != null && !skipExternalUpload) {
      unawaited(_createExternal(external, newImageName, bytes));
    }
    return newImageName;
  }

  Future<CreateResult> _createExternal(
      FileStore external, String name, Uint8List bytes) async {
    _uploadingNames.add(name);
    final create = external.createNew(name, bytes);
    // Even after timeout, create could keep writing. To be safe, consider it to be uploading unless it completes gracefully
    unawaited(create
        .then((_) {}, onError: (Object _) {})
        .whenComplete(() => _uploadingNames.remove(name)));

    var result = CreateResult.failed;
    await externalSyncHealth.record("external image create of $name", () async {
      result = await create.timeout(externalTimeout);
      return result != CreateResult.failed;
    });
    if (result == CreateResult.alreadyExists) {
      _logger.warning(
          'external image create of $name collided with an existing file');
    }
    return result;
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
    final summary = await reconcileImageFolder(updateStatus: updateStatus);
    if (summary == null) return false;

    if (garbageCollect) return await garbageCollectImages();
    return true;
  }

  /// Stops any sync pass, then runs [action] before any later request.
  Future<T> whileNotSyncing<T>(Future<T> Function() action) =>
      _queueImageFolderWork((_) => action());

  /// A pass covers every image, so a newer request stops a running or queued
  /// one. Throws when a listing fails.
  @visibleForTesting
  Future<ImageSyncSummary?> reconcileImageFolder(
          {Function(String)? updateStatus}) =>
      _queueImageFolderWork((superseded) async {
        final internal = await internalStore();
        final external = externalStore;
        if (external == null) return null;

        final summary = await _ImageFolderReconcile(
                this,
                internal,
                external,
                _referencedImageNames('reconcile').toList(),
                superseded,
                updateStatus ?? (_) {})
            .run();
        if (summary.downloaded > 0 || summary.repaired > 0) invalidateCache();
        return summary;
      });

  Future<T> _queueImageFolderWork<T>(
      Future<T> Function(bool Function() superseded) work) {
    final request = ++_imageFolderRequests;
    final result = _imageFolderWork
        .then((_) => work(() => request != _imageFolderRequests));
    _imageFolderWork = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<bool> garbageCollectImages() async =>
      _deleteUnreferencedImages(_referencedImageNames('garbage collect'));

  Set<String> _referencedImageNames(String action) {
    final imagesProvider = EntryImagesProvider.instance;
    if (!imagesProvider.isLoaded) {
      throw StateError(
          'Refused to $action images before the image list was loaded');
    }
    return {for (final entryImage in imagesProvider.images) entryImage.imgPath};
  }

  Future<bool> _deleteUnreferencedImages(Set<String> referencedNames) async {
    final internal = await internalStore();
    for (final name in await internal.list()) {
      if (!referencedNames.contains(name)) {
        await internal.delete(name);
      }
    }
    return true;
  }
}

class ImageSyncSummary {
  int uploaded = 0;
  int downloaded = 0;
  int repaired = 0;
  int conflicts = 0;
  int unavailable = 0;
  int skippedSizeUnknown = 0;
  int collisions = 0;
  int failures = 0;

  @override
  String toString() => [
        'uploaded $uploaded',
        'downloaded $downloaded',
        'repaired $repaired',
        'conflicts $conflicts',
        'unavailable $unavailable',
        'skipped as size unknown $skippedSizeUnknown',
        'collisions $collisions',
        'failures $failures',
      ].join(', ');
}

class _ImageFolderReconcile {
  _ImageFolderReconcile(this._storage, this._internal, this._external,
      this._referencedNames, this._superseded, this._updateStatus);

  static const _stopAfterConsecutive = 3;

  final ImageStorage _storage;
  final FileStore _internal;
  final FileStore _external;
  final List<String> _referencedNames;
  final bool Function() _superseded;
  final Function(String) _updateStatus;

  final ImageSyncSummary _summary = ImageSyncSummary();
  Map<String, int> _internalSizes = {};
  Map<String, int> _externalSizes = {};
  Set<String> _internalLowerCaseNames = {};
  Set<String> _externalLowerCaseNames = {};
  bool _sizesReported = true;

  int _consecutiveFailedWrites = 0;
  String? _stopReason;

  Logger get _logger => _storage._logger;

  bool _shouldStop() {
    if (_superseded()) _stopReason ??= 'a newer request';
    return _stopReason != null;
  }

  /// Later image folder work waits for the pass. Time out SAF providers in case they don't respond
  Future<T> _timed<T>(Future<T> operation) =>
      operation.timeout(_storage.externalTimeout);

  Future<ImageSyncSummary> run() async {
    if (_shouldStop()) return _finished();

    try {
      _internalSizes = _sizesByName(await _internal.listFiles());
      _externalSizes = _sizesByName(await _timed(_external.listFiles()));
    } catch (error) {
      _logger.severe('reconcile: aborted, could not list images', error);
      rethrow;
    }

    _internalLowerCaseNames = _lowerCased(_internalSizes.keys);
    _externalLowerCaseNames = _lowerCased(_externalSizes.keys);
    _sizesReported =
        _externalSizes.isEmpty || _externalSizes.values.any((size) => size > 0);

    final total = _referencedNames.length;
    _updateStatus("0/$total");
    for (final (index, name) in _referencedNames.indexed) {
      if (_shouldStop()) break;
      try {
        await _reconcileImage(name);
      } catch (error) {
        _logger.severe('reconcile: $name failed', error);
        _failed();
      }
      _updateStatus("${index + 1}/$total");

      if (_consecutiveFailedWrites >= _stopAfterConsecutive) {
        _stopReason = 'the circuit breaker after $_stopAfterConsecutive '
            'consecutive failed or colliding writes';
      }
    }

    return _finished();
  }

  ImageSyncSummary _finished() {
    final outcome =
        _stopReason == null ? 'finished' : 'stopped by $_stopReason';
    final sizes = _sizesReported ? '' : ', Image Folder does not report sizes';
    _logger.info('reconcile: $outcome: $_summary$sizes');
    return _summary;
  }

  Map<String, int> _sizesByName(Iterable<StoredFile> files) =>
      {for (final file in files) file.name: file.size};

  Set<String> _lowerCased(Iterable<String> names) =>
      {for (final name in names) name.toLowerCase()};

  Future<void> _reconcileImage(String name) async {
    if (_storage._uploadingNames.contains(name)) return;

    final internalSize = _internalSizes[name];
    final externalSize = _externalSizes[name];
    if (_matchesOnlyByCase(name, internalSize, externalSize)) return;

    if (internalSize != null && externalSize != null) {
      if (internalSize == 0 ||
          (_sizesReported && internalSize != externalSize)) {
        await _compareCopies(name, externalSize);
      } else if (!_sizesReported) {
        _summary.skippedSizeUnknown++;
      }
    } else if (internalSize != null && internalSize > 0) {
      if (await _upload(name)) _summary.uploaded++;
    } else if (internalSize == null && externalSize != null) {
      await _downloadMissing(name, externalSize);
    } else {
      _unavailable(
          name, 'no usable copy on this device or in the Image Folder');
    }
  }

  bool _matchesOnlyByCase(String name, int? internalSize, int? externalSize) {
    final lowerCaseName = name.toLowerCase();
    final internalByCase =
        internalSize == null && _internalLowerCaseNames.contains(lowerCaseName);
    final externalByCase =
        externalSize == null && _externalLowerCaseNames.contains(lowerCaseName);
    if (!internalByCase && !externalByCase) return false;

    _logger.info(
        'reconcile: $name matches a file only by case, counting it as present');
    return true;
  }

  /// A listed 0 may mean unknown, so only a positive size is checked.
  int? _listedSize(int externalSize) =>
      _sizesReported && externalSize > 0 ? externalSize : null;

  Future<void> _downloadMissing(String name, int externalSize) async {
    final bytes = await _readExternal(name);
    final listedSize = _listedSize(externalSize);
    if (bytes == null) {
      _failed();
    } else if (bytes.isEmpty) {
      _unavailable(name, 'the Image Folder copy is empty');
    } else if (listedSize != null && bytes.length != listedSize) {
      _logger.severe('reconcile: download of $name refused, '
          'read ${bytes.length} of $listedSize bytes');
      _failed();
    } else if (await _download(name, bytes)) {
      _summary.downloaded++;
    }
  }

  /// A shorter copy whose bytes start the longer one is a cut-off write of
  /// the same image, repair it
  Future<void> _compareCopies(String name, int externalSize) async {
    final internalBytes = await _internal.read(name);
    final externalBytes = await _readExternal(name);
    final listedSize = _listedSize(externalSize);
    if (internalBytes != null &&
        externalBytes != null &&
        (listedSize == null || externalBytes.length == listedSize)) {
      if (_isPrefix(internalBytes, externalBytes) &&
          internalBytes.length == externalBytes.length) {
        if (internalBytes.isEmpty) {
          _unavailable(name, 'both copies are empty');
        }
        return;
      }
      if (_isPrefix(externalBytes, internalBytes)) {
        if (await _replaceExternal(name, internalBytes)) {
          _summary.repaired++;
          _logger
              .info('reconcile: replaced shorter Image Folder copy of $name');
        }
        return;
      }
      if (_isPrefix(internalBytes, externalBytes)) {
        if (await _replaceInternal(name, externalBytes)) {
          _summary.repaired++;
          _logger.info('reconcile: replaced shorter internal copy of $name');
        }
        return;
      }
    }
    _summary.conflicts++;
    _logger.warning('reconcile: conflict on $name, internal copy is '
        '${_internalSizes[name]} bytes and Image Folder copy is listed as '
        '$externalSize bytes; leaving both');
  }

  bool _isPrefix(Uint8List shorter, Uint8List longer) {
    if (shorter.length > longer.length) return false;
    for (var i = 0; i < shorter.length; i++) {
      if (shorter[i] != longer[i]) return false;
    }
    return true;
  }

  Future<bool> _upload(String name, [Uint8List? bytes]) async {
    bytes ??= await _internal.read(name);
    if (bytes == null || bytes.isEmpty) {
      _logger.severe('reconcile: upload of $name failed, could not read it');
      _failed();
      return false;
    }
    return _tally(await _storage._createExternal(_external, name, bytes));
  }

  Future<bool> _replaceExternal(String name, Uint8List bytes) async {
    final deleted = await _storage.externalSyncHealth.record(
        "reconcile: delete of shorter $name",
        () => _timed(_external.delete(name)));
    if (!deleted) {
      _failedWrite();
      return false;
    }
    return _upload(name, bytes);
  }

  Future<bool> _replaceInternal(String name, Uint8List bytes) async {
    if (!await _internal.delete(name)) {
      _logger.severe('reconcile: delete of internal $name failed');
      _failedWrite();
      return false;
    }
    return _download(name, bytes);
  }

  Future<bool> _download(String name, Uint8List bytes) async {
    final CreateResult result;
    try {
      result = await _internal.createNew(name, bytes);
    } catch (error) {
      _logger.severe('reconcile: download of $name failed', error);
      _failedWrite();
      return false;
    }
    switch (result) {
      case CreateResult.created:
        break;
      case CreateResult.alreadyExists:
        _logger.warning(
            'reconcile: download of $name collided with an existing file');
      case CreateResult.failed:
        _logger.severe('reconcile: download of $name failed');
    }
    return _tally(result);
  }

  Future<Uint8List?> _readExternal(String name) async {
    try {
      final bytes = await _timed(_external.read(name));
      if (bytes == null) {
        _logger
            .warning('reconcile: could not read $name from the Image Folder');
      }
      return bytes;
    } catch (error) {
      _logger.warning(
          'reconcile: read of $name from the Image Folder failed', error);
      return null;
    }
  }

  void _unavailable(String name, String reason) {
    _summary.unavailable++;
    _logger.info('reconcile: $name is unavailable on this device, $reason');
  }

  /// Only writes count towards the circuit breaker. A file that can't be read
  /// fails every launch
  bool _tally(CreateResult result) {
    switch (result) {
      case CreateResult.created:
        _consecutiveFailedWrites = 0;
        return true;
      case CreateResult.alreadyExists:
        _summary.collisions++;
        _consecutiveFailedWrites++;
      case CreateResult.failed:
        _failedWrite();
    }
    return false;
  }

  void _failed() => _summary.failures++;

  void _failedWrite() {
    _failed();
    _consecutiveFailedWrites++;
  }
}
