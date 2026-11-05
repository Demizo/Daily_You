// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/device_info_service.dart';
import 'package:daily_you/main.dart';
import 'package:daily_you/notification_manager.dart';
import 'package:daily_you/storage/storage_picker.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/utils/auto_backup_schedule.dart';
import 'package:daily_you/utils/backup_restore_utils.dart';
import 'package:daily_you/utils/imports/import_registry.dart';
import 'package:daily_you/utils/exports/export_registry.dart';
import 'package:daily_you/utils/exports/export_runner.dart';
import 'package:daily_you/utils/operation_outcome.dart';
import 'package:daily_you/utils/password_store.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/auth_popup.dart';
import 'package:daily_you/widgets/failure_dialog.dart';
import 'package:daily_you/widgets/segmented_group.dart';
import 'package:daily_you/widgets/settings_dialog.dart';
import 'package:daily_you/widgets/settings_rows.dart';
import 'package:daily_you/widgets/settings_page_scaffold.dart';
import 'package:material_ui/material_ui.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class BackupRestoreSettings extends StatefulWidget {
  const BackupRestoreSettings({super.key});

  @override
  State<BackupRestoreSettings> createState() => _BackupRestoreSettingsState();
}

class _BackupRestoreSettingsState extends State<BackupRestoreSettings> {
  Future<void> _showImportSelectionPopup() async {
    final l10n = AppLocalizations.of(context)!;
    final format = await showSettingsDialog<ImportFormat>(
      context: context,
      title: l10n.logFormatTitle,
      isSelection: true,
      builder: (context) => [
        SettingsInfoRow(
            title: l10n.warningTitle,
            subtitle: Text(l10n.logFormatDescription)),
        for (final option in ImportRegistry.instance.options)
          SettingsActionRow(
            title: option.name(l10n),
            onTap: () => Navigator.of(context).pop(option.format),
          ),
      ],
    );

    if (format == null) return;
    if (!mounted) return;

    final outcome = await BackupRestoreUtils.runWithLoadingStatus(
        context,
        (updateStatus) => ImportRegistry.instance
            .optionFor(format)
            .run(context, updateStatus));

    if (!mounted) return;

    if (outcome.failed) {
      await showFailureDialog(context,
          description: AppLocalizations.of(context)!.importErrorDescription,
          error: outcome.error);
    }
  }

  Future<void> _showExportSelectionPopup() async {
    final l10n = AppLocalizations.of(context)!;
    final option = await showSettingsDialog<ExportFormatOption>(
      context: context,
      title: l10n.logFormatTitle,
      isSelection: true,
      builder: (context) => [
        SettingsInfoRow(
            title: l10n.warningTitle,
            subtitle: Text(l10n.settingsExportFormatDescription)),
        for (final option in ExportRegistry.instance.options)
          SettingsActionRow(
            title: option.name(l10n),
            onTap: () => Navigator.of(context).pop(option),
          ),
      ],
    );

    if (option == null) return;
    if (!mounted) return;

    final outcome = await BackupRestoreUtils.runWithLoadingStatus(context,
        (updateStatus) => runExport(context, updateStatus, option: option));

    if (!mounted) return;

    if (outcome.failed) {
      await showFailureDialog(context,
          description: AppLocalizations.of(context)!.exportErrorDescription,
          error: outcome.error);
    }
  }

  Future<void> _backupData(BuildContext context) async {
    final outcome = await BackupRestoreUtils.runWithLoadingStatus(
        context,
        (updateStatus) =>
            BackupRestoreUtils.backupToZip(context, updateStatus));

    if (!context.mounted) return;

    if (outcome.failed) {
      await showFailureDialog(context,
          description: AppLocalizations.of(context)!.backupErrorDescription,
          error: outcome.error);
    }
  }

  Future<void> _restoreData(BuildContext context) async {
    final loadingStatus = LoadingStatusDialog(context);

    final OperationOutcome outcome;
    try {
      outcome = await BackupRestoreUtils.restoreFromZip(
          context, loadingStatus.update, onFilePicked: loadingStatus.show,
          confirm: (fileName, entryCount) async {
        if (!context.mounted) return false;
        final confirmed = await loadingStatus
            .whileHidden(() => _confirmRestore(fileName, entryCount));
        return confirmed && context.mounted;
      });
    } finally {
      loadingStatus.dispose();
    }

    if (!context.mounted) return;

    if (outcome.failed) {
      await showFailureDialog(context,
          description: AppLocalizations.of(context)!.restoreErrorDescription,
          error: outcome.error);
    }
  }

  Future<bool> _confirmRestore(String fileName, int entryCount) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showSettingsDialog<bool>(
      context: context,
      builder: (context) => [
        SettingsInfoRow(
          title: fileName,
          subtitle: Text(l10n.logCount(entryCount)),
        ),
        SettingsInfoRow(
          title: l10n.warningTitle,
          subtitle: Text(l10n.settingsRestorePromptDescription),
        ),
      ],
      actions: (context) => [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.settingsRestore),
        ),
      ],
    );
    return confirmed ?? false;
  }

  String _lastBackupText(String lastBackup) {
    final time = DateTime.tryParse(lastBackup);
    if (time == null) {
      return AppLocalizations.of(context)!.settingsBackupNever;
    }
    return AppLocalizations.of(context)!
        .settingsBackupLast(_dateTimeText(time));
  }

  String _nextAutoBackupText(ConfigProvider configProvider) {
    // Date only since idle/charging-gated scheduling has no guaranteed time
    final next = nextAutoBackupTimeFromConfig(configProvider);
    return AppLocalizations.of(context)!
        .settingsAutoBackupNext(TimeManager.formatDate(next, context));
  }

  String _dateTimeText(DateTime time) =>
      "${TimeManager.formatDate(time, context)} "
      "${TimeManager.timeOfDayString(context, TimeOfDay.fromDateTime(time))}";

  Future<void> _showBackupPasswordDialog(String title) async {
    await showAppDialog(
        context: context,
        builder: (context) => AuthPopup(
              mode: AuthPopupMode.setPassword,
              title: title,
              showBiometrics: false,
              dismissable: true,
              store: const BackupPasswordStore(),
            ));
  }

  Future<void> _setAutoBackup(bool enabled) async {
    final configProvider = ConfigProvider.instance;
    if (enabled) {
      if (!await NotificationManager.instance.hasNotificationPermission()) {
        return;
      }
      if (configProvider.get(Settings.autoBackupLocationUri) == '' &&
          !await _pickAutoBackupLocation()) {
        return;
      }
    }
    await configProvider.set(Settings.autoBackupEnabled, enabled);
    await armAutoBackupWork();
  }

  Future<bool> _pickAutoBackupLocation() async {
    final directory = await StoragePicker.pickDirectory();
    if (directory == null) return false;
    await ConfigProvider.instance
        .set(Settings.autoBackupLocationUri, directory.uri);
    return true;
  }

  List<Widget> _autoBackupOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final configProvider = ConfigProvider.instance;
    return [
      SettingsActionRow(
        title: l10n.settingsAutoBackupLocation,
        subtitle: StoragePicker.displayName(
            configProvider.get(Settings.autoBackupLocationUri)),
        onTap: _pickAutoBackupLocation,
      ),
      SettingsChoiceRow<String>(
        title: l10n.settingsAutoBackupInterval,
        value: configProvider.get(Settings.autoBackupInterval),
        options: {
          for (final interval in AutoBackupInterval.values)
            interval.key: interval.label(context),
        },
        onChanged: (value) async {
          await configProvider.set(Settings.autoBackupInterval, value);
          await armAutoBackupWork();
        },
      ),
      SettingsChoiceRow<int>(
        title: l10n.settingsAutoBackupMaxCount,
        value: configProvider.get(Settings.autoBackupMaxCount),
        options: {
          for (final count in const [1, 3, 5, 10]) count: '$count',
          0: l10n.settingsAutoBackupKeepAll,
        },
        onChanged: (value) =>
            configProvider.set(Settings.autoBackupMaxCount, value),
      ),
      SettingsToggleRow(
        title: l10n.settingsAutoBackupRequireCharging,
        value: configProvider.get(Settings.autoBackupRequireCharging),
        onChanged: (value) async {
          await configProvider.set(Settings.autoBackupRequireCharging, value);
          await armAutoBackupWork();
        },
      ),
    ];
  }

  Future<void> _setBackupPassword(bool enabled) async {
    final configProvider = ConfigProvider.instance;
    if (enabled) {
      await _showBackupPasswordDialog(
          AppLocalizations.of(context)!.settingsSecuritySetPassword);
      await configProvider.set(Settings.backupPasswordEnabled,
          BackupPasswordStore.password.isNotEmpty);
    } else {
      await configProvider.set(Settings.backupPassword, "");
      await configProvider.set(Settings.backupPasswordEnabled, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final configProvider = Provider.of<ConfigProvider>(context);

    return SettingsPageScaffold(
      title: l10n.settingsBackupRestoreTitle,
      children: [
        SegmentedGroup(children: [
          SettingsActionRow(
            icon: Icons.backup_rounded,
            title: l10n.settingsBackup,
            subtitle: _lastBackupText(configProvider.get(Settings.lastBackup)),
            onTap: () => _backupData(context),
          ),
          if (Platform.isAndroid)
            SettingsToggleRow(
              icon: Icons.schedule_rounded,
              title: l10n.settingsAutoBackup,
              subtitle: configProvider.get(Settings.autoBackupEnabled)
                  ? _nextAutoBackupText(configProvider)
                  : null,
              value: configProvider.get(Settings.autoBackupEnabled),
              onChanged: _setAutoBackup,
              onOpenOptions: () => showSettingsDialog(
                  context: context, builder: _autoBackupOptions),
            ),
          SettingsToggleRow(
            icon: Icons.lock_rounded,
            title: l10n.settingsBackupPasswordProtect,
            value: configProvider.get(Settings.backupPasswordEnabled),
            onChanged: (DeviceInfoService().supportsSecureStorage ?? false)
                ? _setBackupPassword
                : null,
            onOpenOptions: () =>
                _showBackupPasswordDialog(l10n.settingsSecurityChangePassword),
          ),
          SettingsActionRow(
            icon: Icons.restore_rounded,
            title: l10n.settingsRestore,
            onTap: () => _restoreData(context),
          ),
        ]),
        SegmentedGroup(children: [
          SettingsActionRow(
            icon: Icons.download_rounded,
            title: l10n.settingsImportFromAnotherApp,
            onTap: _showImportSelectionPopup,
          ),
          SettingsActionRow(
            icon: Icons.upload_rounded,
            title: l10n.settingsExportToAnotherFormat,
            onTap: _showExportSelectionPopup,
          ),
        ]),
      ],
    );
  }
}
