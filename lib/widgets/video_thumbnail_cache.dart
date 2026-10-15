// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:async';
import 'dart:typed_data';

import 'package:daily_you/database/attachment_storage.dart';
import 'package:daily_you/file_bytes_cache.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:logging/logging.dart';
import 'package:pool/pool.dart';

class VideoThumbnailCache {
  static final VideoThumbnailCache instance = VideoThumbnailCache._internal();

  VideoThumbnailCache._internal()
      : _diskCache = CacheManager(
          Config(
            'videoThumbnails',
            stalePeriod: const Duration(days: 30),
            maxNrOfCacheObjects: 500,
          ),
        ) {
    AttachmentStorage.instance.cacheVersion.addListener(_onCacheInvalidated);
    AttachmentStorage.instance.deletions.listen(_onAttachmentDeleted);
  }

  void _onCacheInvalidated() {
    _memoryCache.clear();
    _failedAt.clear();
    unawaited(_diskCache.emptyCache());
  }

  void _onAttachmentDeleted(({AttachmentType type, String fileName}) deleted) {
    if (deleted.type != AttachmentType.video) return;
    _memoryCache.remove(deleted.fileName);
    _failedAt.remove(deleted.fileName);
    unawaited(_diskCache.removeFile(deleted.fileName));
  }

  static const Duration _failureRetryDelay = Duration(minutes: 5);

  final Logger _logger = Logger('VideoThumbnailCache');
  final CacheManager _diskCache;
  final FileBytesCache _memoryCache =
      FileBytesCache(maxCacheSize: 5 * 1024 * 1024);
  final Map<String, Future<Uint8List?>> _inFlight = {};
  final Map<String, DateTime> _failedAt = {};
  final Pool _generatePool = Pool(2);

  Uint8List? peek(String videoFileName) => _memoryCache.get(videoFileName);

  Future<Uint8List?> getThumbnail(String videoFileName) => _get(
        videoFileName,
        resolvePath: () => AttachmentStorage.instance
            .getLocalPath(videoFileName, AttachmentType.video),
        persist: true,
      );

  Future<Uint8List?> getThumbnailForPath(String localPath) => _get(
        _pathKey(localPath),
        resolvePath: () async => localPath,
        persist: false,
      );

  Uint8List? peekForPath(String localPath) =>
      _memoryCache.get(_pathKey(localPath));

  static String _pathKey(String localPath) => 'path:$localPath';

  Future<Uint8List?> _get(
    String videoFileName, {
    required Future<String?> Function() resolvePath,
    required bool persist,
  }) {
    final cached = _memoryCache.get(videoFileName);
    if (cached != null) return Future.value(cached);

    final failedAt = _failedAt[videoFileName];
    if (failedAt != null) {
      if (DateTime.now().difference(failedAt) < _failureRetryDelay) {
        return Future.value(null);
      }
      _failedAt.remove(videoFileName);
    }

    return _inFlight[videoFileName] ??=
        _load(videoFileName, resolvePath, persist).whenComplete(() {
      _inFlight.remove(videoFileName);
    });
  }

  Future<Uint8List?> _load(
    String videoFileName,
    Future<String?> Function() resolvePath,
    bool persist,
  ) async {
    try {
      if (persist) {
        final fromDisk = await _readFromDisk(videoFileName);
        if (fromDisk != null) {
          _memoryCache.put(videoFileName, fromDisk);
          return fromDisk;
        }
      }

      final bytes =
          await _generatePool.withResource(() => _generate(resolvePath));
      if (bytes == null) {
        _failedAt[videoFileName] = DateTime.now();
        return null;
      }

      _memoryCache.put(videoFileName, bytes);
      if (persist) unawaited(_writeToDisk(videoFileName, bytes));
      return bytes;
    } catch (error, stackTrace) {
      _logger.warning('Thumbnail for $videoFileName failed', error, stackTrace);
      _failedAt[videoFileName] = DateTime.now();
      return null;
    }
  }

  Future<void> _writeToDisk(String videoFileName, Uint8List bytes) async {
    try {
      await _diskCache.putFile(videoFileName, bytes, fileExtension: 'jpg');
    } catch (error) {
      _logger.warning('Could not cache thumbnail for $videoFileName', error);
    }
  }

  Future<Uint8List?> _readFromDisk(String videoFileName) async {
    try {
      final fileInfo = await _diskCache.getFileFromCache(videoFileName);
      return await fileInfo?.file.readAsBytes();
    } catch (error) {
      _logger.warning('Could not read cached thumbnail', error);
      return null;
    }
  }

  Future<Uint8List?> _generate(Future<String?> Function() resolvePath) async {
    final localPath = await resolvePath();
    if (localPath == null) return null;

    return FcNativeVideoThumbnail().saveThumbnailToBytes(
      srcFile: localPath,
      width: 480,
      height: 480,
    );
  }
}
