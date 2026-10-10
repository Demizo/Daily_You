import 'package:daily_you/config_provider.dart';
import 'package:daily_you/device_info_service.dart';
import 'package:daily_you/pages/settings/developer_settings_page.dart';
import 'package:daily_you/theme_mode_provider.dart';
import 'package:daily_you/widgets/settings_icon_action.dart';
import 'package:material_ui/material_ui.dart';
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
          GestureDetector(
            child: SettingsIconAction(
                title: AppLocalizations.of(context)!.settingsVersion,
                hint: DeviceInfoService().appInfo?.version ?? "0.0.0",
                icon: Icon(Icons.open_in_new_rounded),
                onPressed: () async {
                  await launchUrl(
                      Uri.https("github.com", "/TraxDinosaur/DailyYou/releases"),
                      mode: LaunchMode.externalApplication);
                }),
            onTap: () async {
              versionTapCount += 1;
              if (versionTapCount > 5) {
                versionTapCount = 0;

                await configProvider.set(Settings.followSystemColor, false);
                await configProvider.set(Settings.developerModeEnabled, true);

                themeProvider.accentColor = pinkAccentColor;
                themeProvider.updateAccentColor();

                if (!context.mounted) return;
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
          SettingsIconAction(
              title: AppLocalizations.of(context)!.settingsSourceCode,
              hint: "github.com/TraxDinosaur/DailyYou",
              icon: Icon(Icons.open_in_new_rounded),
              onPressed: () async {
                await launchUrl(Uri.https("github.com", "/TraxDinosaur/DailyYou"),
                    mode: LaunchMode.externalApplication);
              }),
          SettingsIconAction(
              title: AppLocalizations.of(context)!.settingsLicense,
              hint: AppLocalizations.of(context)!.licenseGPLv3,
              icon: Icon(Icons.open_in_new_rounded),
              onPressed: () async {
                await launchUrl(
                    Uri.https("github.com",
                        "/TraxDinosaur/DailyYou/blob/master/LICENSE.txt"),
                    mode: LaunchMode.externalApplication);
              }),
          SettingsIconAction(
              title: AppLocalizations.of(context)!.settingsOpenSourceLicenses,
              icon: Icon(Icons.chevron_right_rounded),
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => LicensePage(
                          applicationName:
                              AppLocalizations.of(context)!.appTitle,
                          applicationVersion:
                              DeviceInfoService().appInfo?.version,
                        )));
              }),
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            child: Divider(),
          ),
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
              title: AppLocalizations.of(context)!.errorReport,
              hint: "github.com/TraxDinosaur/DailyYou/issues",
              icon: Icon(Icons.open_in_new_rounded),
              onPressed: () async {
                await launchUrl(
                    Uri.https("github.com", "/TraxDinosaur/DailyYou/issues"),
                    mode: LaunchMode.externalApplication);
              }),
          if (configProvider.get(Settings.developerModeEnabled)) ...[
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0),
              child: Divider(),
            ),
            SettingsIconAction(
              title: AppLocalizations.of(context)!.developerOptionsTitle,
              hint: AppLocalizations.of(context)!.developerOptionsDescription,
              icon: Icon(Icons.code_rounded),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const DeveloperSettingsPage(),
                ));
              },
            ),
          ],
        ],
      ),
    );
  }
}
