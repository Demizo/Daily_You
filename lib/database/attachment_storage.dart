// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/file_bytes_cache.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/storage/external_sync_health.dart';
import 'package:daily_you/storage/external_sync_settings.dart';
import 'package:daily_you/storage/file_store.dart';
import 'package:daily_you/storage/in_memory_file_store.dart';
import 'package:daily_you/storage/local_file_store.dart';
import 'package:daily_you/storage/sync_item.dart';
import 'package:daily_you/storage/sync_progress.dart';
import 'package:daily_you/utils/attachment_file_name.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pool/pool.dart';

class AttachmentStorage {
  static final AttachmentStorage instance = AttachmentStorage._init();

  AttachmentStorage._init();

  final Logger _logger = Logger('AttachmentStorage');

  final FileBytesCache bytesCache =
      FileBytesCache(maxCacheSize: 10 * 1024 * 1024);
  final Pool fetchPool = Pool(3);

  final ValueNotifier<int> cacheVersion = ValueNotifier(0);

  void invalidateCache() {
    bytesCache.clear();
    cacheVersion.value++;
  }

  final StreamController<({AttachmentType type, String fileName})>
      _deletedController = StreamController.broadcast();

  Stream<({AttachmentType type, String fileName})> get deletions =>
      _deletedController.stream;

  final ExternalSyncHealth externalSyncHealth =
      ExternalSyncHealth('AttachmentStorage');

  @visibleForTesting
  Duration externalTimeout = const Duration(seconds: 60);

  static const _slowestBytesPerSecond = 512 * 1024;

  Duration _timeoutFor(int bytes) =>
      externalTimeout + Duration(seconds: bytes ~/ _slowestBytesPerSecond);

  final Set<String> _uploadingNames = {};

  final Map<AttachmentType, FileStore> _internalStores = {};
  final Map<AttachmentType, FileStore> _externalStoreOverrides = {};
  final Map<SyncLocation, Future<FileStore>> _externalSubfolders = {};
  int _folderRequests = 0;
  Future<void> _folderWork = Future.value();

  Future<FileStore> internalStore(AttachmentType type) async =>
      _internalStores[type] ??= LocalFileStore(await getInternalFolder(type));

  Future<FileStore?> externalStore(AttachmentType type) async {
    final override = _externalStoreOverrides[type];
    if (override != null) return override;

    final location =
        ExternalSyncSettings.load().location(SyncItem.forAttachments(type));
    if (location == null) return null;

    final base = FileStore.external(location.uri);
    final subfolder = location.subfolder;
    if (subfolder == null) return base;
    final pending = _externalSubfolders[location] ??= base.subfolder(subfolder);
    try {
      return await pending;
    } catch (error, stackTrace) {
      if (identical(_externalSubfolders[location], pending)) {
        _externalSubfolders.remove(location);
      }
      _logger.warning(
          'External $subfolder folder is unavailable', error, stackTrace);
      return null;
    }
  }

  @visibleForTesting
  void overrideStores(FileStore internal, FileStore external) {
    for (final type in AttachmentType.values) {
      final isImage = type == AttachmentType.image;
      _internalStores[type] = isImage ? internal : InMemoryFileStore();
      _externalStoreOverrides[type] = isImage ? external : InMemoryFileStore();
    }
  }

  @visibleForTesting
  void clearStoreOverrides() {
    _internalStores.clear();
    _externalStoreOverrides.clear();
    _externalSubfolders.clear();
  }

  bool usingExternalLocation() => AttachmentType.values.any((type) =>
      ExternalSyncSettings.load().location(SyncItem.forAttachments(type)) !=
      null);

  Future<bool> hasExternalLocationPermission() async {
    final settings = ExternalSyncSettings.load();
    final uris = {
      for (final type in AttachmentType.values)
        if (settings.location(SyncItem.forAttachments(type))
            case final location?)
          location.uri,
    };
    for (final uri in uris) {
      if (!await FileStore.external(uri).isAvailable()) return false;
    }
    return true;
  }

  Future<int> internalSizeBytes(AttachmentType type) async {
    final folder = Directory(await getInternalFolder(type));
    var total = 0;
    await for (final entity in folder.list()) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  Future<String> getInternalFolder(AttachmentType type) async {
    final basePath = await getApplicationSupportDirectory();
    final directory = Directory('${basePath.path}/${type.folderName}');
    if (!directory.existsSync()) directory.createSync(recursive: true);
    return directory.path;
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

    final newImagesDir =
        Directory(await getInternalFolder(AttachmentType.image));

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

  Future<Uint8List?> getBytes(String fileName, AttachmentType type) async {
    var bytes = bytesCache.get(fileName);
    if (bytes != null) {
      return bytes;
    }
    final internal = await internalStore(type);
    bytes =
        _nonEmpty(await fetchPool.withResource(() => internal.read(fileName)));

    if (bytes == null) {
      final external = await externalStore(type);
      if (external != null) bytes = _nonEmpty(await external.read(fileName));
    }
    if (bytes != null) {
      bytesCache.put(fileName, bytes);
    }
    return bytes;
  }

  Uint8List? _nonEmpty(Uint8List? bytes) =>
      bytes == null || bytes.isEmpty ? null : bytes;

  Future<String?> getLocalPath(String fileName, AttachmentType type) async {
    final folder = await getInternalFolder(type);
    if (await (await internalStore(type)).exists(fileName)) {
      return join(folder, fileName);
    }

    final external = await externalStore(type);
    if (external == null) return null;

    try {
      final fetched = await LocalFileStore(folder).writeAtomically(
          fileName,
          (temporary) async =>
              await external.copyToFile(fileName, temporary) &&
              await temporary.length() > 0);
      return fetched ? join(folder, fileName) : null;
    } catch (error, stackTrace) {
      _logger.warning('Fetching $fileName from the external location failed',
          error, stackTrace);
      return null;
    }
  }

  Future<String?> create(String? fileName, Uint8List bytes, AttachmentType type,
          {DateTime? currTime,
          bool skipExternalUpload = false,
          bool keepFileName = false,
          Set<String>? takenNames}) =>
      _createNew(
          fileName,
          type,
          currTime,
          skipExternalUpload,
          keepFileName,
          takenNames,
          (store, name) => store.createNew(name, bytes),
          (external, _, name) => external.createNew(name, bytes));

  Future<String?> createFromFile(
          String? fileName, File source, AttachmentType type,
          {DateTime? currTime,
          bool skipExternalUpload = false,
          bool keepFileName = false,
          Set<String>? takenNames}) =>
      _createNew(
          fileName,
          type,
          currTime,
          skipExternalUpload,
          keepFileName,
          takenNames,
          (store, name) => store.createNewFromFile(name, source),
          _uploadFromInternal);

  Future<String?> _createNew(
    String? fileName,
    AttachmentType type,
    DateTime? currTime,
    bool skipExternalUpload,
    bool keepFileName,
    Set<String>? takenNames,
    Future<CreateResult> Function(FileStore internal, String name)
        createInternal,
    Future<CreateResult> Function(
            FileStore external, FileStore internal, String name)
        upload,
  ) async {
    currTime ??= DateTime.now();

    final internal = await internalStore(type);

    final fileExtension = sanitizedExtension(fileName, type.defaultExtension);

    final timestamp =
        currTime.toIso8601String().split('.').first.replaceAll(':', '-');

    final stem = (keepFileName ? sanitizedStem(fileName) : null) ??
        "daily_you_$timestamp";
    final taken = takenNames ?? await takenLowerCaseNames(type);
    var newFileName = "$stem$fileExtension";
    var index = 0;
    while (true) {
      if (!taken.contains(newFileName.toLowerCase())) {
        final result = await createInternal(internal, newFileName);
        if (result == CreateResult.created) break;
        if (result == CreateResult.failed) return null;
      }
      index += 1;
      newFileName = "${stem}_$index$fileExtension";
    }

    taken.add(newFileName.toLowerCase());

    final external = skipExternalUpload ? null : await externalStore(type);
    if (external != null) {
      final name = newFileName;
      final bytes = await internal.size(name) ?? 0;
      unawaited(
          _createExternal(name, bytes, () => upload(external, internal, name)));
    }
    return newFileName;
  }

  Future<Set<String>> takenLowerCaseNames(AttachmentType type) async => {
        for (final name in await (await internalStore(type)).list())
          name.toLowerCase(),
        for (final attachment in EntryAttachmentsProvider.instance.attachments)
          if (attachment.type == type) attachment.filePath.toLowerCase(),
      };

  Future<CreateResult> _uploadFromInternal(
      FileStore external, FileStore internal, String name) async {
    if (internal is LocalFileStore) {
      return external.createNewFromFile(
          name, File(join(internal.directoryPath, name)));
    }
    final bytes = await internal.read(name);
    if (bytes == null || bytes.isEmpty) return CreateResult.failed;
    return external.createNew(name, bytes);
  }

  Future<int?> sizeBytes(String fileName, AttachmentType type) async {
    final internal = await internalStore(type);
    final size = await internal.size(fileName);
    if (size != null) return size;
    return (await externalStore(type))?.size(fileName);
  }

  Future<CreateResult> _createExternal(
      String name, int bytes, Future<CreateResult> Function() start) async {
    _uploadingNames.add(name);
    final create = start();
    // Even after timeout, create could keep writing. To be safe, consider it to be uploading unless it completes gracefully
    unawaited(create
        .then((_) {}, onError: (Object _) {})
        .whenComplete(() => _uploadingNames.remove(name)));

    var result = CreateResult.failed;
    await externalSyncHealth.record("external attachment create of $name",
        () async {
      result = await create.timeout(_timeoutFor(bytes));
      return result != CreateResult.failed;
    });
    if (result == CreateResult.alreadyExists) {
      _logger.warning(
          'external attachment create of $name collided with an existing file');
    }
    return result;
  }

  Future<bool> delete(String fileName, AttachmentType type) async {
    var deleted = true;
    try {
      await (await internalStore(type)).delete(fileName);
      bytesCache.remove(fileName);
      _deletedController.add((type: type, fileName: fileName));
    } catch (error, stackTrace) {
      _logger.warning(
          'Deleting $fileName from internal storage failed', error, stackTrace);
      deleted = false;
    }

    final external = await externalStore(type);
    if (external != null) {
      // Do not await operation
      unawaited(externalSyncHealth.record(
          "external attachment delete", () => external.delete(fileName)));
    }

    return deleted;
  }

  Future<void> syncAttachmentFolders(bool garbageCollect,
      {Iterable<AttachmentType>? types,
      void Function(SyncProgress)? onProgress}) async {
    await reconcileAttachmentFolders(types: types, onProgress: onProgress);
    if (garbageCollect) await garbageCollectAttachments();
  }

  /// Stops any sync pass, then runs [action] before any later request.
  Future<T> whileNotSyncing<T>(Future<T> Function() action) =>
      _queueFolderWork((_) => action());

  @visibleForTesting
  Future<AttachmentSyncSummary> reconcileAttachmentFolders(
          {Iterable<AttachmentType>? types,
          void Function(SyncProgress)? onProgress}) =>
      _queueFolderWork((superseded) async {
        final referenced = _referencedFileNames('reconcile');
        final summary = AttachmentSyncSummary();
        for (final type in types ?? AttachmentType.values) {
          final external = await externalStore(type);
          if (external == null) continue;

          final item = SyncItem.forAttachments(type);
          onProgress?.call(SyncProgress(item));
          summary.add(await _AttachmentFolderReconcile(
                  this,
                  type,
                  await internalStore(type),
                  external,
                  referenced[type]!.toList(),
                  superseded,
                  (completed, total) =>
                      onProgress?.call(SyncProgress(item, completed, total)))
              .run());
        }
        if (summary.downloaded > 0 || summary.repaired > 0) invalidateCache();
        return summary;
      });

  Future<T> _queueFolderWork<T>(
      Future<T> Function(bool Function() superseded) work) {
    final request = ++_folderRequests;
    final result =
        _folderWork.then((_) => work(() => request != _folderRequests));
    _folderWork = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<bool> garbageCollectAttachments() async {
    final referenced = _referencedFileNames('garbage collect');
    for (final type in AttachmentType.values) {
      await _deleteUnreferenced(type, referenced[type]!);
    }
    return true;
  }

  Future<int> deleteOrphanedAttachments(
      {Duration minAge = const Duration(days: 1), DateTime? now}) async {
    final referenced = _referencedFileNames('delete orphaned');
    if (AppDatabase.instance.databaseReplacedThisSession ||
        referenced.values.every((names) => names.isEmpty)) {
      _logger.info(
          'Orphan sweep skipped: database replaced or nothing referenced');
      return 0;
    }
    final cutoff = (now ?? DateTime.now()).subtract(minAge);
    var deleted = 0;
    for (final type in AttachmentType.values) {
      final internal = await internalStore(type);
      for (final name in await internal.list()) {
        if (referenced[type]!.contains(name) ||
            _uploadingNames.contains(name)) {
          continue;
        }
        final modified = await internal.modifiedTime(name);
        if (modified == null || modified.isAfter(cutoff)) continue;
        try {
          await internal.delete(name);
          deleted++;
        } catch (error, stackTrace) {
          _logger.warning(
              'Deleting orphaned attachment $name failed', error, stackTrace);
        }
      }
    }
    if (deleted > 0) _logger.info('Deleted $deleted orphaned attachments');
    return deleted;
  }

  Map<AttachmentType, Set<String>> _referencedFileNames(String action) {
    final attachmentsProvider = EntryAttachmentsProvider.instance;
    if (!attachmentsProvider.isLoaded) {
      throw StateError(
          'Refused to $action attachments before the attachment list was loaded');
    }
    return {
      for (final type in AttachmentType.values)
        type: {
          for (final attachment in attachmentsProvider.attachments)
            if (attachment.type == type) attachment.filePath
        },
    };
  }

  Future<void> _deleteUnreferenced(
      AttachmentType type, Set<String> referencedNames) async {
    final internal = await internalStore(type);
    for (final name in await internal.list()) {
      if (!referencedNames.contains(name) &&
          !LocalFileStore.isTemporary(name)) {
        await internal.delete(name);
      }
    }
  }
}

class AttachmentSyncSummary {
  int uploaded = 0;
  int downloaded = 0;
  int repaired = 0;
  int conflicts = 0;
  int unavailable = 0;
  int skippedSizeUnknown = 0;
  int collisions = 0;
  int failures = 0;

  void add(AttachmentSyncSummary other) {
    uploaded += other.uploaded;
    downloaded += other.downloaded;
    repaired += other.repaired;
    conflicts += other.conflicts;
    unavailable += other.unavailable;
    skippedSizeUnknown += other.skippedSizeUnknown;
    collisions += other.collisions;
    failures += other.failures;
  }

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

class _AttachmentFolderReconcile {
  _AttachmentFolderReconcile(
      this._storage,
      this._type,
      this._internal,
      this._external,
      this._referencedNames,
      this._superseded,
      this._onProgress);

  static const _stopAfterConsecutive = 3;
  static const _compareChunkBytes = 1024 * 1024;

  final AttachmentStorage _storage;
  final AttachmentType _type;
  final FileStore _internal;
  final FileStore _external;
  final List<String> _referencedNames;
  final bool Function() _superseded;
  final void Function(int completed, int total) _onProgress;

  final AttachmentSyncSummary _summary = AttachmentSyncSummary();
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

  Future<T> _timed<T>(Future<T> operation, {int bytes = 0}) =>
      operation.timeout(_storage._timeoutFor(bytes));

  Future<AttachmentSyncSummary> run() async {
    if (_shouldStop()) return _finished();

    try {
      _internalSizes = _sizesByName(await _internal.listFiles());
      _externalSizes = _sizesByName(await _timed(_external.listFiles()));
    } catch (error) {
      _logger.severe('reconcile: aborted, could not list attachments', error);
      rethrow;
    }

    _internalLowerCaseNames = _lowerCased(_internalSizes.keys);
    _externalLowerCaseNames = _lowerCased(_externalSizes.keys);
    _sizesReported =
        _externalSizes.isEmpty || _externalSizes.values.any((size) => size > 0);

    final total = _referencedNames.length;
    _onProgress(0, total);
    for (final (index, name) in _referencedNames.indexed) {
      if (_shouldStop()) break;
      try {
        await _reconcileAttachment(name);
      } catch (error) {
        _logger.severe('reconcile: $name failed', error);
        _failed();
      }
      _onProgress(index + 1, total);

      if (_consecutiveFailedWrites >= _stopAfterConsecutive) {
        _stopReason = 'the circuit breaker after $_stopAfterConsecutive '
            'consecutive failed or colliding writes';
      }
    }

    return _finished();
  }

  AttachmentSyncSummary _finished() {
    final outcome =
        _stopReason == null ? 'finished' : 'stopped by $_stopReason';
    final sizes =
        _sizesReported ? '' : ', external folder does not report sizes';
    _logger.info('reconcile ${_type.name}: $outcome: $_summary$sizes');
    return _summary;
  }

  Map<String, int> _sizesByName(Iterable<StoredFile> files) =>
      {for (final file in files) file.name: file.size};

  Set<String> _lowerCased(Iterable<String> names) =>
      {for (final name in names) name.toLowerCase()};

  Future<void> _reconcileAttachment(String name) async {
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
      if (await _downloadMissing(name, externalSize)) _summary.downloaded++;
    } else {
      _unavailable(
          name, 'no usable copy on this device or in the external folder');
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

  Future<bool> _downloadMissing(String name, int externalSize) async {
    final internal = _internal;
    if (internal is LocalFileStore) {
      return _downloadMissingToDisk(internal, name, externalSize);
    }

    final bytes = await _readExternal(name);
    return _acceptDownload(name, bytes?.length, externalSize) &&
        await _download(name, () => internal.createNew(name, bytes!));
  }

  Future<bool> _downloadMissingToDisk(
          LocalFileStore internal, String name, int externalSize) =>
      _download(name, () async {
        final published =
            await internal.writeAtomically(name, (temporary) async {
          final copied = await _copyExternal(name, temporary);
          return _acceptDownload(
              name, copied ? await temporary.length() : null, externalSize);
        });
        return published ? CreateResult.created : null;
      });

  bool _acceptDownload(String name, int? size, int externalSize) {
    final listedSize = _listedSize(externalSize);
    if (size == null) {
      _failed();
    } else if (size == 0) {
      _unavailable(name, 'the external folder copy is empty');
    } else if (listedSize != null && size != listedSize) {
      _logger.severe('reconcile: download of $name refused, '
          'read $size of $listedSize bytes');
      _failed();
    } else {
      return true;
    }
    return false;
  }

  Future<void> _compareCopies(String name, int externalSize) async {
    final scratch =
        await Directory.systemTemp.createTemp('daily_you_reconcile');
    try {
      final internalFile = await _internalFile(name, scratch);
      final externalFile = await _externalFile(name, scratch);
      if (internalFile != null && externalFile != null) {
        final internalLength = await internalFile.length();
        final externalLength = await externalFile.length();
        final listedSize = _listedSize(externalSize);
        if ((listedSize == null || externalLength == listedSize) &&
            await _startWithSameBytes(internalFile, externalFile,
                min(internalLength, externalLength))) {
          if (internalLength == externalLength) {
            if (internalLength == 0) {
              _unavailable(name, 'both copies are empty');
            }
            return;
          }
          final externalIsShorter = externalLength < internalLength;
          final repaired = externalIsShorter
              ? await _replaceExternal(name)
              : await _replaceInternal(name, externalSize);
          if (repaired) {
            _summary.repaired++;
            _logger.info('reconcile: replaced shorter '
                '${externalIsShorter ? 'external folder' : 'internal'} '
                'copy of $name');
          }
          return;
        }
      }
      _summary.conflicts++;
      _logger.warning('reconcile: conflict on $name, internal copy is '
          '${_internalSizes[name]} bytes and external folder copy is listed as '
          '$externalSize bytes; leaving both');
    } finally {
      await scratch.delete(recursive: true);
    }
  }

  Future<File?> _internalFile(String name, Directory scratch) async {
    final internal = _internal;
    if (internal is LocalFileStore) {
      return File(join(internal.directoryPath, name));
    }
    final copy = File(join(scratch.path, 'internal'));
    return await internal.copyToFile(name, copy) ? copy : null;
  }

  Future<File?> _externalFile(String name, Directory scratch) async {
    final copy = File(join(scratch.path, 'external'));
    return await _copyExternal(name, copy) ? copy : null;
  }

  Future<bool> _startWithSameBytes(File first, File second, int length) async {
    final firstHandle = await first.open();
    final secondHandle = await second.open();
    try {
      for (var offset = 0; offset < length; offset += _compareChunkBytes) {
        final size = min(_compareChunkBytes, length - offset);
        if (!listEquals(
            await firstHandle.read(size), await secondHandle.read(size))) {
          return false;
        }
      }
      return true;
    } finally {
      await firstHandle.close();
      await secondHandle.close();
    }
  }

  Future<bool> _upload(String name) async {
    final length = await _internal.size(name);
    if (length == null || length == 0) {
      _logger.severe('reconcile: upload of $name failed, could not read it');
      _failed();
      return false;
    }
    return _tally(await _storage._createExternal(name, length,
        () => _storage._uploadFromInternal(_external, _internal, name)));
  }

  Future<bool> _replaceExternal(String name) async {
    final deleted = await _storage.externalSyncHealth.record(
        "reconcile: delete of shorter $name",
        () => _timed(_external.delete(name)));
    if (!deleted) {
      _failedWrite();
      return false;
    }
    return _upload(name);
  }

  Future<bool> _replaceInternal(String name, int externalSize) async {
    if (!await _internal.delete(name)) {
      _logger.severe('reconcile: delete of internal $name failed');
      _failedWrite();
      return false;
    }
    return _downloadMissing(name, externalSize);
  }

  Future<bool> _download(
      String name, Future<CreateResult?> Function() create) async {
    final CreateResult? result;
    try {
      result = await create();
    } catch (error) {
      _logger.severe('reconcile: download of $name failed', error);
      _failedWrite();
      return false;
    }
    if (result == null) return false;
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
      final bytes =
          await _timed(_external.read(name), bytes: _externalSizes[name] ?? 0);
      if (bytes == null) {
        _logger.warning(
            'reconcile: could not read $name from the external folder');
      }
      return bytes;
    } catch (error) {
      _logger.warning(
          'reconcile: read of $name from the external folder failed', error);
      return null;
    }
  }

  Future<bool> _copyExternal(String name, File destination) async {
    try {
      final copied = await _timed(_external.copyToFile(name, destination),
          bytes: _externalSizes[name] ?? 0);
      if (!copied) {
        _logger.warning(
            'reconcile: could not read $name from the external folder');
      }
      return copied;
    } catch (error) {
      _logger.warning(
          'reconcile: read of $name from the external folder failed', error);
      return false;
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
