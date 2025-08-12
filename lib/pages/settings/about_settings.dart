import 'package:daily_you/config_provider.dart';
import 'package:daily_you/device_info_service.dart';
import 'package:daily_you/theme_mode_provider.dart';
import 'package:daily_you/widgets/settings_icon_action.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutSettings extends StatefulWidget {
  const AboutSettings({super.key});

  @override
  State<AboutSettings> createState() => _AboutSettingsState();
}

class _AboutSettingsState extends State<AboutSettings> {
  final Color pinkAccentColor = const Color(0xffff00d5);
  int versionTapCount = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<ConfigProvider>(context);
    final themeProvider = Provider.of<ThemeModeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settingsAboutTitle),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          SettingsIconAction(
              title: AppLocalizations.of(context)!.settingsSourceCode,
              hint: "github.com/Demizo/Daily_You",
              icon: Icon(Icons.open_in_new_rounded),
              onPressed: () async {
                await launchUrl(Uri.https("github.com", "/Demizo/Daily_You"),
                    mode: LaunchMode.externalApplication);
              }),
          SettingsIconAction(
            title: AppLocalizations.of(context)!.settingsHelpTranslate,
            hint: "hosted.weblate.org/projects/daily-you",
            icon: Icon(Icons.open_in_new_rounded),
            onPressed: () async {
              await launchUrl(
                  Uri.https("hosted.weblate.org", "/projects/daily-you"),
                  mode: LaunchMode.externalApplication);
            },
          ),
          SettingsIconAction(
              title: AppLocalizations.of(context)!.settingsLicense,
              hint: AppLocalizations.of(context)!.licenseGPLv3,
              icon: Icon(Icons.open_in_new_rounded),
              onPressed: () async {
                await launchUrl(
                    Uri.https("github.com",
                        "/Demizo/Daily_You/blob/master/LICENSE.txt"),
                    mode: LaunchMode.externalApplication);
              }),
          GestureDetector(
            child: SettingsIconAction(
                title: AppLocalizations.of(context)!.settingsVersion,
                hint: DeviceInfoService().appInfo?.version ?? "0.0.0",
                icon: Icon(Icons.open_in_new_rounded),
                onPressed: () async {
                  await launchUrl(
                      Uri.https("github.com", "/Demizo/Daily_You/releases"),
                      mode: LaunchMode.externalApplication);
                }),
            onTap: () async {
              versionTapCount += 1;
              if (versionTapCount > 5) {
                versionTapCount = 0;

                await configProvider.set(ConfigKey.followSystemColor, false);

                themeProvider.accentColor = pinkAccentColor;
                themeProvider.updateAccentColor();

                await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Center(
                          child: Text(AppLocalizations.of(context)!
                              .settingsMadeWithLove)),
                    );
                  },
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
