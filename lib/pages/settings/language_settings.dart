// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:daily_you/config_provider.dart';
import 'package:daily_you/device_info_service.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/language_option.dart';
import 'package:daily_you/widgets/segmented_group.dart';
import 'package:daily_you/widgets/settings_page_scaffold.dart';
import 'package:daily_you/widgets/settings_rows.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class LanguageSettings extends StatelessWidget {
  const LanguageSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final configProvider = Provider.of<ConfigProvider>(context);
    final hasSystemLanguagePicker = Platform.isAndroid &&
        DeviceInfoService().androidSdk != null &&
        DeviceInfoService().androidSdk! >= 33;

    return SettingsPageScaffold(
      title: l10n.settingsLanguageTitle,
      children: [
        SegmentedGroup(children: [
          if (hasSystemLanguagePicker)
            SettingsActionRow(
              icon: Icons.language_rounded,
              title: l10n.settingsAppLanguageTitle,
              onTap: () =>
                  AppSettings.openAppSettings(type: AppSettingsType.appLocale),
            ),
          SettingsChoiceRow<LanguageOption?>(
            icon: Icons.translate_rounded,
            title: hasSystemLanguagePicker
                ? l10n.settingsOverrideAppLanguageTitle
                : l10n.settingsAppLanguageTitle,
            value: LanguageOption.fromJsonOrNull(
                configProvider.get(Settings.overrideLanguage)),
            options: {
              null: l10n.themeSystem,
              for (final locale in AppLocalizations.supportedLocales)
                if (LanguageOption.displayNameMapping
                    .containsKey(LanguageOption.fromLocale(locale)))
                  LanguageOption.fromLocale(locale):
                      LanguageOption.fromLocale(locale).displayName(),
            },
            onChanged: (language) => configProvider.set(
                Settings.overrideLanguage, language?.toJson()),
          ),
        ]),
        SegmentedGroup(children: [
          SettingsActionRow(
            icon: Icons.volunteer_activism_rounded,
            title: l10n.settingsHelpTranslate,
            subtitle: l10n.settingsTranslateCallToAction,
            onTap: () => launchUrl(
                Uri.https("hosted.weblate.org", "/projects/daily-you"),
                mode: LaunchMode.externalApplication),
          ),
        ]),
      ],
    );
  }
}
