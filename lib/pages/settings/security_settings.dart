import 'package:daily_you/config_provider.dart';
import 'package:daily_you/device_info_service.dart';
import 'package:daily_you/widgets/auth_popup.dart';
import 'package:daily_you/widgets/settings_icon_action.dart';
import 'package:daily_you/widgets/settings_toggle.dart';
import 'package:flutter/material.dart';
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
              settingsKey: ConfigKey.usePassword,
              onChanged: (value) async {
                if (!configProvider.get(ConfigKey.usePassword)) {
                  // Set a password
                  bool setPassword = false;
                  await showDialog(
                      context: context,
                      builder: (context) => AuthPopup(
                            mode: AuthPopupMode.setPassword,
                            title: AppLocalizations.of(context)!
                                .settingsSecuritySetPassword,
                            showBiometrics: false,
                            dismissable: true,
                            onSuccess: () {
                              setPassword = true;
                            },
                          ));
                  await configProvider.set(ConfigKey.usePassword, setPassword);
                } else {
                  // Disable password
                  await showDialog(
                      context: context,
                      builder: (context) => AuthPopup(
                            mode: AuthPopupMode.unlock,
                            title: AppLocalizations.of(context)!
                                .settingsSecurityEnterPassword,
                            showBiometrics: false,
                            dismissable: true,
                            onSuccess: () {
                              configProvider.set(ConfigKey.usePassword, false);
                            },
                          ));
                }
              }),
          if (configProvider.get(ConfigKey.usePassword))
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
                            onSuccess: () {},
                          ));
                }),
          if (configProvider.get(ConfigKey.usePassword) &&
              (DeviceInfoService().supportsBiometrics ?? false))
            SettingsToggle(
                title: AppLocalizations.of(context)!
                    .settingsSecurityBiometricUnlock,
                settingsKey: ConfigKey.biometricUnlock,
                onChanged: (value) async {
                  bool success = true;
                  try {
                    final bool didAuthenticate = await auth.authenticate(
                        options: AuthenticationOptions(
                            stickyAuth: false, biometricOnly: true),
                        localizedReason:
                            AppLocalizations.of(context)!.unlockAppPrompt);
                    success = didAuthenticate;
                  } on PlatformException {
                    success = false;
                  }

                  if (success) {
                    configProvider.set(ConfigKey.biometricUnlock, value);
                  }
                }),
        ],
      ),
    );
  }
}
