// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/device_info_service.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/utils/auto_backup_schedule.dart';
import 'package:daily_you/utils/password_store.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/auth_popup.dart';
import 'package:daily_you/widgets/auto_backup_options.dart';
import 'package:daily_you/widgets/settings_dialog.dart';
import 'package:daily_you/widgets/settings_rows.dart';
import 'package:material_ui/material_ui.dart';

abstract final class BackupRows {
  static Widget autoBackup(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final configProvider = ConfigProvider.instance;
    final enabled = configProvider.get(Settings.autoBackupEnabled);
    return SettingsToggleRow(
      icon: Icons.schedule_rounded,
      title: l10n.settingsAutoBackup,
      subtitle: enabled ? _nextAutoBackupText(context) : null,
      value: enabled,
      onChanged: (value) => _setAutoBackup(context, value),
      onOpenOptions: () => showSettingsDialog(
          context: context, builder: AutoBackupOptions.build),
    );
  }

  static Widget passwordProtect(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SettingsToggleRow(
      icon: Icons.lock_rounded,
      title: l10n.settingsBackupPasswordProtect,
      value: ConfigProvider.instance.get(Settings.backupPasswordEnabled),
      onChanged: (DeviceInfoService().supportsSecureStorage ?? false)
          ? (value) => _setBackupPassword(context, value)
          : null,
      onOpenOptions: () => _showBackupPasswordDialog(
          context, l10n.settingsSecurityChangePassword),
    );
  }

  static Future<void> _setAutoBackup(BuildContext context, bool enabled) async {
    final hadLocation =
        ConfigProvider.instance.get(Settings.autoBackupLocationUri) != '';
    final succeeded = await AutoBackupOptions.setEnabled(enabled);
    if (succeeded && enabled && !hadLocation && context.mounted) {
      await showSettingsDialog(
          context: context, builder: AutoBackupOptions.build);
    }
  }

  static String _nextAutoBackupText(BuildContext context) {
    final next = nextAutoBackupTimeFromConfig(ConfigProvider.instance);
    return AppLocalizations.of(context)!
        .settingsAutoBackupNext(TimeManager.formatDate(next, context));
  }

  static Future<void> _showBackupPasswordDialog(
      BuildContext context, String title) {
    return showAppDialog(
        context: context,
        builder: (context) => AuthPopup(
              mode: AuthPopupMode.setPassword,
              title: title,
              showBiometrics: false,
              dismissable: true,
              store: const BackupPasswordStore(),
            ));
  }

  static Future<void> _setBackupPassword(
      BuildContext context, bool enabled) async {
    final configProvider = ConfigProvider.instance;
    if (enabled) {
      await _showBackupPasswordDialog(
          context, AppLocalizations.of(context)!.settingsSecuritySetPassword);
      await configProvider.set(Settings.backupPasswordEnabled,
          BackupPasswordStore.password.isNotEmpty);
    } else {
      await configProvider.set(Settings.backupPassword, "");
      await configProvider.set(Settings.backupPasswordEnabled, false);
    }
  }
}
