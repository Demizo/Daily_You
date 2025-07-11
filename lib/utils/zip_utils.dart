import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';

class ZipUtils {
  static Future<void> compress(
      String outputFile, List<String> inputFiles, List<String> inputFolders,
      {Function(double percent)? onProgress}) async {
    var rxPort = ReceivePort();

    rxPort.listen((data) {
      if (onProgress != null) {
        onProgress(data);
      }
    });

    await compute(
      encodeArchive,
      {
        "outputFile": outputFile,
        "inputFiles": inputFiles,
        "inputFolders": inputFolders,
        "port": rxPort.sendPort
      },
    );

    rxPort.close();
  }

  static Future<void> extract(String inputFile, String outputFolder,
      {Function(double percent)? onProgress}) async {
    var rxPort = ReceivePort();

    rxPort.listen((data) {
      if (onProgress != null) {
        onProgress(data);
      }
    });

    await compute(decodeArchive, {
      "inputFile": inputFile,
      "outputFolder": outputFolder,
      "port": rxPort.sendPort
    });

    rxPort.close();
  }

  static Future<void> encodeArchive(Map<String, dynamic> args) async {
    SendPort sendPort = args["port"];
    var encoder = ZipFileEncoder();
    encoder.createWithStream(OutputFileStream(args["outputFile"]));
    for (var file in args["inputFiles"]) {
      await encoder.addFile(File(file));
    }
    for (var folder in args["inputFolders"]) {
      // TODO This is not accurate and only works for a single folder
      await encoder.addDirectory(Directory(folder), onProgress: (progress) {
        sendPort.send(progress * 100);
      });
    }
    await encoder.close();
  }

  static Future<void> decodeArchive(Map<String, dynamic> args) async {
    SendPort sendPort = args["port"];
    var decoder = ZipDecoder().decodeStream(InputFileStream(args["inputFile"]));

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
