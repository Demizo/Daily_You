import 'dart:io';

import 'package:daily_you/entries_database.dart';
import 'package:daily_you/file_layer.dart';
import 'package:daily_you/stats_provider.dart';
import 'package:daily_you/utils/zip_utils.dart';
import 'package:daily_you/widgets/images_provider.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class BackupRestoreUtils {
  static Future<bool> backupToZip(
      BuildContext context, void Function(String) updateStatus) async {
    String? savePath;
    try {
      savePath = await FileLayer.pickDirectory();
    } catch (e) {
      updateStatus("$e");
      await Future.delayed(Duration(seconds: 5));
      return false;
    }
    if (savePath == null) return false;

    var tempDir = await getTemporaryDirectory();

    final exportedZipName =
        "daily_you_backup_${DateTime.now().toIso8601String().replaceAll(':', '-')}.zip";

    // Create archive
    updateStatus(AppLocalizations.of(context)!.creatingBackupStatus("0"));
    await ZipUtils.compress(join(tempDir.path, exportedZipName), [
      await EntriesDatabase.instance.getInternalDbPath()
    ], [
      await EntriesDatabase.instance.getInternalImgDatabasePath()
    ], onProgress: (percent) {
      updateStatus(AppLocalizations.of(context)!
          .creatingBackupStatus("${percent.round()}"));
    });

    // Save archive
    updateStatus(AppLocalizations.of(context)!.tranferStatus("0"));
    await FileLayer.copyToExternalLocation(
        join(tempDir.path, exportedZipName), savePath, exportedZipName,
        onProgress: (percent) {
      updateStatus(
          AppLocalizations.of(context)!.tranferStatus("${percent.round()}"));
    });

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
    await FileLayer.copyFromExternalLocation(archive, tempDir.path, tempZipName,
        onProgress: (percent) {
      updateStatus(
          AppLocalizations.of(context)!.tranferStatus("${percent.round()}"));
    });

    // Restore archive
    updateStatus(AppLocalizations.of(context)!.restoringBackupStatus("0"));
    final restoreFolder = Directory(join(tempDir.path, "Restore"));
    await restoreFolder.create(recursive: true);

    await ZipUtils.extract(join(tempDir.path, tempZipName), restoreFolder.path,
        onProgress: (percent) {
      updateStatus(AppLocalizations.of(context)!
          .restoringBackupStatus("${percent.round()}"));
    });

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
      await ImagesProvider.instance.update();
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
