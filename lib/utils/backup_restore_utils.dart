import 'dart:io';

import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/database/image_storage.dart';
import 'package:daily_you/storage/file_store.dart';
import 'package:daily_you/storage/local_file_store.dart';
import 'package:daily_you/storage/storage_picker.dart';
import 'package:daily_you/utils/zip_utils.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class BackupRestoreUtils {
  static Future<bool> backupToZip(
      BuildContext context, void Function(String) updateStatus) async {
    final localizations = AppLocalizations.of(context)!;
    bool exportSuccessful = true;
    var tempDir = await getTemporaryDirectory();
    final exportedZipName =
        "daily_you_backup_${DateTime.now().toIso8601String().replaceAll(':', '-')}.zip";
    final tempExportZipFile = File(join(tempDir.path, exportedZipName));

    try {
      final saveDirectory = await StoragePicker.pickDirectory();
      if (saveDirectory == null) return false;

      // Create archive
      updateStatus(localizations.creatingBackupStatus("0"));
      await ZipUtils.compress(tempExportZipFile.path, [
        await AppDatabase.instance.getInternalPath()
      ], [
        await ImageStorage.instance.getInternalFolder()
      ], onProgress: (percent) {
        updateStatus(localizations.creatingBackupStatus("${percent.round()}"));
      });

      // Save archive
      updateStatus(localizations.tranferStatus("0"));
      await saveDirectory.copyFileInto(tempExportZipFile.path, exportedZipName,
          mimeType: "application/zip", onProgress: (percent) {
        updateStatus(localizations.tranferStatus("${percent.round()}"));
      });
    } catch (e) {
      updateStatus("$e");
      await Future.delayed(Duration(seconds: 5));
      exportSuccessful = false;
    }

    // Delete temp files
    updateStatus(localizations.cleanUpStatus);
    if (await tempExportZipFile.exists()) {
      await tempExportZipFile.delete();
    }

    return exportSuccessful;
  }

  static Future<bool> restoreFromZip(
      BuildContext context, void Function(String) updateStatus) async {
    final localizations = AppLocalizations.of(context)!;
    var importSuccessful = true;
    var tempDir = await getTemporaryDirectory();
    final tempZipName = "temp_backup.zip";
    final tempZipFile = File(join(tempDir.path, tempZipName));
    final restoreFolder = Directory(join(tempDir.path, "Restore"));

    try {
      final archive = await StoragePicker.pickFile(
          allowedExtensions: ['zip'], mimeTypes: ['application/zip']);

      if (archive == null) return false;

      // Import archive
      updateStatus(localizations.tranferStatus("0"));
      await archive.copyInto(tempDir.path, tempZipName, onProgress: (percent) {
        updateStatus(localizations.tranferStatus("${percent.round()}"));
      });

      // Restore archive
      updateStatus(localizations.restoringBackupStatus("0"));
      await restoreFolder.create(recursive: true);

      await ZipUtils.extract(tempZipFile.path, restoreFolder.path,
          onProgress: (percent) {
        updateStatus(localizations.restoringBackupStatus("${percent.round()}"));
      });

      final restoreStore = LocalFileStore(restoreFolder.path);
      final databaseBytes =
          await restoreStore.read(AppDatabase.databaseFileName);
      if (databaseBytes != null) {
        // Import database
        await AppDatabase.instance.close();
        await AppDatabase.instance.internalStore
            .write(AppDatabase.databaseFileName, databaseBytes);
        await AppDatabase.instance.open();
        await AppDatabase.instance.updateExternalDatabase();

        // Import images. These will be garbage collected after import
        final restoredImages =
            LocalFileStore(join(restoreFolder.path, "Images"));
        if (await restoredImages.isAvailable()) {
          // Also show cleanup status here since images may take awhile
          updateStatus(localizations.cleanUpStatus);
          await restoreImages(
              restoredImages, await ImageStorage.instance.internalStore());
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
    updateStatus(localizations.cleanUpStatus);
    if (await tempZipFile.exists()) {
      await tempZipFile.delete();
    }
    if (await restoreFolder.exists()) {
      await restoreFolder.delete(recursive: true);
    }

    return importSuccessful;
  }

  static Future<void> restoreImages(
      FileStore backup, FileStore destination) async {
    for (final imageName in await backup.list()) {
      final bytes = await backup.read(imageName);
      if (bytes != null) await destination.write(imageName, bytes);
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
