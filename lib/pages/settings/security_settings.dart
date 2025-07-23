import 'package:daily_you/config_provider.dart';
import 'package:daily_you/widgets/settings_icon_action.dart';
import 'package:daily_you/widgets/settings_toggle.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settingsSecurityTitle),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          SettingsToggle(
              title: AppLocalizations.of(context)!.settingsSecurityUsePassword,
              settingsKey: ConfigKey.usePassword,
              onChanged: (value) {
                configProvider.set(ConfigKey.usePassword, value);
              }),
          if (configProvider.get(ConfigKey.usePassword))
            SettingsIconAction(
                title:
                    AppLocalizations.of(context)!.settingsSecuritySetPassword,
                icon: Icon(Icons.key_rounded),
                onPressed: () {}),
          SettingsToggle(
              title:
                  AppLocalizations.of(context)!.settingsSecurityBiometricUnlock,
              settingsKey: ConfigKey.biometricUnlock,
              onChanged: (value) {
                configProvider.set(ConfigKey.biometricUnlock, value);
              }),
        ],
      ),
    );
  }
}
