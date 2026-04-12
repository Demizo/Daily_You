import 'dart:io';

import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/database/image_storage.dart';
import 'package:daily_you/utils/file_layer.dart';
import 'package:daily_you/utils/zip_utils.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class BackupRestoreUtils {
  static Future<bool> backupToZip(
      BuildContext context, void Function(String) updateStatus) async {
    bool exportSuccessful = true;
    var tempDir = await getTemporaryDirectory();
    final exportedZipName =
        "daily_you_backup_${DateTime.now().toIso8601String().replaceAll(':', '-')}.zip";
    final tempExportZipFile = File(join(tempDir.path, exportedZipName));

    try {
      final savePath = await FileLayer.pickDirectory();
      if (savePath == null) return false;

      // Create archive
      updateStatus(AppLocalizations.of(context)!.creatingBackupStatus("0"));
      await ZipUtils.compress(tempExportZipFile.path, [
        await AppDatabase.instance.getInternalPath()
      ], [
        await ImageStorage.instance.getInternalFolder()
      ], onProgress: (percent) {
        updateStatus(AppLocalizations.of(context)!
            .creatingBackupStatus("${percent.round()}"));
      });

      // Save archive
      updateStatus(AppLocalizations.of(context)!.tranferStatus("0"));
      await FileLayer.copyToExternalLocation(
          tempExportZipFile.path, savePath, exportedZipName,
          onProgress: (percent) {
        updateStatus(
            AppLocalizations.of(context)!.tranferStatus("${percent.round()}"));
      });
    } catch (e) {
      updateStatus("$e");
      await Future.delayed(Duration(seconds: 5));
      exportSuccessful = false;
    }

    // Delete temp files
    updateStatus(AppLocalizations.of(context)!.cleanUpStatus);
    if (await tempExportZipFile.exists()) {
      await tempExportZipFile.delete();
    }

    return exportSuccessful;
  }

  static Future<bool> restoreFromZip(
      BuildContext context, void Function(String) updateStatus) async {
    var importSuccessful = true;
    var tempDir = await getTemporaryDirectory();
    final tempZipName = "temp_backup.zip";
    final tempZipFile = File(join(tempDir.path, tempZipName));
    final restoreFolder = Directory(join(tempDir.path, "Restore"));

    try {
      String? archive = await FileLayer.pickFile(
          allowedExtensions: ['zip'], mimeTypes: ['application/zip']);

      if (archive == null) return false;

      // Import archive
      updateStatus(AppLocalizations.of(context)!.tranferStatus("0"));
      await FileLayer.copyFromExternalLocation(
          archive, tempDir.path, tempZipName, onProgress: (percent) {
        updateStatus(
            AppLocalizations.of(context)!.tranferStatus("${percent.round()}"));
      });

      // Restore archive
      updateStatus(AppLocalizations.of(context)!.restoringBackupStatus("0"));
      await restoreFolder.create(recursive: true);

      await ZipUtils.extract(tempZipFile.path, restoreFolder.path,
          onProgress: (percent) {
        updateStatus(AppLocalizations.of(context)!
            .restoringBackupStatus("${percent.round()}"));
      });

      final tempDb = File(join(restoreFolder.path, 'daily_you.db'));
      if (await tempDb.exists()) {
        // Import database
        await AppDatabase.instance.close();
        await File(await AppDatabase.instance.getInternalPath())
            .writeAsBytes(await tempDb.readAsBytes());
        await AppDatabase.instance.open();
        await AppDatabase.instance.updateExternalDatabase();

        // Import images. These will be garbage collected after import
        if (await Directory(join(restoreFolder.path, "Images")).exists()) {
          // Also show cleanup status here since images may take awhile
          updateStatus(AppLocalizations.of(context)!.cleanUpStatus);
          var files = Directory(join(restoreFolder.path, "Images")).list();
          final internalImagePath =
              await ImageStorage.instance.getInternalFolder();
          await for (FileSystemEntity fileEntity in files) {
            if (fileEntity is File) {
              await File(join(internalImagePath, basename(fileEntity.path)))
                  .writeAsBytes(await fileEntity.readAsBytes());
            }
          }
          if (ImageStorage.instance.usingExternalLocation()) {
            await ImageStorage.instance.syncImageFolder(true);
          }
        }
      } else {
        importSuccessful = false;
      }
    } catch (e) {
      updateStatus("$e");
      await Future.delayed(Duration(seconds: 5));
      importSuccessful = false;
    }

    // Delete temp files
    updateStatus(AppLocalizations.of(context)!.cleanUpStatus);
    if (await tempZipFile.exists()) {
      await tempZipFile.delete();
    }
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
