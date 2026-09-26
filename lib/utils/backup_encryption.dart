import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:daily_you/utils/cancellation_token.dart';
import 'package:daily_you/utils/crypto_utils.dart';
import 'package:flutter/foundation.dart';

class BackupDecryptionFailedException implements Exception {}

class BackupEncryption {
  // AES-256-CTR, unauthenticated
  // A canary block catches a wrong password or garbled file without paying for a full-file MAC
  static final Uint8List _magic = Uint8List.fromList('DYENC1'.codeUnits);

  static const _magicLength = 6;
  static const _saltLength = 16;
  static const _ctrIvLength = 16;
  static const _aesKeyLength = 32;
  static const _canaryLength = 16;
  static final Uint8List _canaryPlaintext = Uint8List(_canaryLength);
  static const _chunkSize = 1 << 20; // 1 MiB

  static Future<bool> looksEncrypted(File file) async {
    if (await file.length() < _magicLength) return false;
    final input = await file.open();
    try {
      final header = await input.read(_magicLength);
      return constantTimeEquals(header, _magic);
    } finally {
      await input.close();
    }
  }

  static Future<void> encryptFile(
      String inputFile, String outputFile, String password,
      {Function(double percent)? onProgress,
      CancellationToken? cancellationToken}) async {
    if (cancellationToken?.isCancelled ?? false) {
      throw BackupCancelledException();
    }

    var rxPort = ReceivePort();
    var completer = Completer<void>();

    rxPort.listen((data) {
      if (data is String && data == _done) {
        if (!completer.isCompleted) completer.complete();
      } else if (data is String) {
        if (!completer.isCompleted) completer.completeError(Exception(data));
      } else {
        onProgress?.call(data);
      }
    });

    final isolate = await Isolate.spawn(_encryptIsolate, {
      "inputFile": inputFile,
      "outputFile": outputFile,
      "password": password,
      "port": rxPort.sendPort,
    });

    cancellationToken?.attachIsolate(isolate, () {
      if (!completer.isCompleted) {
        completer.completeError(BackupCancelledException());
      }
    });

    try {
      await completer.future;
    } finally {
      cancellationToken?.detach();
      rxPort.close();
      isolate.kill(priority: Isolate.immediate);
    }
  }

  static Future<void> decryptFile(
      String inputFile, String outputFile, String password,
      {Function(double percent)? onProgress}) async {
    var rxPort = ReceivePort();

    rxPort.listen((data) {
      if (onProgress != null && data is num) {
        onProgress(data.toDouble());
      }
    });

    await compute(_decryptIsolate, {
      "inputFile": inputFile,
      "outputFile": outputFile,
      "password": password,
      "port": rxPort.sendPort,
    });

    rxPort.close();
  }

  static const _done = 'done';

  static Future<void> _encryptIsolate(Map<String, dynamic> args) async {
    SendPort sendPort = args["port"];
    try {
      await _encryptStream(
        inputPath: args["inputFile"],
        outputPath: args["outputFile"],
        password: args["password"],
        onProgress: (percent) => sendPort.send(percent),
      );
      sendPort.send(_done);
    } catch (error) {
      sendPort.send(error.toString());
    }
  }

  static Future<void> _decryptIsolate(Map<String, dynamic> args) async {
    SendPort sendPort = args["port"];
    await _decryptStream(
      inputPath: args["inputFile"],
      outputPath: args["outputFile"],
      password: args["password"],
      onProgress: (percent) => sendPort.send(percent),
    );
  }

  static Future<void> _encryptStream({
    required String inputPath,
    required String outputPath,
    required String password,
    void Function(double percent)? onProgress,
  }) async {
    final totalSize = await File(inputPath).length();
    final input = File(inputPath).openSync(mode: FileMode.read);
    final output = File(outputPath).openSync(mode: FileMode.writeOnly);

    try {
      final salt = secureRandomBytes(_saltLength);
      final iv = secureRandomBytes(_ctrIvLength);
      final key = deriveArgon2idKey(
          password: password, salt: salt, keyLength: _aesKeyLength);
      final cipher = AesCtrCipher(key, Uint8List.fromList(iv));

      final canaryCiphertext = Uint8List(_canaryLength);
      cipher.process(_canaryPlaintext, _canaryLength, canaryCiphertext);

      output.writeFromSync(_magic);
      output.writeFromSync(salt);
      output.writeFromSync(iv);
      output.writeFromSync(canaryCiphertext);

      var processed = 0;
      final readBuffer = Uint8List(_chunkSize);
      final writeBuffer = Uint8List(_chunkSize);
      while (true) {
        final bytesRead = input.readIntoSync(readBuffer);
        if (bytesRead <= 0) break;

        cipher.process(readBuffer, bytesRead, writeBuffer);
        output.writeFromSync(writeBuffer, 0, bytesRead);

        processed += bytesRead;
        if (totalSize > 0) {
          onProgress?.call((processed / totalSize) * 100);
        }
      }
    } finally {
      input.closeSync();
      output.closeSync();
    }
  }

  static Future<void> _decryptStream({
    required String inputPath,
    required String outputPath,
    required String password,
    void Function(double percent)? onProgress,
  }) async {
    final totalSize = await File(inputPath).length();
    final input = File(inputPath).openSync(mode: FileMode.read);
    final output = File(outputPath).openSync(mode: FileMode.writeOnly);

    try {
      final header = input.readSync(_magicLength);
      final salt = input.readSync(_saltLength);
      final iv = input.readSync(_ctrIvLength);
      final canaryCiphertext = input.readSync(_canaryLength);
      if (!constantTimeEquals(header, _magic) ||
          salt.length != _saltLength ||
          iv.length != _ctrIvLength ||
          canaryCiphertext.length != _canaryLength) {
        throw BackupDecryptionFailedException();
      }

      var cipherTextLength =
          totalSize - _magicLength - _saltLength - _ctrIvLength - _canaryLength;
      if (cipherTextLength < 0) throw BackupDecryptionFailedException();

      final key = deriveArgon2idKey(
          password: password, salt: salt, keyLength: _aesKeyLength);
      final cipher = AesCtrCipher(key, Uint8List.fromList(iv));

      final canaryPlaintext = Uint8List(_canaryLength);
      cipher.process(canaryCiphertext, _canaryLength, canaryPlaintext);
      if (!constantTimeEquals(canaryPlaintext, _canaryPlaintext)) {
        throw BackupDecryptionFailedException();
      }

      var processed = 0;
      final readBuffer = Uint8List(_chunkSize);
      final writeBuffer = Uint8List(_chunkSize);
      while (cipherTextLength > 0) {
        final toRead =
            cipherTextLength < _chunkSize ? cipherTextLength : _chunkSize;
        final bytesRead = input.readIntoSync(readBuffer, 0, toRead);
        if (bytesRead <= 0) throw BackupDecryptionFailedException();

        cipher.process(readBuffer, bytesRead, writeBuffer);
        output.writeFromSync(writeBuffer, 0, bytesRead);

        cipherTextLength -= bytesRead;
        processed += bytesRead;
        if (totalSize > 0) {
          onProgress?.call((processed / totalSize) * 100);
        }
      }
    } finally {
      input.closeSync();
      output.closeSync();
    }
  }
}
