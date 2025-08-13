import 'dart:io';
import 'package:daily_you/pages/settings/about_settings.dart';
import 'package:daily_you/pages/settings/appearance_settings.dart';
import 'package:daily_you/pages/settings/backup_restore_settings.dart';
import 'package:daily_you/pages/settings/flashback_settings.dart';
import 'package:daily_you/pages/settings/language_settings.dart';
import 'package:daily_you/pages/settings/notification_settings.dart';
import 'package:daily_you/pages/settings/security_settings.dart';
import 'package:daily_you/pages/settings/storage_settings.dart';
import 'package:daily_you/pages/settings/templates_page.dart';
import 'package:daily_you/stats_provider.dart';
import 'package:daily_you/widgets/settings_category.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final statsProvider = Provider.of<StatsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.pageSettingsTitle),
        centerTitle: true,
      ),
      persistentFooterButtons: [
        Center(
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                    text: AppLocalizations.of(context)!.settingsMadeWithLove,
                    style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.secondary)),
                if (statsProvider.entries.length > 30)
                  TextSpan(
                      text: " ",
                      style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.secondary)),
                if (statsProvider.entries.length > 30)
                  TextSpan(
                    text: AppLocalizations.of(context)!
                        .settingsConsiderSupporting,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        await launchUrl(
                            Uri(
                                scheme: "https",
                                host: "github.com",
                                path: "/Demizo/Daily_You",
                                queryParameters: {"tab": "readme-ov-file"},
                                fragment: "support-the-app"),
                            mode: LaunchMode.externalApplication);
                      },
                  ),
              ],
            ),
          ),
        )
      ],
      body: ListView(
        children: [
          SettingsCategory(
              title: AppLocalizations.of(context)!.settingsAppearanceTitle,
              icon: Icons.palette_rounded,
              page: AppearanceSettings()),
          SettingsCategory(
              title: AppLocalizations.of(context)!.settingsLanguageTitle,
              icon: Icons.language_rounded,
              page: LanguageSettings()),
          if (Platform.isAndroid)
            SettingsCategory(
                title: AppLocalizations.of(context)!.settingsNotificationsTitle,
                icon: Icons.notifications_rounded,
                page: NotificationSettings()),
          SettingsCategory(
              title: AppLocalizations.of(context)!.flashbacksTitle,
              icon: Icons.history_rounded,
              page: FlashbackSettings()),
          SettingsCategory(
              title: AppLocalizations.of(context)!.settingsTemplatesTitle,
              icon: Icons.description_rounded,
              page: TemplateSettings()),
          SettingsCategory(
              title: AppLocalizations.of(context)!.settingsStorageTitle,
              icon: Icons.storage_rounded,
              page: StorageSettings()),
          SettingsCategory(
              title: AppLocalizations.of(context)!.settingsSecurityTitle,
              icon: Icons.security_rounded,
              page: SecuritySettings()),
          SettingsCategory(
              title: AppLocalizations.of(context)!.settingsBackupRestoreTitle,
              icon: Icons.settings_backup_restore_rounded,
              page: BackupRestoreSettings()),
          SettingsCategory(
              title: AppLocalizations.of(context)!.settingsAboutTitle,
              icon: Icons.info_rounded,
              page: AboutSettings()),
        ],
      ),
    );
  }
}
