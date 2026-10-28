// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/device_info_service.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/auth_popup.dart';
import 'package:daily_you/widgets/segmented_group.dart';
import 'package:daily_you/widgets/settings_page_scaffold.dart';
import 'package:daily_you/widgets/settings_rows.dart';
import 'package:material_ui/material_ui.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

class SecuritySettings extends StatelessWidget {
  const SecuritySettings({super.key});

  Future<void> _setRequirePassword(BuildContext context) async {
    final configProvider = ConfigProvider.instance;
    if (!configProvider.get(Settings.requirePassword)) {
      bool setPassword = false;
      await showAppDialog(
          context: context,
          builder: (context) => AuthPopup(
                mode: AuthPopupMode.setPassword,
                title:
                    AppLocalizations.of(context)!.settingsSecuritySetPassword,
                showBiometrics: false,
                dismissable: true,
                onSuccess: (_) {
                  setPassword = true;
                },
              ));
      await configProvider.set(Settings.requirePassword, setPassword);
    } else {
      await showAppDialog(
          context: context,
          builder: (context) => AuthPopup(
                mode: AuthPopupMode.unlock,
                title:
                    AppLocalizations.of(context)!.settingsSecurityEnterPassword,
                showBiometrics: false,
                dismissable: true,
                onSuccess: (_) {
                  configProvider.set(Settings.requirePassword, false);
                },
              ));
    }
  }

  Future<void> _changePassword(BuildContext context) async {
    await showAppDialog(
        context: context,
        builder: (context) => AuthPopup(
              mode: AuthPopupMode.changePassword,
              title:
                  AppLocalizations.of(context)!.settingsSecurityChangePassword,
              showBiometrics: false,
              dismissable: true,
              onSuccess: (_) {},
            ));
  }

  Future<void> _setBiometricUnlock(BuildContext context, bool value) async {
    await showAppDialog(
        context: context,
        builder: (context) => AuthPopup(
              mode: AuthPopupMode.unlock,
              title:
                  AppLocalizations.of(context)!.settingsSecurityEnterPassword,
              showBiometrics: false,
              dismissable: true,
              onSuccess: (_) async {
                bool success = true;
                if (value) {
                  try {
                    success = await LocalAuthentication().authenticate(
                        persistAcrossBackgrounding: false,
                        biometricOnly: true,
                        localizedReason:
                            AppLocalizations.of(context)!.unlockAppPrompt);
                  } on PlatformException {
                    success = false;
                  }
                }

                if (success) {
                  ConfigProvider.instance.set(Settings.biometricUnlock, value);
                }
              },
            ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final configProvider = Provider.of<ConfigProvider>(context);
    final requirePassword = configProvider.get(Settings.requirePassword);

    return SettingsPageScaffold(
      title: l10n.settingsSecurityTitle,
      children: [
        SegmentedGroup(children: [
          SettingsToggleRow(
            icon: Icons.lock_rounded,
            title: l10n.settingsSecurityRequirePassword,
            value: requirePassword,
            onChanged: (DeviceInfoService().supportsSecureStorage ?? false)
                ? (_) => _setRequirePassword(context)
                : null,
          ),
          SettingsActionRow(
            icon: Icons.password_rounded,
            title: l10n.settingsSecurityChangePassword,
            onTap: requirePassword ? () => _changePassword(context) : null,
          ),
          if (DeviceInfoService().supportsBiometrics ?? false)
            SettingsToggleRow(
              icon: Icons.fingerprint_rounded,
              title: l10n.settingsSecurityBiometricUnlock,
              value: requirePassword &&
                  configProvider.get(Settings.biometricUnlock),
              onChanged: requirePassword
                  ? (value) => _setBiometricUnlock(context, value)
                  : null,
            ),
        ]),
      ],
    );
  }
}
