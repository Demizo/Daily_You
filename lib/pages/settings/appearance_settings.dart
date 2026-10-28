// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/theme_mode_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/color_picker_dialog.dart';
import 'package:daily_you/widgets/mood_scale_setting.dart';
import 'package:daily_you/widgets/segmented_group.dart';
import 'package:daily_you/widgets/settings_page_scaffold.dart';
import 'package:daily_you/widgets/settings_rows.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class AppearanceSettings extends StatelessWidget {
  const AppearanceSettings({super.key});

  Future<void> _showAccentColorPopup(
      BuildContext context, ThemeModeProvider themeProvider) async {
    final initialColor =
        Color(ConfigProvider.instance.get(Settings.accentColor));
    final result = await showAppDialog<ColorPickerResult>(
      context: context,
      builder: (context) => ColorPickerDialog(initialColor: initialColor),
    );
    if (result?.color != null) {
      themeProvider.accentColor = result!.color!;
      themeProvider.updateAccentColor();
    }
  }

  ThemeMode _themeModeFor(String theme) {
    switch (theme) {
      case "light":
        return ThemeMode.light;
      case "dark":
      case "amoled":
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = Provider.of<ThemeModeProvider>(context);
    final configProvider = Provider.of<ConfigProvider>(context);
    final dayLabels = TimeManager.daysOfWeekLabels(context);

    return SettingsPageScaffold(
      title: l10n.settingsAppearanceTitle,
      children: [
        SegmentedGroup(children: [
          const MoodScaleSetting(),
          SettingsChoiceRow<String>(
            icon: Icons.brightness_6_rounded,
            title: l10n.settingsTheme,
            value: configProvider.get(Settings.theme),
            options: {
              "system": l10n.themeSystem,
              "dark": l10n.themeDark,
              "light": l10n.themeLight,
              "amoled": l10n.themeAmoled,
            },
            onChanged: (theme) {
              themeProvider.themeMode = _themeModeFor(theme);
              configProvider.set(Settings.theme, theme);
            },
          ),
          SettingsToggleRow(
            icon: Icons.palette_rounded,
            title: l10n.settingsUseSystemAccentColor,
            value: configProvider.get(Settings.followSystemColor),
            onChanged: (value) {
              configProvider.set(Settings.followSystemColor, value);
              themeProvider.updateAccentColor();
            },
          ),
          if (!configProvider.get(Settings.followSystemColor))
            SettingsActionRow(
              icon: Icons.colorize_rounded,
              title: l10n.settingsCustomAccentColor,
              onTap: () => _showAccentColorPopup(context, themeProvider),
            ),
        ]),
        SegmentedGroup(children: [
          SettingsChoiceRow<String>(
            icon: Icons.calendar_view_week_rounded,
            title: l10n.settingsFirstDayOfWeek,
            value: configProvider.get(Settings.startingDayOfWeek),
            options: {
              "system": l10n.themeSystem,
              for (var index = 0; index < 7; index++)
                TimeManager.dayOfWeekIndexMapping[index]!: dayLabels[index],
            },
            onChanged: (day) =>
                configProvider.set(Settings.startingDayOfWeek, day),
          ),
          SettingsChoiceRow<String>(
            icon: Icons.calendar_month_rounded,
            title: l10n.settingsCalendarSystem,
            value: configProvider.get(Settings.calendarSystem),
            options: {
              "system": l10n.themeSystem,
              "gregorian": l10n.calendarSystemGregorian,
              "jalali": l10n.calendarSystemJalali,
            },
            onChanged: (system) =>
                configProvider.set(Settings.calendarSystem, system),
          ),
        ]),
        SegmentedGroup(children: [
          SettingsChoiceRow<String>(
            icon: Icons.grid_view_rounded,
            title: l10n.settingsGalleryViewLayout,
            value: configProvider.get(Settings.galleryPageViewMode),
            options: {
              "list": l10n.viewLayoutList,
              "grid": l10n.viewLayoutGrid,
            },
            onChanged: (layout) =>
                configProvider.set(Settings.galleryPageViewMode, layout),
          ),
          SettingsDialogRow(
            icon: Icons.hide_image_rounded,
            title: l10n.settingsHideImages,
            options: (context) => [
              SettingsToggleRow.setting(
                  title: l10n.flashbacksTitle,
                  setting: Settings.hideImagesInFlashbacks),
              SettingsToggleRow.setting(
                  title: l10n.pageCalendarTitle,
                  setting: Settings.hideImagesInCalendar),
              SettingsToggleRow.setting(
                  title: l10n.pageGalleryTitle,
                  setting: Settings.hideImagesInGallery),
            ],
          ),
        ]),
      ],
    );
  }
}
