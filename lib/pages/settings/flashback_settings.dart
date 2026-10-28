// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/widgets/segmented_group.dart';
import 'package:daily_you/widgets/settings_rows.dart';
import 'package:daily_you/widgets/settings_page_scaffold.dart';
import 'package:material_ui/material_ui.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class FlashbackSettings extends StatelessWidget {
  const FlashbackSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final configProvider = Provider.of<ConfigProvider>(context);
    final showFlashbacks = configProvider.get(Settings.showFlashbacks);

    Widget dependent(String title, Setting<bool> setting) => SettingsDependents(
          enabled: showFlashbacks,
          child: SettingsToggleRow.setting(title: title, setting: setting),
        );

    return SettingsPageScaffold(
      title: l10n.flashbacksTitle,
      children: [
        SegmentedGroup(children: [
          SettingsToggleRow.setting(
              title: l10n.settingsShowFlashbacks,
              setting: Settings.showFlashbacks),
          dependent(l10n.settingsFlashbacksExcludeBadDays,
              Settings.excludeBadDaysFromFlashbacks),
        ]),
        SegmentedGroup(children: [
          dependent(l10n.flashbackOnThisDay, Settings.showflashbackYearsAgo),
          dependent(l10n.flashbackMonth(6), Settings.showflashback6MonthsAgo),
          dependent(l10n.flashbackMonth(1), Settings.showflashback1MonthAgo),
          dependent(l10n.flashbackWeek(1), Settings.showflashback1WeekAgo),
          dependent(l10n.flashbackGoodDay, Settings.showflashbackGoodDay),
          dependent(l10n.flashbackRandomDay, Settings.showflashbackRandomDay),
        ]),
      ],
    );
  }
}
