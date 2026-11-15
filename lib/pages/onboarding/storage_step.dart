// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/device_info_service.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/pages/onboarding/onboarding_illustrations.dart';
import 'package:daily_you/pages/onboarding/onboarding_step_layout.dart';
import 'package:daily_you/pages/onboarding/onboarding_tile.dart';
import 'package:daily_you/storage/external_sync_settings.dart';
import 'package:daily_you/utils/external_sync_flow.dart';
import 'package:daily_you/widgets/app_lock_rows.dart';
import 'package:daily_you/widgets/backup_rows.dart';
import 'package:daily_you/widgets/settings_dialog.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class StorageStep extends StatelessWidget {
  const StorageStep({super.key, required this.index});

  final int index;

  Future<void> _showPasswordOptions(BuildContext context) {
    return showSettingsDialog(
      context: context,
      title: AppLocalizations.of(context)!.settingsSecurityTitle,
      builder: (context) => [
        AppLockRows.requirePassword(context),
        ...AppLockRows.biometricUnlock(context),
      ],
    );
  }

  Future<void> _showBackupOptions(BuildContext context) {
    return showSettingsDialog(
      context: context,
      title: AppLocalizations.of(context)!.settingsBackup,
      builder: (context) => [
        BackupRows.autoBackup(context),
        BackupRows.passwordProtect(context),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final configProvider = context.watch<ConfigProvider>();
    final passwordEnabled = configProvider.get(Settings.requirePassword);
    final syncEnabled = ExternalSyncSettings.load().isOn;
    final backupsEnabled = configProvider.get(Settings.autoBackupEnabled);

    return OnboardingStepLayout(
      index: index,
      illustration: const OnboardingIllustration(
          icon: Icons.folder_rounded, badgeIcon: Icons.check_circle_rounded),
      title: l10n.onboardingStorageTitle,
      description: l10n.onboardingStorageNote,
      children: [
        if (DeviceInfoService().supportsSecureStorage ?? false)
          OnboardingTile.task(
            icon: Icons.lock_rounded,
            title: l10n.settingsSecuritySetPassword,
            done: passwordEnabled,
            onTap: () => _showPasswordOptions(context),
          ),
        OnboardingTile.task(
          icon: Icons.sync_rounded,
          title: l10n.settingsExternalSyncTitle,
          done: syncEnabled,
          onTap: () => syncEnabled
              ? ExternalSyncFlow.edit(context)
              : ExternalSyncFlow.toggle(context, true),
        ),
        if (Platform.isAndroid)
          OnboardingTile.task(
            icon: Icons.backup_rounded,
            title: l10n.settingsAutoBackup,
            done: backupsEnabled,
            onTap: () => _showBackupOptions(context),
          ),
      ],
    );
  }
}
