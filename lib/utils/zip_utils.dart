import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:daily_you/utils/cancellation_token.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';

class ZipUtils {
  static Future<void> compress(
      String outputFile, List<String> inputFiles, List<String> inputFolders,
      {Function(double percent)? onProgress,
      String? password,
      CancellationToken? cancellationToken}) async {
    if (cancellationToken?.isCancelled ?? false) {
      throw BackupCancelledException();
    }

    var rxPort = ReceivePort();
    var completer = Completer<void>();

    rxPort.listen((data) {
      if (data is String && data == _encodeArchiveDone) {
        if (!completer.isCompleted) completer.complete();
      } else if (data is String) {
        if (!completer.isCompleted) completer.completeError(Exception(data));
      } else {
        onProgress?.call(data);
      }
    });

    final isolate = await Isolate.spawn(encodeArchive, {
      "outputFile": outputFile,
      "inputFiles": inputFiles,
      "inputFolders": inputFolders,
      "port": rxPort.sendPort,
      "password": password,
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

  static Future<void> extract(String inputFile, String outputFolder,
      {Function(double percent)? onProgress, String? password}) async {
    var rxPort = ReceivePort();

    rxPort.listen((data) {
      if (onProgress != null) {
        onProgress(data);
      }
    });

    await compute(decodeArchive, {
      "inputFile": inputFile,
      "outputFolder": outputFolder,
      "port": rxPort.sendPort,
      "password": password,
    });

    rxPort.close();
  }

  static const _encodeArchiveDone = 'done';

  static Future<void> encodeArchive(Map<String, dynamic> args) async {
    SendPort sendPort = args["port"];
    try {
      var encoder = ZipFileEncoder(password: args["password"]);
      encoder.createWithStream(OutputFileStream(args["outputFile"]));
      for (var file in args["inputFiles"]) {
        await encoder.addFile(File(file));
      }
      for (var folder in args["inputFolders"]) {
        // TODO This is not accurate and only works for a single folder
        await encoder.addDirectory(Directory(folder), level: 0,
            onProgress: (progress) {
          sendPort.send(progress * 100);
        });
      }
      await encoder.close();
      sendPort.send(_encodeArchiveDone);
    } catch (error) {
      sendPort.send(error.toString());
    }
  }

  static Future<void> decodeArchive(Map<String, dynamic> args) async {
    SendPort sendPort = args["port"];
    var decoder = ZipDecoder().decodeStream(InputFileStream(args["inputFile"]),
        password: args["password"]);

    // Track number of files for progress indication
    var totalFileCount = decoder.numberOfFiles();
    var processedFileCount = 0;

    for (final entry in decoder) {
      if (entry.isFile) {
        final bytes = entry.readBytes();
        if (bytes == null) continue;
        // Fix for Zip encodings that place / at the start of files paths.
        // All Zip paths should be relative
        String fileName = entry.name;
        if (fileName.startsWith('/')) {
          fileName = fileName.substring(1);
        }
        final file = File(join(args["outputFolder"], fileName));
        await file.create(recursive: true);
        await file.writeAsBytes(bytes);

        // Updates status
        processedFileCount += 1;
        sendPort.send((processedFileCount / totalFileCount) * 100);
      } else {
        await Directory(join(args["outputFolder"], entry.name))
            .create(recursive: true);
      }
    }
  }
}
