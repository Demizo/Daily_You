// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';
import 'package:daily_you/layouts/window_size_class.dart';
import 'package:daily_you/pages/settings/about_settings.dart';
import 'package:daily_you/pages/settings/appearance_settings.dart';
import 'package:daily_you/pages/settings/backup_restore_settings.dart';
import 'package:daily_you/pages/settings/flashback_settings.dart';
import 'package:daily_you/pages/settings/language_settings.dart';
import 'package:daily_you/pages/settings/notification_settings.dart';
import 'package:daily_you/pages/settings/security_settings.dart';
import 'package:daily_you/pages/settings/storage_settings.dart';
import 'package:daily_you/pages/settings/tags_settings.dart';
import 'package:daily_you/pages/settings/templates_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/widgets/segmented_group.dart';
import 'package:daily_you/widgets/settings_page_scaffold.dart';
import 'package:daily_you/widgets/settings_rows.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

typedef SettingsSection = ({String title, IconData icon, Widget page});

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _selected = 0;

  List<List<SettingsSection>> _sectionGroups(AppLocalizations l10n) => [
        [
          (
            title: l10n.settingsAppearanceTitle,
            icon: Icons.palette_rounded,
            page: const AppearanceSettings(),
          ),
          (
            title: l10n.settingsLanguageTitle,
            icon: Icons.language_rounded,
            page: const LanguageSettings(),
          ),
          if (Platform.isAndroid)
            (
              title: l10n.settingsNotificationsTitle,
              icon: Icons.notifications_rounded,
              page: const NotificationSettings(),
            ),
        ],
        [
          (
            title: l10n.settingsTagsTitle,
            icon: Icons.local_offer_rounded,
            page: const TagsSettings(),
          ),
          (
            title: l10n.settingsTemplatesTitle,
            icon: Icons.description_rounded,
            page: const TemplateSettings(),
          ),
          (
            title: l10n.flashbacksTitle,
            icon: Icons.history_rounded,
            page: const FlashbackSettings(),
          ),
        ],
        [
          (
            title: l10n.settingsBackupRestoreTitle,
            icon: Icons.settings_backup_restore_rounded,
            page: const BackupRestoreSettings(),
          ),
          (
            title: l10n.settingsStorageTitle,
            icon: Icons.storage_rounded,
            page: const StorageSettings(),
          ),
          (
            title: l10n.settingsSecurityTitle,
            icon: Icons.security_rounded,
            page: const SecuritySettings(),
          ),
        ],
        [
          (
            title: l10n.settingsAboutTitle,
            icon: Icons.info_rounded,
            page: const AboutSettings(),
          ),
        ],
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final groups = _sectionGroups(l10n);
    final sections = groups.expand((group) => group).toList();
    final hasSidebar = WindowSizeClass.of(context).hasPersistentSidebar;
    final selected = hasSidebar ? sections[_selected] : null;

    void open(SettingsSection section) {
      if (!hasSidebar) {
        Navigator.of(context).push(MaterialPageRoute(
          allowSnapshotting: false,
          builder: (context) => section.page,
        ));
        return;
      }
      setState(() => _selected = sections.indexOf(section));
    }

    final sectionList = Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.pageSettingsTitle),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
      ),
      body: SettingsListView(children: [
        for (final group in groups)
          SegmentedGroup(children: [
            for (final section in group)
              SettingsSectionRow(
                icon: section.icon,
                title: section.title,
                selected: section == selected,
                onTap: () => open(section),
              ),
          ]),
        _SupportFooter(),
      ]),
    );

    if (selected == null) return sectionList;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 304, child: sectionList),
        Expanded(child: SettingsPane(child: selected.page)),
      ],
    );
  }
}

class _SupportFooter extends StatefulWidget {
  @override
  State<_SupportFooter> createState() => _SupportFooterState();
}

class _SupportFooterState extends State<_SupportFooter> {
  late final TapGestureRecognizer _supportTapRecognizer;

  @override
  void initState() {
    super.initState();
    _supportTapRecognizer = TapGestureRecognizer()
      ..onTap = () async {
        await launchUrl(
            Uri(
                scheme: "https",
                host: "github.com",
                path: "/Demizo/Daily_You",
                queryParameters: {"tab": "readme-ov-file"},
                fragment: "support-the-app"),
            mode: LaunchMode.externalApplication);
      };
  }

  @override
  void dispose() {
    _supportTapRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entriesProvider = Provider.of<EntriesProvider>(context);
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: [
            TextSpan(
                text: AppLocalizations.of(context)!.settingsMadeWithLove,
                style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.secondary)),
            if (entriesProvider.entries.length > 30)
              TextSpan(
                  text: " ",
                  style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.secondary)),
            if (entriesProvider.entries.length > 30)
              TextSpan(
                text: AppLocalizations.of(context)!.settingsConsiderSupporting,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
                recognizer: _supportTapRecognizer,
              ),
          ],
        ),
      ),
    );
  }
}
