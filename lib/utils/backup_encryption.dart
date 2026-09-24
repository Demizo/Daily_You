import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:daily_you/utils/cancellation_token.dart';
import 'package:daily_you/utils/crypto_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:pointycastle/export.dart';

class BackupDecryptionFailedException implements Exception {}

class BackupEncryption {
  static final Uint8List _magic = Uint8List.fromList('DYENC1'.codeUnits);
  static const _saltLength = 16;
  static const _nonceLength = 12;
  static const _chunkSize = 1 << 20; // 1 MiB

  static Future<bool> looksEncrypted(File file) async {
    if (await file.length() < _magic.length) return false;
    final input = await file.open();
    try {
      final header = await input.read(_magic.length);
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
      await _runCipher(
        forEncryption: true,
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
    await _runCipher(
      forEncryption: false,
      inputPath: args["inputFile"],
      outputPath: args["outputFile"],
      password: args["password"],
      onProgress: (percent) => sendPort.send(percent),
    );
  }

  static Future<void> _runCipher({
    required bool forEncryption,
    required String inputPath,
    required String outputPath,
    required String password,
    void Function(double percent)? onProgress,
  }) async {
    final totalSize = await File(inputPath).length();
    final input = File(inputPath).openSync(mode: FileMode.read);
    final output = File(outputPath).openSync(mode: FileMode.writeOnly);

    try {
      final Uint8List salt;
      final Uint8List nonce;

      if (forEncryption) {
        salt = secureRandomBytes(_saltLength);
        nonce = secureRandomBytes(_nonceLength);
        output.writeFromSync(_magic);
        output.writeFromSync(salt);
        output.writeFromSync(nonce);
      } else {
        final header = input.readSync(_magic.length);
        if (!constantTimeEquals(header, _magic)) {
          throw BackupDecryptionFailedException();
        }
        salt = input.readSync(_saltLength);
        nonce = input.readSync(_nonceLength);
        if (salt.length != _saltLength || nonce.length != _nonceLength) {
          throw BackupDecryptionFailedException();
        }
      }

      final key = deriveArgon2idKey(password: password, salt: salt);
      final cipher = GCMBlockCipher(AESEngine())
        ..init(forEncryption,
            AEADParameters(KeyParameter(key), 128, nonce, Uint8List(0)));

      var processed = 0;
      final readBuffer = Uint8List(_chunkSize);
      while (true) {
        final bytesRead = input.readIntoSync(readBuffer);
        if (bytesRead <= 0) break;

        final outBuffer = Uint8List(cipher.getOutputSize(bytesRead) + 32);
        final outLength =
            cipher.processBytes(readBuffer, 0, bytesRead, outBuffer, 0);
        if (outLength > 0) {
          output.writeFromSync(outBuffer, 0, outLength);
        }

        processed += bytesRead;
        if (totalSize > 0) {
          onProgress?.call((processed / totalSize) * 100);
        }
      }

      final finalBuffer = Uint8List(64);
      final finalLength = cipher.doFinal(finalBuffer, 0);
      if (finalLength > 0) {
        output.writeFromSync(finalBuffer, 0, finalLength);
      }
    } on InvalidCipherTextException {
      throw BackupDecryptionFailedException();
    } finally {
      input.closeSync();
      output.closeSync();
    }
  }
}
