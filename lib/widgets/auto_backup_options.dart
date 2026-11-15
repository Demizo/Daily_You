// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/main.dart';
import 'package:daily_you/notification_manager.dart';
import 'package:daily_you/storage/storage_picker.dart';
import 'package:daily_you/utils/auto_backup_schedule.dart';
import 'package:daily_you/widgets/settings_rows.dart';
import 'package:material_ui/material_ui.dart';

abstract final class AutoBackupOptions {
  static Future<bool> setEnabled(bool enabled) async {
    final configProvider = ConfigProvider.instance;
    if (enabled) {
      if (!await NotificationManager.instance.hasNotificationPermission()) {
        return false;
      }
      if (configProvider.get(Settings.autoBackupLocationUri) == '' &&
          !await pickLocation()) {
        return false;
      }
    }
    await configProvider.set(Settings.autoBackupEnabled, enabled);
    await armAutoBackupWork();
    return true;
  }

  static Future<bool> pickLocation() async {
    final directory = await StoragePicker.pickDirectory();
    if (directory == null) return false;
    await ConfigProvider.instance
        .set(Settings.autoBackupLocationUri, directory.uri);
    return true;
  }

  static List<Widget> build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final configProvider = ConfigProvider.instance;
    return [
      SettingsActionRow(
        title: l10n.settingsAutoBackupLocation,
        subtitle: StoragePicker.displayName(
            configProvider.get(Settings.autoBackupLocationUri)),
        onTap: pickLocation,
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
}
