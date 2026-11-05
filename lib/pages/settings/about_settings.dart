// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/device_info_service.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/widgets/segmented_group.dart';
import 'package:daily_you/widgets/settings_page_scaffold.dart';
import 'package:daily_you/widgets/settings_rows.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutSettings extends StatelessWidget {
  const AboutSettings({super.key});

  Future<void> _open(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SettingsPageScaffold(
      title: l10n.settingsAboutTitle,
      children: [
        SegmentedGroup(children: [
          SettingsActionRow(
            icon: Icons.info_rounded,
            title: l10n.settingsVersion,
            subtitle: DeviceInfoService().appInfo?.version ?? "0.0.0",
            onTap: () =>
                _open(Uri.https("github.com", "/Demizo/Daily_You/releases")),
          ),
          SettingsActionRow(
            icon: Icons.bug_report_rounded,
            title: l10n.errorReport,
            subtitle: "github.com/Demizo/Daily_You/issues",
            onTap: () =>
                _open(Uri.https("github.com", "/Demizo/Daily_You/issues")),
          ),
        ]),
        SegmentedGroup(children: [
          SettingsActionRow(
            icon: Icons.code_rounded,
            title: l10n.settingsSourceCode,
            subtitle: "github.com/Demizo/Daily_You",
            onTap: () => _open(Uri.https("github.com", "/Demizo/Daily_You")),
          ),
          SettingsActionRow(
            icon: Icons.gavel_rounded,
            title: l10n.settingsLicense,
            subtitle: l10n.licenseGPLv3,
            onTap: () => _open(Uri(
                scheme: "https",
                host: "github.com",
                path: "/Demizo/Daily_You",
                fragment: "license")),
          ),
          SettingsActionRow(
            icon: Icons.description_rounded,
            title: l10n.settingsOpenSourceLicenses,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => LicensePage(
                      applicationName: l10n.appTitle,
                      applicationVersion: DeviceInfoService().appInfo?.version,
                    ))),
          ),
        ]),
        SegmentedGroup(emphasized: true, children: [
          SettingsActionRow(
            icon: Icons.volunteer_activism_rounded,
            title:
                '${l10n.settingsMadeWithLove} ${l10n.settingsConsiderSupporting}',
            onTap: () => _open(Uri(
                scheme: "https",
                host: "github.com",
                path: "/Demizo/Daily_You",
                queryParameters: {"tab": "readme-ov-file"},
                fragment: "support-the-app")),
          ),
        ]),
      ],
    );
  }
}
