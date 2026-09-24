import 'dart:async';
import 'dart:io';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/database/image_storage.dart';
import 'package:daily_you/notification_manager.dart';
import 'package:daily_you/storage/file_store.dart';
import 'package:daily_you/storage/local_file_store.dart';
import 'package:daily_you/storage/storage_picker.dart';
import 'package:daily_you/utils/backup_encryption.dart';
import 'package:daily_you/utils/cancellation_token.dart';
import 'package:daily_you/utils/operation_outcome.dart';
import 'package:daily_you/utils/password_store.dart';
import 'package:daily_you/utils/zip_utils.dart';
import 'package:daily_you/widgets/auth_popup.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RestoreCancelled implements Exception {}

enum AutoBackupOutcome { succeeded, cancelled, failed, skipped }

class BackupRestoreUtils {
  static final Logger _logger = Logger('BackupRestoreUtils');

  // Prevent periodic and catch-up backups from colliding
  static bool _autoBackupRunning = false;

  static const String manualBackupPrefix = 'daily_you_backup_';
  static const String autoBackupPrefix = 'daily_you_auto_backup_';

  static String? _backupPassword() =>
      BackupPasswordStore.isEnabled ? BackupPasswordStore.password : null;

  static String _backupName(String prefix) =>
      "$prefix${DateTime.now().toIso8601String().replaceAll(':', '-')}.zip";

  static Future<void> _writeBackup({
    required PickedDirectory destination,
    required String name,
    required void Function(double percent) onCompress,
    required void Function(double percent) onEncrypt,
    required void Function(double percent) onTransfer,
    required void Function() onCleanup,
    CancellationToken? cancellationToken,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final stagedArchive = File(join(tempDir.path, name));
    final encryptedArchive = File('${stagedArchive.path}.enc');
    // Unique to prevent overlap if multiple backups manage to run concurrently
    final snapshotDir = Directory(join(tempDir.path, '$name.snapshot'));
    final databaseSnapshot =
        File(join(snapshotDir.path, AppDatabase.databaseFileName));
    final password = _backupPassword();
    final outputName = password != null ? '$name.enc' : name;

    try {
      if (await snapshotDir.exists()) await snapshotDir.delete(recursive: true);
      await snapshotDir.create(recursive: true);
      if (!await AppDatabase.instance.exportSnapshotTo(databaseSnapshot.path)) {
        throw Exception('Failed to create a consistent database snapshot');
      }

      onCompress(0);
      await ZipUtils.compress(stagedArchive.path, [databaseSnapshot.path],
          [await ImageStorage.instance.getInternalFolder()],
          onProgress: onCompress, cancellationToken: cancellationToken);

      if (cancellationToken?.isCancelled ?? false) {
        throw BackupCancelledException();
      }
      if (await stagedArchive.length() == 0) {
        throw Exception('Created backup is empty');
      }

      var backupFile = stagedArchive;
      if (password != null) {
        onEncrypt(0);
        await BackupEncryption.encryptFile(
            stagedArchive.path, encryptedArchive.path, password,
            onProgress: onEncrypt, cancellationToken: cancellationToken);
        if (cancellationToken?.isCancelled ?? false) {
          throw BackupCancelledException();
        }
        backupFile = encryptedArchive;
      }

      onTransfer(0);
      final transferred = await destination.copyFileInto(
          backupFile.path, outputName,
          mimeType:
              password != null ? "application/octet-stream" : "application/zip",
          onProgress: onTransfer);
      if (!transferred) {
        throw Exception('Failed to transfer backup to $outputName');
      }
    } finally {
      onCleanup();
      if (await stagedArchive.exists()) {
        await stagedArchive.delete();
      }
      if (await encryptedArchive.exists()) {
        await encryptedArchive.delete();
      }
      if (await snapshotDir.exists()) {
        await snapshotDir.delete(recursive: true);
      }
    }
  }

  static Future<void> _recordBackup({bool automatic = false}) async {
    final now = DateTime.now().toIso8601String();
    await ConfigProvider.instance.set(Settings.lastBackup, now);
    if (automatic) {
      await ConfigProvider.instance.set(Settings.lastAutoBackup, now);
    }
  }

  /// Throws [BackupCancelledException] when cancelled
  static Future<bool> runAutoBackup(
      {void Function(double percent)? onCompress,
      void Function(double percent)? onEncrypt,
      void Function(double percent)? onTransfer,
      CancellationToken? cancellationToken}) async {
    final destinationUri =
        ConfigProvider.instance.get(Settings.autoBackupLocationUri);
    if (destinationUri.isEmpty) return false;
    final destination = PickedDirectory(destinationUri);
    if (!await destination.store.isAvailable()) {
      _logger.severe('Automatic backup skipped: no access to $destinationUri');
      return false;
    }
    if (!await File(await AppDatabase.instance.getInternalPath()).exists()) {
      _logger.info('Automatic backup skipped: no database yet');
      return false;
    }

    final databaseAlreadyOpen = AppDatabase.instance.database != null;
    if (!databaseAlreadyOpen &&
        !await AppDatabase.instance
            .init(forceWithoutSync: true, allowMigration: false)) {
      _logger.severe('Automatic backup skipped: could not open database');
      return false;
    }

    try {
      await _writeBackup(
        destination: destination,
        name: _backupName(autoBackupPrefix),
        onCompress: onCompress ?? (_) {},
        onEncrypt: onEncrypt ?? (_) {},
        onTransfer: onTransfer ?? (_) {},
        onCleanup: () {},
        cancellationToken: cancellationToken,
      );
    } on BackupCancelledException {
      rethrow;
    } catch (error, stackTrace) {
      _logger.severe('Automatic backup failed', error, stackTrace);
      return false;
    } finally {
      if (!databaseAlreadyOpen) await AppDatabase.instance.close();
    }

    await _recordBackup(automatic: true);

    try {
      await _pruneAutoBackups(destination.store,
          ConfigProvider.instance.get(Settings.autoBackupMaxCount));
    } catch (error, stackTrace) {
      _logger.severe('Pruning old backups failed', error, stackTrace);
    }
    return true;
  }

  static Future<AutoBackupOutcome> runAutoBackupAndNotify() async {
    if (_autoBackupRunning) return AutoBackupOutcome.skipped;
    _autoBackupRunning = true;
    try {
      return await _runAutoBackupAndNotify();
    } finally {
      _autoBackupRunning = false;
    }
  }

  static Future<AutoBackupOutcome> _runAutoBackupAndNotify() async {
    final prefs = await SharedPreferences.getInstance();
    final creatingTemplate = prefs.getString('creatingBackupStatusTemplate');
    final encryptingTemplate =
        prefs.getString('encryptingBackupStatusTemplate');
    final transferringTemplate = prefs.getString('tranferStatusTemplate');
    final failedTitle =
        prefs.getString('autoBackupFailedTitle') ?? 'Backup Failed';
    final cancelLabel = prefs.getString('backupCancelActionLabel');

    String stageTitle(String? template, int percent) =>
        template?.replaceFirst('{percent}', '$percent') ?? '';

    await NotificationManager.instance.clearBackupCancelRequest();
    final cancellationToken = CancellationToken();
    final cancelPoll =
        Timer.periodic(const Duration(milliseconds: 300), (_) async {
      if (cancellationToken.isCancelled) return;
      if (await NotificationManager.instance.isBackupCancelRequested()) {
        cancellationToken.cancel();
      }
    });

    try {
      await NotificationManager.instance.showBackupProgress(
          0, stageTitle(creatingTemplate, 0),
          cancelLabel: cancelLabel);
    } catch (error, stackTrace) {
      _logger.warning(
          'Could not show backup progress notification', error, stackTrace);
    }

    var success = false;
    var cancelled = false;
    try {
      String? shownTemplate = creatingTemplate;
      var shownPercent = 0;
      void showStage(String? template, double percent) {
        final rounded = percent.round();
        if (template == shownTemplate && rounded - shownPercent < 5) return;
        shownTemplate = template;
        shownPercent = rounded;
        NotificationManager.instance.showBackupProgress(
            rounded, stageTitle(template, rounded),
            cancelLabel: cancelLabel);
      }

      success = await runAutoBackup(
        cancellationToken: cancellationToken,
        onCompress: (percent) => showStage(creatingTemplate, percent),
        onEncrypt: (percent) => showStage(encryptingTemplate, percent),
        onTransfer: (percent) => showStage(transferringTemplate, percent),
      );
    } on BackupCancelledException {
      cancelled = true;
      _logger.info('Automatic backup cancelled by the user');
    } finally {
      cancelPoll.cancel();
      try {
        if (cancelled || success) {
          await NotificationManager.instance.stopBackupProgress();
        } else {
          await NotificationManager.instance.showBackupFailed(failedTitle);
        }
      } catch (error, stackTrace) {
        _logger.warning(
            'Could not update backup result notification', error, stackTrace);
      }
    }
    if (cancelled) return AutoBackupOutcome.cancelled;
    return success ? AutoBackupOutcome.succeeded : AutoBackupOutcome.failed;
  }

  static Future<void> _pruneAutoBackups(FileStore destination, int keep) async {
    if (keep <= 0) return;
    final backups = (await destination.list())
        .where((name) =>
            name.startsWith(autoBackupPrefix) &&
            (name.endsWith('.zip') || name.endsWith('.zip.enc')))
        .toList()
      ..sort();
    if (backups.length <= keep) return;

    for (final name in backups.take(backups.length - keep)) {
      await destination.delete(name);
    }
  }

  static Future<void> _extractBackup(File archive, Directory destination,
      void Function(double percent) onProgress) async {
    if (await destination.exists()) {
      await destination.delete(recursive: true);
    }
    await destination.create(recursive: true);
    await ZipUtils.extract(archive.path, destination.path,
        onProgress: onProgress);
  }

  static Future<void> _decryptBackup(BuildContext context, File encrypted,
      File destination, void Function(double percent) onProgress) async {
    try {
      final password =
          BackupPasswordStore.isEnabled ? BackupPasswordStore.password : null;
      if (password == null) throw BackupDecryptionFailedException();
      await BackupEncryption.decryptFile(
          encrypted.path, destination.path, password,
          onProgress: onProgress);
    } catch (_) {
      if (!context.mounted) rethrow;
      final password = await _promptForBackupPassword(context);
      if (password == null) throw _RestoreCancelled();
      await BackupEncryption.decryptFile(
          encrypted.path, destination.path, password,
          onProgress: onProgress);
    }
  }

  static Future<String?> _promptForBackupPassword(BuildContext context) async {
    String? password;
    await showDialog(
        context: context,
        builder: (context) => AuthPopup(
              mode: AuthPopupMode.enterPassword,
              title: AppLocalizations.of(context)!.backupEncryptedTitle,
              description: AppLocalizations.of(context)!.backupEncryptedContent,
              showBiometrics: false,
              dismissable: true,
              store: const BackupPasswordStore(),
              onSuccess: (entered) => password = entered,
            ));
    return password;
  }

  static Future<OperationOutcome> backupToZip(
      BuildContext context, void Function(String) updateStatus) async {
    final localizations = AppLocalizations.of(context)!;
    var outcome = const OperationOutcome.succeeded();

    try {
      final saveDirectory = await StoragePicker.pickDirectory();
      if (saveDirectory == null) return const OperationOutcome.cancelled();

      await _writeBackup(
        destination: saveDirectory,
        name: _backupName(manualBackupPrefix),
        onCompress: (percent) => updateStatus(
            localizations.creatingBackupStatus("${percent.round()}")),
        onEncrypt: (percent) => updateStatus(
            localizations.encryptingBackupStatus("${percent.round()}")),
        onTransfer: (percent) =>
            updateStatus(localizations.tranferStatus("${percent.round()}")),
        onCleanup: () => updateStatus(localizations.cleanUpStatus),
      );
      await _recordBackup();
    } catch (error) {
      outcome = OperationOutcome.failed(error);
    }

    return outcome;
  }

  static Future<OperationOutcome> restoreFromZip(
      BuildContext context, void Function(String) updateStatus) async {
    final localizations = AppLocalizations.of(context)!;
    var outcome = const OperationOutcome.succeeded();
    var tempDir = await getTemporaryDirectory();
    const tempImportName = "temp_backup_import";
    final tempImportFile = File(join(tempDir.path, tempImportName));
    final tempZipFile = File(join(tempDir.path, "temp_backup.zip"));
    final restoreFolder = Directory(join(tempDir.path, "Restore"));

    try {
      final archive = await StoragePicker.pickFile(
          allowedExtensions: ['zip', 'enc'],
          mimeTypes: ['application/zip', 'application/octet-stream']);

      if (archive == null) return const OperationOutcome.cancelled();

      // Import archive
      updateStatus(localizations.tranferStatus("0"));
      await archive.copyInto(tempDir.path, tempImportName,
          onProgress: (percent) {
        updateStatus(localizations.tranferStatus("${percent.round()}"));
      });

      if (await BackupEncryption.looksEncrypted(tempImportFile)) {
        if (!context.mounted) throw _RestoreCancelled();
        await _decryptBackup(context, tempImportFile, tempZipFile, (percent) {
          updateStatus(
              localizations.decryptingBackupStatus("${percent.round()}"));
        });
      } else {
        if (await tempZipFile.exists()) await tempZipFile.delete();
        await tempImportFile.copy(tempZipFile.path);
      }

      // Restore archive
      updateStatus(localizations.restoringBackupStatus("0"));

      void reportExtractProgress(double percent) {
        updateStatus(localizations.restoringBackupStatus("${percent.round()}"));
      }

      await _extractBackup(tempZipFile, restoreFolder, reportExtractProgress);

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
          ImageStorage.instance.invalidateCache();
        }
      } else {
        outcome = const OperationOutcome.failed();
      }
    } on _RestoreCancelled {
      outcome = const OperationOutcome.cancelled();
    } catch (error) {
      outcome = OperationOutcome.failed(error);
    }

    // Delete temp files
    updateStatus(localizations.cleanUpStatus);
    if (await tempImportFile.exists()) {
      await tempImportFile.delete();
    }
    if (await tempZipFile.exists()) {
      await tempZipFile.delete();
    }
    if (await restoreFolder.exists()) {
      await restoreFolder.delete(recursive: true);
    }

    return outcome;
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
