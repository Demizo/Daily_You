import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/database/image_storage.dart';
import 'package:daily_you/models/image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' show extension;

/// Handles incoming shared images from Android via a custom MethodChannel.
///
/// Integration points:
///   - [init] is called once in `main()` (inside the Android block) to
///     register the warm-start stream listener before the app renders.
///   - [getInitialSharedFiles] is called in `LaunchPage._checkDatabaseConnection`
///     after `AppDatabase.instance.init()` succeeds. The result is stored as a
///     `ShareFilesIntent` in `DeviceInfoService` and consumed by
///     `HomePage._checkForLaunchIntent` → `ShareToEntryPage`.
///   - [sharingFilesStream] is subscribed to in `MobileScaffold.initState`
///     for warm-start shares; emits raw local file paths.
///   - [saveSharedImages] compresses and stores images; called from
///     `ShareToEntryPage._addToEntry`.
class ShareIntentService {
  ShareIntentService._();
  static final ShareIntentService instance = ShareIntentService._();

  static const MethodChannel _channel =
      MethodChannel('com.demizo.daily_you/share');

  final StreamController<List<String>> _rawFilesController =
      StreamController<List<String>>.broadcast();

  /// Warm-start stream. Emits local file paths when a share arrives while the
  /// app is already running. Subscribe in `MobileScaffold.initState`.
  Stream<List<String>> get sharingFilesStream => _rawFilesController.stream;

  bool _initialized = false;
  String? _lastWarmStartKey;

  /// Registers the warm-start MethodChannel handler.
  ///
  /// Safe to call multiple times — no-op after first call.
  /// Call early in `main()` so no warm-start shares are missed.
  void init() {
    if (_initialized) return;
    _initialized = true;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onSharedFiles') {
        final uris = _toUriList(call.arguments);
        if (uris.isEmpty) return;
        // Deduplicate: onNewIntent may fire on activity recreation.
        final key = uris.join('|');
        if (key == _lastWarmStartKey) return;
        _lastWarmStartKey = key;
        _rawFilesController.add(uris);
      }
    });
  }

  /// Returns raw file paths from the cold-start share intent, or `null` if
  /// the app was not launched via a share action.
  ///
  /// Call after `AppDatabase.instance.init()` so the caller can safely route
  /// to `ShareToEntryPage`.
  Future<List<String>?> getInitialSharedFiles() async {
    try {
      final result =
          await _channel.invokeMethod<dynamic>('getInitialSharedFiles');
      final uris = _toUriList(result);
      return uris.isEmpty ? null : uris;
    } on PlatformException catch (e) {
      debugPrint('ShareIntentService: getInitialSharedFiles failed: $e');
      return null;
    }
  }

  /// Compresses and stores images at [filePaths], returning [EntryImage]
  /// records ready for `EntryImagesProvider.add`.
  ///
  /// Individual failures are silently skipped (partial-success behaviour).
  Future<List<EntryImage>> saveSharedImages(
      List<String> filePaths, int entryId) async {
    final saved = <EntryImage>[];

    for (int i = 0; i < filePaths.length; i++) {
      final path = filePaths[i];
      try {
        final bytes = await _compressAndLoad(path);
        final imageName =
            await ImageStorage.instance.create(_fileNameHint(path), bytes);
        if (imageName == null) continue;

        saved.add(EntryImage(
          entryId: entryId,
          imgPath: imageName,
          imgRank: filePaths.length - 1 - i,
          timeCreate: DateTime.now(),
        ));
      } catch (e) {
        debugPrint('ShareIntentService: failed to process $path: $e');
      }
    }

    return saved;
  }

  /// Reads raw bytes from [uri].
  ///
  /// Handles both plain file paths and `content://` URIs — the latter are
  /// read via the native MethodChannel since `File()` cannot open them on
  /// Android. Used by [ShareImagePreview] for in-app image rendering.
  Future<Uint8List?> readUriBytes(String uri) async {
    try {
      return await _readContentUri(uri);
    } catch (e) {
      debugPrint('ShareIntentService: readUriBytes failed for $uri: $e');
      return null;
    }
  }

  void dispose() {
    // Clear the handler rather than closing the singleton StreamController,
    // which cannot be reopened if the service is reused.
    _channel.setMethodCallHandler(null);
    _initialized = false;
    _lastWarmStartKey = null;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  List<String> _toUriList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw.whereType<String>().toList();
    return const [];
  }

  /// Compression logic mirrors `entry_image_picker.dart:73-98` exactly.
  Future<Uint8List> _compressAndLoad(String contentUri) async {
    // Read raw bytes from the content:// URI via the native MethodChannel.
    // File() cannot open content:// URIs on Android.
    final rawBytes = await _readContentUri(contentUri);

    final quality = ConfigProvider.instance.get(ConfigKey.imageQualityLevel);
    // Derive a hint extension from the URI for GIF detection.
    final ext = extension(contentUri.split('?').first).toLowerCase();

    if (ext == '.gif' || quality == ImageQuality.noCompression) {
      return rawBytes;
    }

    final width =
        (ConfigProvider.imageQualityMaxSizeMapping[quality] ?? 1600).toInt();
    final compressionQuality =
        ConfigProvider.imageQualityCompressionMapping[quality] ?? 100;

    if (Platform.isAndroid) {
      return await FlutterImageCompress.compressWithList(
            rawBytes,
            quality: compressionQuality,
            minWidth: width,
            minHeight: width,
          ) ??
          rawBytes;
    }

    return rawBytes;
  }

  /// Reads bytes from a content:// URI via the native MethodChannel.
  Future<Uint8List> _readContentUri(String uri) async {
    // If it's already a plain file path, read directly.
    if (!uri.startsWith('content://')) {
      return File(uri).readAsBytes();
    }
    try {
      final result = await _channel.invokeMethod<dynamic>(
          'readFileBytes', {'uri': uri});
      if (result is Uint8List) return result;
      if (result is List) return Uint8List.fromList(result.cast<int>());
      throw Exception('readFileBytes returned unexpected type: ${result.runtimeType}');
    } on PlatformException catch (e) {
      debugPrint('ShareIntentService: readFileBytes failed for $uri: $e');
      rethrow;
    }
  }

  String? _fileNameHint(String path) {
    final segment = path.split('/').last.split('?').first;
    return segment.isNotEmpty ? segment : null;
  }
}
