// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/device_info_service.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/utils/app_lock.dart';
import 'package:daily_you/widgets/settings_rows.dart';
import 'package:material_ui/material_ui.dart';

abstract final class AppLockRows {
  static Widget requirePassword(BuildContext context) {
    final configProvider = ConfigProvider.instance;
    return SettingsToggleRow(
      icon: Icons.lock_rounded,
      title: AppLocalizations.of(context)!.settingsSecurityRequirePassword,
      value: configProvider.get(Settings.requirePassword),
      onChanged: (DeviceInfoService().supportsSecureStorage ?? false)
          ? (_) => configProvider.get(Settings.requirePassword)
              ? AppLock.disable(context)
              : AppLock.enable(context)
          : null,
      onOpenOptions: () => AppLock.changePassword(context),
    );
  }

  static List<Widget> biometricUnlock(BuildContext context) {
    if (!(DeviceInfoService().supportsBiometrics ?? false)) return const [];
    final configProvider = ConfigProvider.instance;
    final requirePassword = configProvider.get(Settings.requirePassword);
    return [
      SettingsToggleRow(
        icon: Icons.fingerprint_rounded,
        title: AppLocalizations.of(context)!.settingsSecurityBiometricUnlock,
        value: requirePassword && configProvider.get(Settings.biometricUnlock),
        onChanged: requirePassword
            ? (value) => AppLock.setBiometricUnlock(context, value)
            : null,
      ),
    ];
  }
}
