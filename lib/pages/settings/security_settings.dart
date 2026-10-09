import 'dart:io';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/device_info_service.dart';
import 'package:daily_you/utils/network_gate.dart';
import 'package:daily_you/utils/screen_protection.dart';
import 'package:daily_you/utils/security_question_helper.dart';
import 'package:daily_you/widgets/auth_popup.dart';
import 'package:daily_you/widgets/settings_icon_action.dart';
import 'package:daily_you/widgets/settings_toggle.dart';
import 'package:material_ui/material_ui.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

class SecuritySettings extends StatefulWidget {
  const SecuritySettings({super.key});

  @override
  State<SecuritySettings> createState() => SecuritySettingsPageState();
}

class SecuritySettingsPageState extends State<SecuritySettings> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<ConfigProvider>(context);
    final LocalAuthentication auth = LocalAuthentication();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settingsSecurityTitle),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          SettingsToggle(
              title:
                  AppLocalizations.of(context)!.settingsSecurityRequirePassword,
              setting: Settings.requirePassword,
              onChanged: (DeviceInfoService().supportsSecureStorage ?? false)
                  ? (value) async {
                      if (!configProvider.get(Settings.requirePassword)) {
                        bool setPassword = false;
                        await showDialog(
                            context: context,
                            builder: (context) => AuthPopup(
                                  mode: AuthPopupMode.setPassword,
                                  title: AppLocalizations.of(context)!
                                      .settingsSecuritySetPassword,
                                  showBiometrics: false,
                                  dismissable: true,
                                  onSuccess: (_) {
                                    setPassword = true;
                                  },
                                ));
                        await configProvider.set(
                            Settings.requirePassword, setPassword);
                      } else {
                        await showDialog(
                            context: context,
                            builder: (context) => AuthPopup(
                                  mode: AuthPopupMode.unlock,
                                  title: AppLocalizations.of(context)!
                                      .settingsSecurityEnterPassword,
                                  showBiometrics: false,
                                  dismissable: true,
                                  onSuccess: (_) {
                                    configProvider.set(
                                        Settings.requirePassword, false);
                                  },
                                ));
                      }
                    }
                  : null),
          if (configProvider.get(Settings.requirePassword))
            SettingsIconAction(
                title: AppLocalizations.of(context)!
                    .settingsSecurityChangePassword,
                icon: Icon(Icons.edit_rounded),
                onPressed: () async {
                  await showDialog(
                      context: context,
                      builder: (context) => AuthPopup(
                            mode: AuthPopupMode.changePassword,
                            title: AppLocalizations.of(context)!
                                .settingsSecurityChangePassword,
                            showBiometrics: false,
                            dismissable: true,
                            onSuccess: (_) {},
                          ));
                }),
          if (configProvider.get(Settings.requirePassword))
            SettingsIconAction(
                title: AppLocalizations.of(context)!.securityQuestionTitle,
                hint: SecurityQuestionHelper.hasSecurityQuestion
                    ? SecurityQuestionHelper.question
                    : AppLocalizations.of(context)!
                        .securityQuestionDescription,
                icon: const Icon(Icons.help_outline_rounded),
                onPressed: () => _promptSetupSecurityQuestion(context)),
          if (configProvider.get(Settings.requirePassword) &&
              (DeviceInfoService().supportsBiometrics ?? false))
            SettingsToggle(
                title: AppLocalizations.of(context)!
                    .settingsSecurityBiometricUnlock,
                setting: Settings.biometricUnlock,
                onChanged: (value) async {
                  await showDialog(
                      context: context,
                      builder: (context) => AuthPopup(
                            mode: AuthPopupMode.unlock,
                            title: AppLocalizations.of(context)!
                                .settingsSecurityEnterPassword,
                            showBiometrics: false,
                            dismissable: true,
                            onSuccess: (_) async {
                              bool success = true;
                              // Only require biometric authentication when enabling biometric unlock
                              if (value == true) {
                                try {
                                  final bool didAuthenticate =
                                      await auth.authenticate(
                                          persistAcrossBackgrounding: false,
                                          biometricOnly: true,
                                          localizedReason:
                                              AppLocalizations.of(context)!
                                                  .unlockAppPrompt);
                                  success = didAuthenticate;
                                } on PlatformException {
                                  success = false;
                                }
                              }

                              if (success) {
                                configProvider.set(
                                    Settings.biometricUnlock, value);
                              }
                            },
                          ));
                }),
          if (NetworkGate.isCompiledIn)
            SettingsToggle(
              title: AppLocalizations.of(context)!.settingsAllowNetworkTitle,
              hint:
                  AppLocalizations.of(context)!.settingsAllowNetworkDescription,
              setting: Settings.allowNetworkAccess,
              onChanged: (value) async {
                await configProvider.set(Settings.allowNetworkAccess, value);
              },
            ),
          if (Platform.isAndroid)
            SettingsToggle(
              title: AppLocalizations.of(context)!
                  .settingsScreenProtectionTitle,
              hint: AppLocalizations.of(context)!
                  .settingsScreenProtectionDescription,
              setting: Settings.screenProtection,
              onChanged: (value) async {
                await configProvider.set(Settings.screenProtection, value);
                await ScreenProtection.updateFromConfig();
              },
            ),
        ],
      ),
    );
  }

  Future<void> _promptSetupSecurityQuestion(BuildContext context) async {
    final qController =
        TextEditingController(text: SecurityQuestionHelper.question);
    final aController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.securityQuestionTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qController,
              decoration: InputDecoration(
                labelText: l10n.securityQuestionPrompt,
                hintText: 'e.g. What is your favorite book?',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: aController,
              decoration: InputDecoration(
                labelText: l10n.securityAnswerPrompt,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child:
                Text(MaterialLocalizations.of(dialogContext).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () async {
              if (qController.text.trim().isNotEmpty &&
                  aController.text.trim().isNotEmpty) {
                await SecurityQuestionHelper.setSecurityQuestion(
                  qController.text,
                  aController.text,
                );
                if (mounted) setState(() {});
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              }
            },
            child: Text(MaterialLocalizations.of(dialogContext).okButtonLabel),
          ),
        ],
      ),
    );
  }
}
