import 'package:app_settings/app_settings.dart';
import 'package:daily_you/widgets/settings_icon_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settingsLanguageTitle),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          SettingsIconAction(
              title: AppLocalizations.of(context)!.settingsLanguageTitle,
              icon: Icon(Icons.language_rounded),
              onPressed: () =>
                  AppSettings.openAppSettings(type: AppSettingsType.appLocale)),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(AppLocalizations.of(context)!.settingsTranslateCallToAction),
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
          )
        ],
      ),
    );
  }
}
