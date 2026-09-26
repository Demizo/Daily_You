import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:backup_crypto/backup_crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';
import 'package:daily_you/utils/cancellation_token.dart';
import 'package:daily_you/utils/crypto_utils.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

class BackupDecryptionFailedException implements Exception {}

class _KeyMaterial {
  _KeyMaterial(
      this.key, this.baseNonce, this.chunkPlainSize, this.totalPlainLength);
  final Uint8List key;
  final Uint8List baseNonce;
  final int chunkPlainSize;
  final int totalPlainLength;
}

enum _Direction { encrypt, decrypt }

class BackupEncryption {
  static final Logger _logger = Logger('BackupEncryption');

  static final Uint8List _magic = Uint8List.fromList('DYENC1'.codeUnits);

  static const _magicLength = 6;
  static const _saltLength = 16;
  static const _baseNonceLength = 4;
  static const _nonceLength = 12; // AesGcm.defaultNonceLength
  static const _tagLength = 16; // AES-GCM tag length
  static const _keyLength = 32;
  static const _headerLength =
      _magicLength + _saltLength + _baseNonceLength + 4 + 8;

  static final bool _hasNativeAcceleration =
      Platform.isAndroid || Platform.isIOS;

  static const _chunkPlainSize = 16 << 20;

  static const _maxDesktopWorkers = 4;
  static const _reservedDesktopCores = 2;

  static final AesGcm _cipher =
      _hasNativeAcceleration ? AesGcm.with256bits() : DartAesGcm.with256bits();

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

    final plainLength = await File(inputFile).length();
    final keyMaterial = await _prepareEncrypt(
        outputFile, password, plainLength, cancellationToken);

    await _processChunks(
      label: 'encrypt',
      direction: _Direction.encrypt,
      inputFile: inputFile,
      outputFile: outputFile,
      keyMaterial: keyMaterial,
      onProgress: onProgress,
      cancellationToken: cancellationToken,
    );
  }

  static Future<void> decryptFile(
      String inputFile, String outputFile, String password,
      {Function(double percent)? onProgress,
      CancellationToken? cancellationToken}) async {
    if (cancellationToken?.isCancelled ?? false) {
      throw BackupCancelledException();
    }

    final keyMaterial = await _prepareDecrypt(
        inputFile, outputFile, password, cancellationToken);

    await _processChunks(
      label: 'decrypt',
      direction: _Direction.decrypt,
      inputFile: inputFile,
      outputFile: outputFile,
      keyMaterial: keyMaterial,
      onProgress: onProgress,
      cancellationToken: cancellationToken,
    );
  }

  static const _done = 'done';
  static const _decryptionFailedSentinel = 'decryption_failed';

  static int _totalChunksFor(int totalPlainLength, int chunkPlainSize) {
    if (totalPlainLength <= 0) return 0;
    return ((totalPlainLength - 1) ~/ chunkPlainSize) + 1;
  }

  static int _workerCountFor(int totalChunks) {
    if (_hasNativeAcceleration || totalChunks <= 1) return 1;
    final availableCores = Platform.numberOfProcessors - _reservedDesktopCores;
    final maxByCores = availableCores < 1
        ? 1
        : (availableCores > _maxDesktopWorkers
            ? _maxDesktopWorkers
            : availableCores);
    return totalChunks < maxByCores ? totalChunks : maxByCores;
  }

  static Future<void> _processChunks({
    required String label,
    required _Direction direction,
    required String inputFile,
    required String outputFile,
    required _KeyMaterial keyMaterial,
    void Function(double percent)? onProgress,
    CancellationToken? cancellationToken,
  }) async {
    final totalChunks = _totalChunksFor(
        keyMaterial.totalPlainLength, keyMaterial.chunkPlainSize);
    if (totalChunks == 0) {
      onProgress?.call(100);
      return;
    }
    if (cancellationToken?.isCancelled ?? false) {
      throw BackupCancelledException();
    }

    // On Android defer to native plugin for full file encryption
    if (Platform.isAndroid) {
      _logger
          .info('$label (native): bodyLength=${keyMaterial.totalPlainLength}');
      final requestId = const Uuid().v4();
      cancellationToken
          ?.attachNativeCancel(() => BackupCrypto.cancel(requestId));
      try {
        final run = direction == _Direction.encrypt
            ? BackupCrypto.encryptBody
            : BackupCrypto.decryptBody;
        await run(
          requestId: requestId,
          inputPath: inputFile,
          outputPath: outputFile,
          key: keyMaterial.key,
          baseNonce: keyMaterial.baseNonce,
          chunkPlainSize: keyMaterial.chunkPlainSize,
          totalPlainLength: keyMaterial.totalPlainLength,
          headerLength: _headerLength,
          onProgress: onProgress,
        );
      } on BackupCryptoCancelledException {
        throw BackupCancelledException();
      } on BackupCryptoDecryptionFailedException {
        throw BackupDecryptionFailedException();
      } finally {
        cancellationToken?.detach();
      }
      return;
    }

    final workerCount = _workerCountFor(totalChunks);
    final chunksPerWorker = (totalChunks + workerCount - 1) ~/ workerCount;

    _logger.info('$label: bodyLength=${keyMaterial.totalPlainLength} '
        'cores=${Platform.numberOfProcessors} '
        'hasNativeAcceleration=$_hasNativeAcceleration '
        'totalChunks=$totalChunks workerCount=$workerCount');

    final processedByWorker = List<int>.filled(workerCount, 0);
    var pendingWorkers = workerCount;

    var rxPort = ReceivePort();
    var completer = Completer<void>();

    rxPort.listen((data) {
      if (completer.isCompleted) return;
      if (data is List) {
        processedByWorker[data[0] as int] = data[1] as int;
        var total = 0;
        for (final processed in processedByWorker) {
          total += processed;
        }
        onProgress?.call((total / keyMaterial.totalPlainLength) * 100);
      } else if (data == _done) {
        pendingWorkers--;
        if (pendingWorkers == 0) completer.complete();
      } else if (data == _decryptionFailedSentinel) {
        completer.completeError(BackupDecryptionFailedException());
      } else {
        completer.completeError(Exception(data));
      }
    });

    final isolates = <Isolate>[];
    for (var workerIndex = 0; workerIndex < workerCount; workerIndex++) {
      final startChunk = workerIndex * chunksPerWorker;
      if (startChunk >= totalChunks) break;
      final endChunk = startChunk + chunksPerWorker < totalChunks
          ? startChunk + chunksPerWorker
          : totalChunks;

      isolates.add(await Isolate.spawn(_chunkWorkerIsolate, {
        "direction": direction.index,
        "inputFile": inputFile,
        "outputFile": outputFile,
        "key": keyMaterial.key,
        "baseNonce": keyMaterial.baseNonce,
        "chunkPlainSize": keyMaterial.chunkPlainSize,
        "totalPlainLength": keyMaterial.totalPlainLength,
        "startChunk": startChunk,
        "endChunk": endChunk,
        "workerIndex": workerIndex,
        "rootIsolateToken": RootIsolateToken.instance,
        "port": rxPort.sendPort,
      }));
    }
    pendingWorkers = isolates.length;

    cancellationToken?.attachIsolates(isolates, () {
      if (!completer.isCompleted) {
        completer.completeError(BackupCancelledException());
      }
    });

    try {
      await completer.future;
    } finally {
      cancellationToken?.detach();
      rxPort.close();
      for (final isolate in isolates) {
        isolate.kill(priority: Isolate.immediate);
      }
    }
  }

  static void _initPlatformChannelsIfNeeded(Map<String, dynamic> args) {
    final rootIsolateToken = args["rootIsolateToken"] as RootIsolateToken?;
    if (rootIsolateToken != null) {
      BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
    }
  }

  static Future<void> _chunkWorkerIsolate(Map<String, dynamic> args) async {
    _initPlatformChannelsIfNeeded(args);
    SendPort sendPort = args["port"];
    final workerIndex = args["workerIndex"] as int;
    final direction = _Direction.values[args["direction"] as int];
    final chunkPlainSize = args["chunkPlainSize"] as int;
    final totalPlainLength = args["totalPlainLength"] as int;
    final startChunk = args["startChunk"] as int;
    final endChunk = args["endChunk"] as int;
    final key = args["key"] as Uint8List;
    final baseNonce = args["baseNonce"] as Uint8List;
    final onDiskChunkSize = chunkPlainSize + _tagLength;

    final input = File(args["inputFile"]).openSync(mode: FileMode.read);
    final output =
        File(args["outputFile"]).openSync(mode: FileMode.writeOnlyAppend);
    try {
      final secretKey = SecretKeyData(key);
      var processed = 0;
      for (var chunkIndex = startChunk; chunkIndex < endChunk; chunkIndex++) {
        final chunkStart = chunkIndex * chunkPlainSize;
        final plainLength = totalPlainLength - chunkStart < chunkPlainSize
            ? totalPlainLength - chunkStart
            : chunkPlainSize;
        final nonce = _chunkNonce(baseNonce, chunkIndex);

        if (direction == _Direction.encrypt) {
          input.setPositionSync(chunkStart);
          final plainBytes = input.readSync(plainLength);
          if (plainBytes.length != plainLength) {
            throw Exception('Unexpected end of file');
          }
          final secretBox = await _cipher.encrypt(plainBytes,
              secretKey: secretKey, nonce: nonce);
          output.setPositionSync(_headerLength + chunkIndex * onDiskChunkSize);
          output.writeFromSync(secretBox.cipherText);
          output.writeFromSync(secretBox.mac.bytes);
        } else {
          input.setPositionSync(_headerLength + chunkIndex * onDiskChunkSize);
          final cipherBytes = input.readSync(plainLength);
          final tagBytes = input.readSync(_tagLength);
          if (cipherBytes.length != plainLength ||
              tagBytes.length != _tagLength) {
            throw BackupDecryptionFailedException();
          }
          final List<int> plainBytes;
          try {
            plainBytes = await _cipher.decrypt(
              SecretBox(cipherBytes, nonce: nonce, mac: Mac(tagBytes)),
              secretKey: secretKey,
            );
          } on SecretBoxAuthenticationError {
            throw BackupDecryptionFailedException();
          }
          output.setPositionSync(chunkStart);
          output.writeFromSync(plainBytes);
        }

        processed += plainLength;
        sendPort.send([workerIndex, processed]);
      }
      sendPort.send(_done);
    } on BackupDecryptionFailedException {
      sendPort.send(_decryptionFailedSentinel);
    } catch (error) {
      sendPort.send(error.toString());
    } finally {
      input.closeSync();
      output.closeSync();
    }
  }

  static Future<_KeyMaterial> _prepareEncrypt(String outputFile,
      String password, int plainLength, CancellationToken? cancellationToken) {
    return _spawnAndAwait(
      _prepareEncryptIsolate,
      {
        "outputFile": outputFile,
        "password": password,
        "plainLength": plainLength,
        "chunkPlainSize": _chunkPlainSize,
      },
      (data, completer) {
        if (data is List) {
          completer.complete(_KeyMaterial(data[0] as Uint8List,
              data[1] as Uint8List, _chunkPlainSize, plainLength));
        } else {
          completer.completeError(Exception(data));
        }
      },
      cancellationToken,
    );
  }

  static Future<void> _prepareEncryptIsolate(Map<String, dynamic> args) async {
    SendPort sendPort = args["port"];
    try {
      final plainLength = args["plainLength"] as int;
      final chunkPlainSize = args["chunkPlainSize"] as int;

      final salt = secureRandomBytes(_saltLength);
      final baseNonce = secureRandomBytes(_baseNonceLength);
      final key = deriveArgon2idKey(
          password: args["password"], salt: salt, keyLength: _keyLength);

      final totalChunks = _totalChunksFor(plainLength, chunkPlainSize);
      final totalOnDiskSize = plainLength + totalChunks * _tagLength;

      final output = File(args["outputFile"]).openSync(mode: FileMode.write);
      try {
        output.writeFromSync(_magic);
        output.writeFromSync(salt);
        output.writeFromSync(baseNonce);
        output.writeFromSync(_uint32BE(chunkPlainSize));
        output.writeFromSync(_uint64BE(plainLength));
        output.truncateSync(_headerLength + totalOnDiskSize);
      } finally {
        output.closeSync();
      }

      sendPort.send([key, baseNonce]);
    } catch (error) {
      sendPort.send(error.toString());
    }
  }

  static Future<_KeyMaterial> _prepareDecrypt(
      String inputFile,
      String outputFile,
      String password,
      CancellationToken? cancellationToken) {
    return _spawnAndAwait(
      _prepareDecryptIsolate,
      {
        "inputFile": inputFile,
        "outputFile": outputFile,
        "password": password,
      },
      (data, completer) {
        if (data is List) {
          completer.complete(_KeyMaterial(data[0] as Uint8List,
              data[1] as Uint8List, data[2] as int, data[3] as int));
        } else if (data == _decryptionFailedSentinel) {
          completer.completeError(BackupDecryptionFailedException());
        } else {
          completer.completeError(Exception(data));
        }
      },
      cancellationToken,
    );
  }

  static Future<T> _spawnAndAwait<T>(
    Future<void> Function(Map<String, dynamic>) entryPoint,
    Map<String, dynamic> args,
    void Function(dynamic data, Completer<T> completer) onMessage,
    CancellationToken? cancellationToken,
  ) async {
    final rxPort = ReceivePort();
    final completer = Completer<T>();

    rxPort.listen((data) {
      if (!completer.isCompleted) onMessage(data, completer);
    });

    final isolate =
        await Isolate.spawn(entryPoint, {...args, "port": rxPort.sendPort});

    cancellationToken?.attachIsolate(isolate, () {
      if (!completer.isCompleted) {
        completer.completeError(BackupCancelledException());
      }
    });

    try {
      return await completer.future;
    } finally {
      cancellationToken?.detach();
      rxPort.close();
      isolate.kill(priority: Isolate.immediate);
    }
  }

  static Future<void> _prepareDecryptIsolate(Map<String, dynamic> args) async {
    SendPort sendPort = args["port"];
    try {
      final inputFile = args["inputFile"] as String;
      final totalSize = await File(inputFile).length();

      final Uint8List header, salt, baseNonce, chunkSizeBytes, totalLengthBytes;
      final input = File(inputFile).openSync(mode: FileMode.read);
      try {
        header = input.readSync(_magicLength);
        salt = input.readSync(_saltLength);
        baseNonce = input.readSync(_baseNonceLength);
        chunkSizeBytes = input.readSync(4);
        totalLengthBytes = input.readSync(8);
      } finally {
        input.closeSync();
      }

      if (totalSize < _headerLength ||
          !constantTimeEquals(header, _magic) ||
          salt.length != _saltLength ||
          baseNonce.length != _baseNonceLength ||
          chunkSizeBytes.length != 4 ||
          totalLengthBytes.length != 8) {
        sendPort.send(_decryptionFailedSentinel);
        return;
      }

      final chunkPlainSize =
          ByteData.sublistView(chunkSizeBytes).getUint32(0, Endian.big);
      final totalPlainLength =
          ByteData.sublistView(totalLengthBytes).getUint64(0, Endian.big);
      if (chunkPlainSize <= 0) {
        sendPort.send(_decryptionFailedSentinel);
        return;
      }

      final totalChunks = _totalChunksFor(totalPlainLength, chunkPlainSize);
      final expectedSize =
          _headerLength + totalPlainLength + totalChunks * _tagLength;
      if (expectedSize != totalSize) {
        sendPort.send(_decryptionFailedSentinel);
        return;
      }

      final key = deriveArgon2idKey(
          password: args["password"], salt: salt, keyLength: _keyLength);

      final output = File(args["outputFile"]).openSync(mode: FileMode.write);
      try {
        output.truncateSync(totalPlainLength);
      } finally {
        output.closeSync();
      }

      sendPort.send([key, baseNonce, chunkPlainSize, totalPlainLength]);
    } catch (error) {
      sendPort.send(error.toString());
    }
  }

  static Uint8List _chunkNonce(Uint8List baseNonce, int chunkIndex) {
    final nonce = Uint8List(_nonceLength);
    nonce.setRange(0, _baseNonceLength, baseNonce);
    final indexBytes = ByteData(_nonceLength - _baseNonceLength)
      ..setUint64(0, chunkIndex, Endian.big);
    nonce.setRange(
        _baseNonceLength, _nonceLength, indexBytes.buffer.asUint8List());
    return nonce;
  }

  static Uint8List _uint32BE(int value) =>
      (ByteData(4)..setUint32(0, value, Endian.big)).buffer.asUint8List();

  static Uint8List _uint64BE(int value) =>
      (ByteData(8)..setUint64(0, value, Endian.big)).buffer.asUint8List();
}
