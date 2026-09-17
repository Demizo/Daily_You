import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

class SafTransfer {
  static const MethodChannel _channel = MethodChannel('saf_transfer');

  // A map to hold active progress callbacks referenced by their transfer ID
  static final Map<String, Function(double)> _progressCallbacks = {};
  static bool _isInitialized = false;

  /// Initialize the listener once
  static void _initListener() {
    if (_isInitialized) return;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'transferProgress') {
        final String id = call.arguments['id'];
        final double progress = call.arguments['progress'];

        if (_progressCallbacks.containsKey(id)) {
          _progressCallbacks[id]!(progress);
        }
      }
    });

    _isInitialized = true;
  }

  /// Copy a file from external storage to local storage
  static Future<bool> copyFromExternalLocation(
      String externalFileUri, String localDestPath,
      {Function(double percent)? onProgress}) async {
    _initListener();
    final transferId = const Uuid().v4();

    if (onProgress != null) {
      _progressCallbacks[transferId] = onProgress;
    }

    try {
      await _channel.invokeMethod('copyFromExternal', {
        'src': externalFileUri,
        'dest': localDestPath,
        'transferId': transferId,
      });

      // Ensure 100% is fired at completion
      if (onProgress != null) onProgress(100.0);
      return true;
    } catch (e) {
      return false;
    } finally {
      // Clean up callback memory to prevent leaks
      _progressCallbacks.remove(transferId);
    }
  }

  /// Copy a file from local storage to external storage (SAF)
  static Future<bool> copyToExternalLocation(
      String localFilePath, String treeUri, String fileName, String mimeType,
      {bool overwrite = false,
      bool append = false,
      Function(double percent)? onProgress}) async {
    _initListener();
    final transferId = const Uuid().v4();

    if (onProgress != null) {
      _progressCallbacks[transferId] = onProgress;
    }

    try {
      final result = await _channel.invokeMethod('copyToExternal', {
        'treeUri': treeUri,
        'fileName': fileName,
        'mime': mimeType,
        'localSrc': localFilePath,
        'overwrite': overwrite,
        'append': append,
        'transferId': transferId,
      });

      if (onProgress != null) onProgress(100.0);
      return result != null;
    } catch (e) {
      return false;
    } finally {
      _progressCallbacks.remove(transferId);
    }
  }
}
