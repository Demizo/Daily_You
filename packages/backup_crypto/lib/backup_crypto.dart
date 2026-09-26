import 'package:flutter/services.dart';

class BackupCryptoCancelledException implements Exception {}

class BackupCryptoDecryptionFailedException implements Exception {}

class BackupCrypto {
  static const MethodChannel _channel = MethodChannel('backup_crypto');
  static final Map<String, void Function(double percent)> _progressCallbacks =
      {};
  static bool _isListening = false;

  static void _ensureListening() {
    if (_isListening) return;
    _isListening = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'progress') {
        final args = call.arguments as Map;
        final requestId = args['requestId'] as String;
        final percent = (args['percent'] as num).toDouble();
        _progressCallbacks[requestId]?.call(percent);
      }
    });
  }

  static Future<void> encryptBody({
    required String requestId,
    required String inputPath,
    required String outputPath,
    required Uint8List key,
    required Uint8List baseNonce,
    required int chunkPlainSize,
    required int totalPlainLength,
    required int headerLength,
    void Function(double percent)? onProgress,
  }) =>
      _runBody(
        'encryptBody',
        requestId: requestId,
        inputPath: inputPath,
        outputPath: outputPath,
        key: key,
        baseNonce: baseNonce,
        chunkPlainSize: chunkPlainSize,
        totalPlainLength: totalPlainLength,
        headerLength: headerLength,
        onProgress: onProgress,
      );

  static Future<void> decryptBody({
    required String requestId,
    required String inputPath,
    required String outputPath,
    required Uint8List key,
    required Uint8List baseNonce,
    required int chunkPlainSize,
    required int totalPlainLength,
    required int headerLength,
    void Function(double percent)? onProgress,
  }) =>
      _runBody(
        'decryptBody',
        requestId: requestId,
        inputPath: inputPath,
        outputPath: outputPath,
        key: key,
        baseNonce: baseNonce,
        chunkPlainSize: chunkPlainSize,
        totalPlainLength: totalPlainLength,
        headerLength: headerLength,
        onProgress: onProgress,
      );

  /// Flips a cooperative cancel flag native checks once per chunk. Does not
  /// itself throw; the in-flight [encryptBody]/[decryptBody] call surfaces
  /// the cancellation as a [BackupCryptoCancelledException].
  static Future<void> cancel(String requestId) =>
      _channel.invokeMethod('cancel', {'requestId': requestId});

  static Future<void> _runBody(
    String method, {
    required String requestId,
    required String inputPath,
    required String outputPath,
    required Uint8List key,
    required Uint8List baseNonce,
    required int chunkPlainSize,
    required int totalPlainLength,
    required int headerLength,
    void Function(double percent)? onProgress,
  }) async {
    _ensureListening();
    if (onProgress != null) _progressCallbacks[requestId] = onProgress;
    try {
      await _channel.invokeMethod(method, {
        'inputPath': inputPath,
        'outputPath': outputPath,
        'key': key,
        'baseNonce': baseNonce,
        'chunkPlainSize': chunkPlainSize,
        'totalPlainLength': totalPlainLength,
        'headerLength': headerLength,
        'requestId': requestId,
      });
    } on PlatformException catch (error) {
      if (error.code == 'CANCELLED') throw BackupCryptoCancelledException();
      if (error.code == 'DECRYPTION_FAILED') {
        throw BackupCryptoDecryptionFailedException();
      }
      rethrow;
    } finally {
      _progressCallbacks.remove(requestId);
    }
  }
}
