import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:daily_you/entries_database.dart';
import 'package:daily_you/file_layer.dart';
import 'package:daily_you/stats_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class BackupRestoreUtils {
  static Future<bool> backupToZip(
      BuildContext context, void Function(String) updateStatus) async {
    String? savePath = await FileLayer.pickDirectory();
    if (savePath == null) return false;

    var tempDir = await getTemporaryDirectory();

    final exportedZipName =
        "daily_you_backup_${DateTime.now().toIso8601String().replaceAll(':', '-')}.zip";

    // Create archive
    updateStatus(AppLocalizations.of(context)!.creatingBackupStatus("0"));
    var rxPort = ReceivePort();

    rxPort.listen((data) {
      var percent = data as double;
      updateStatus(AppLocalizations.of(context)!
          .creatingBackupStatus("${percent.round()}"));
    });

    await compute(
      encodeArchive,
      [
        join(tempDir.path, exportedZipName),
        await EntriesDatabase.instance.getInternalDbPath(),
        await EntriesDatabase.instance.getInternalImgDatabasePath(),
        rxPort.sendPort
      ],
    );

    rxPort.close();

    // Save archive
    updateStatus(AppLocalizations.of(context)!.tranferStatus("0"));

    final archiveSize = await FileLayer.getFileSize(tempDir.path,
        name: exportedZipName, useExternalPath: false);
    if (archiveSize == null || archiveSize == 0) return false;

    var readStream = await FileLayer.readFileStream(tempDir.path,
        name: exportedZipName, useExternalPath: false);
    if (readStream == null) return false;
    var writeStream =
        await FileLayer.openFileWriteStream(savePath, exportedZipName);
    if (writeStream == null) return false;

    var transferredSize = 0;

    await for (List<int> chunk in readStream) {
      await FileLayer.writeFileWriteStreamChunk(
          writeStream, Uint8List.fromList(chunk));
      transferredSize += chunk.length;
      var percent = (transferredSize / archiveSize) * 100;
      updateStatus(
          AppLocalizations.of(context)!.tranferStatus("${percent.round()}"));
    }
    await FileLayer.closeFileWriteStream(writeStream);

    // Delete temp files
    updateStatus(AppLocalizations.of(context)!.cleanUpStatus);
    await File(join(tempDir.path, exportedZipName)).delete();

    return true;
  }

  static Future<bool> restoreFromZip(
      BuildContext context, void Function(String) updateStatus) async {
    var importSuccessful = true;

    String? archive = await FileLayer.pickFile(
        allowedExtensions: ['zip'], mimeTypes: ['application/zip']);

    if (archive == null) return false;

    var tempDir = await getTemporaryDirectory();

    final tempZipName = "temp_backup.zip";

    // Import archive
    updateStatus(AppLocalizations.of(context)!.tranferStatus("0"));

    final archiveSize = await FileLayer.getFileSize(archive);
    if (archiveSize == null || archiveSize == 0) return false;

    var readStream =
        await FileLayer.readFileStream(archive, useExternalPath: true);
    if (readStream == null) return false;
    var writeStream = await FileLayer.openFileWriteStream(
        tempDir.path, tempZipName,
        useExternalPath: false);
    if (writeStream == null) return false;

    var transferredSize = 0;

    await for (List<int> chunk in readStream) {
      await FileLayer.writeFileWriteStreamChunk(
          writeStream, Uint8List.fromList(chunk));
      transferredSize += chunk.length;
      var percent = (transferredSize / archiveSize) * 100;
      updateStatus(
          AppLocalizations.of(context)!.tranferStatus("${percent.round()}"));
    }
    await FileLayer.closeFileWriteStream(writeStream);

    // Restore archive
    final restoreFolder = Directory(join(tempDir.path, "Restore"));
    if (await restoreFolder.exists() == false) {
      await restoreFolder.create();
    }

    updateStatus(AppLocalizations.of(context)!.restoringBackupStatus("0"));

    var rxPort = ReceivePort();

    rxPort.listen((data) {
      var percent = data as double;
      updateStatus(AppLocalizations.of(context)!
          .restoringBackupStatus("${percent.round()}"));
    });

    await compute(decodeArchive,
        [join(tempDir.path, tempZipName), restoreFolder.path, rxPort.sendPort]);

    rxPort.close();

    final tempDb = File(join(restoreFolder.path, 'daily_you.db'));
    if (await tempDb.exists()) {
      // Import database
      await EntriesDatabase.instance.close();
      await File(await EntriesDatabase.instance.getInternalDbPath())
          .writeAsBytes(await tempDb.readAsBytes());
      await EntriesDatabase.instance.initDB();

      // Import images. These will be garbage collected after import
      if (await Directory(join(restoreFolder.path, "Images")).exists()) {
        // Also show cleanup status here since images may take awhile
        updateStatus(AppLocalizations.of(context)!.cleanUpStatus);
        var files = Directory(join(restoreFolder.path, "Images")).list();
        final internalImagePath =
            await EntriesDatabase.instance.getInternalImgDatabasePath();
        await for (FileSystemEntity fileEntity in files) {
          if (fileEntity is File) {
            await File(join(internalImagePath, basename(fileEntity.path)))
                .writeAsBytes(await fileEntity.readAsBytes());
          }
        }
        if (EntriesDatabase.instance.usingExternalImg()) {
          await EntriesDatabase.instance.syncImageFolder(false);
        }
        await EntriesDatabase.instance.garbageCollectImages();
      }

      await StatsProvider.instance.updateStats();
    } else {
      importSuccessful = false;
    }

    // Delete temp files
    updateStatus(AppLocalizations.of(context)!.cleanUpStatus);
    await File(join(tempDir.path, tempZipName)).delete();
    if (await restoreFolder.exists()) {
      await restoreFolder.delete(recursive: true);
    }

    return importSuccessful;
  }

  static Future<void> encodeArchive(List<dynamic> args) async {
    SendPort sendPort = args[3];
    var encoder = ZipFileEncoder();
    encoder.createWithStream(OutputFileStream(args[0]));
    await encoder.addFile(File(args[1]));
    await encoder.addDirectory(Directory(args[2]), onProgress: (progress) {
      sendPort.send(progress * 100);
    });
    await encoder.close();
  }

  static Future<void> decodeArchive(List<dynamic> args) async {
    SendPort sendPort = args[2];
    var decoder = ZipDecoder().decodeStream(InputFileStream(args[0]));

    // Track number of files for progress indication
    var totalFileCount = decoder.numberOfFiles();
    var processedFileCount = 0;

    for (final entry in decoder) {
      if (entry.isFile) {
        final bytes = entry.readBytes();
        if (bytes == null) continue;
        final parent = Directory(File(join(args[1], entry.name)).parent.path);
        if (await parent.exists() == false) {
          await parent.create(recursive: true);
        }
        await File(join(args[1], entry.name)).writeAsBytes(bytes);

        // Updates status
        processedFileCount += 1;
        sendPort.send((processedFileCount / totalFileCount) * 100);
      } else {
        await Directory(join(args[1], entry.name)).create(recursive: true);
      }
    }
  }

  static void showLoadingStatus(
      BuildContext context, ValueNotifier<String> statusNotifier) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  ValueListenableBuilder<String>(
                    valueListenable: statusNotifier,
                    builder: (context, message, child) {
                      return Text(message, textAlign: TextAlign.center);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
