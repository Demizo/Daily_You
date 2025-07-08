import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:daily_you/config_provider.dart';
import 'package:daily_you/device_info_service.dart';
import 'package:daily_you/language_option.dart';
import 'package:daily_you/widgets/settings_dropdown.dart';
import 'package:daily_you/widgets/settings_icon_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class LanguageSettings extends StatefulWidget {
  const LanguageSettings({super.key});

  @override
  State<LanguageSettings> createState() => _LanguageSettingsState();
}

class _LanguageSettingsState extends State<LanguageSettings> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ConfigProvider configProvider = Provider.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settingsLanguageTitle),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          if (Platform.isAndroid &&
              DeviceInfoService().androidSdk != null &&
              DeviceInfoService().androidSdk! >= 33)
            SettingsIconAction(
                title: AppLocalizations.of(context)!.settingsAppLanguageTitle,
                icon: Icon(Icons.language_rounded),
                onPressed: () => AppSettings.openAppSettings(
                    type: AppSettingsType.appLocale)),
          SettingsDropdown<LanguageOption?>(
              title: (Platform.isAndroid &&
                      DeviceInfoService().androidSdk != null &&
                      DeviceInfoService().androidSdk! >= 33)
                  ? AppLocalizations.of(context)!
                      .settingsOverrideAppLanguageTitle
                  : AppLocalizations.of(context)!.settingsAppLanguageTitle,
              value: LanguageOption.fromJsonOrNull(
                  configProvider.get(ConfigKey.overrideLanguage)),
              options: [
                DropdownMenuItem(
                    value: null,
                    child: Text(AppLocalizations.of(context)!.themeSystem)),
                for (var locale in AppLocalizations.supportedLocales
                    .where((locale) => locale.toLanguageTag() != "pt"))
                  DropdownMenuItem(
                      value: LanguageOption.fromLocale(locale),
                      child:
                          Text(LanguageOption.fromLocale(locale).displayName()))
              ],
              onChanged: (LanguageOption? newValue) {
                configProvider.set(
                    ConfigKey.overrideLanguage, newValue?.toJson());
              }),
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(AppLocalizations.of(context)!
                    .settingsTranslateCallToAction),
                ElevatedButton.icon(
                  icon: Icon(Icons.translate_rounded),
                  label:
                      Text(AppLocalizations.of(context)!.settingsHelpTranslate),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.surface,
                  ),
                  onPressed: () async {
                    await launchUrl(
                        Uri.https("hosted.weblate.org", "/projects/daily-you"),
                        mode: LaunchMode.externalApplication);
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
