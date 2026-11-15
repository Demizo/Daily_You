// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/auth_popup.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:material_ui/material_ui.dart';

abstract final class AppLock {
  static Future<bool> enable(BuildContext context) async {
    var passwordSet = false;
    await showAppDialog(
        context: context,
        builder: (context) => AuthPopup(
              mode: AuthPopupMode.setPassword,
              title: AppLocalizations.of(context)!.settingsSecuritySetPassword,
              description:
                  AppLocalizations.of(context)!.settingsSecurityPasswordWarning,
              showBiometrics: false,
              dismissable: true,
              onSuccess: (_) {
                passwordSet = true;
              },
            ));
    await ConfigProvider.instance.set(Settings.requirePassword, passwordSet);
    return passwordSet;
  }

  static Future<void> disable(BuildContext context) {
    return showAppDialog(
        context: context,
        builder: (context) => AuthPopup(
              mode: AuthPopupMode.unlock,
              title:
                  AppLocalizations.of(context)!.settingsSecurityEnterPassword,
              showBiometrics: false,
              dismissable: true,
              onSuccess: (_) {
                ConfigProvider.instance.set(Settings.requirePassword, false);
              },
            ));
  }

  static Future<void> changePassword(BuildContext context) {
    return showAppDialog(
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

  static Future<void> setBiometricUnlock(BuildContext context, bool value) {
    return showAppDialog(
        context: context,
        builder: (context) => AuthPopup(
              mode: AuthPopupMode.unlock,
              title:
                  AppLocalizations.of(context)!.settingsSecurityEnterPassword,
              showBiometrics: false,
              dismissable: true,
              onSuccess: (_) => applyBiometricUnlock(context, value),
            ));
  }

  static Future<void> applyBiometricUnlock(
      BuildContext context, bool value) async {
    var success = true;
    if (value) {
      try {
        success = await LocalAuthentication().authenticate(
            persistAcrossBackgrounding: false,
            biometricOnly: true,
            localizedReason: AppLocalizations.of(context)!.unlockAppPrompt);
      } on PlatformException {
        success = false;
      }
    }

    if (success) {
      await ConfigProvider.instance.set(Settings.biometricUnlock, value);
    }
  }
}
