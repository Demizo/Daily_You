// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/color_picker_dialog.dart';
import 'package:daily_you/widgets/mood_scale_setting.dart';
import 'package:daily_you/widgets/settings_dropdown.dart';
import 'package:daily_you/widgets/settings_icon_action.dart';
import 'package:daily_you/widgets/settings_toggle.dart';
import 'package:material_ui/material_ui.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:daily_you/theme_mode_provider.dart';

class AppearanceSettings extends StatefulWidget {
  const AppearanceSettings({super.key});

  @override
  State<AppearanceSettings> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettings> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _showAccentColorPopup(ThemeModeProvider themeProvider) async {
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

  void _showHideImagesDialog(
      BuildContext context, ConfigProvider configProvider) {
    showAppDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.settingsHideImages),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _hideImagesToggleRow(
                    context,
                    AppLocalizations.of(context)!.flashbacksTitle,
                    configProvider.get(Settings.hideImagesInFlashbacks),
                    (value) {
                      configProvider.set(
                          Settings.hideImagesInFlashbacks, value);
                      setDialogState(() {});
                    },
                  ),
                  _hideImagesToggleRow(
                    context,
                    AppLocalizations.of(context)!.pageCalendarTitle,
                    configProvider.get(Settings.hideImagesInCalendar),
                    (value) {
                      configProvider.set(Settings.hideImagesInCalendar, value);
                      setDialogState(() {});
                    },
                  ),
                  _hideImagesToggleRow(
                    context,
                    AppLocalizations.of(context)!.pageGalleryTitle,
                    configProvider.get(Settings.hideImagesInGallery),
                    (value) {
                      configProvider.set(Settings.hideImagesInGallery, value);
                      setDialogState(() {});
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              child: Text(MaterialLocalizations.of(context).okButtonLabel),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  Widget _hideImagesToggleRow(BuildContext context, String label, bool value,
      ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }

  List<DropdownMenuItem<String>> _buildFirstDayOfWeekDropdownItems(
      BuildContext context) {
    final dayLabels = TimeManager.daysOfWeekLabels(context);
    List<DropdownMenuItem<String>> dropdownItems = List.empty(growable: true);
    dropdownItems.add(DropdownMenuItem<String>(
      value: "system",
      child: Text(AppLocalizations.of(context)!.themeSystem),
    ));

    var dropdownDays = List.generate(7, (index) {
      return DropdownMenuItem<String>(
        value: TimeManager.dayOfWeekIndexMapping[index],
        child: Text(
          dayLabels[index],
        ),
      );
    });
    dropdownItems.addAll(dropdownDays);
    return dropdownItems;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeModeProvider>(context);
    final configProvider = Provider.of<ConfigProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settingsAppearanceTitle),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const MoodScaleSetting(),
          SettingsDropdown<String>(
              title: AppLocalizations.of(context)!.settingsTheme,
              value: configProvider.get(Settings.theme),
              options: [
                DropdownMenuItem<String>(
                    value: "system",
                    child: Text(AppLocalizations.of(context)!.themeSystem)),
                DropdownMenuItem<String>(
                    value: "dark",
                    child: Text(AppLocalizations.of(context)!.themeDark)),
                DropdownMenuItem<String>(
                    value: "light",
                    child: Text(AppLocalizations.of(context)!.themeLight)),
                DropdownMenuItem<String>(
                    value: "amoled",
                    child: Text(AppLocalizations.of(context)!.themeAmoled)),
              ],
              onChanged: (String? newValue) {
                if (newValue == null) return;
                ThemeMode themeMode = ThemeMode.system;
                switch (newValue) {
                  case "system":
                    themeMode = ThemeMode.system;
                    break;
                  case "light":
                    themeMode = ThemeMode.light;
                    break;
                  case "dark":
                  case "amoled":
                    themeMode = ThemeMode.dark;
                    break;
                  default:
                    themeMode = ThemeMode.system;
                    break;
                }
                themeProvider.themeMode = themeMode;
                configProvider.set(Settings.theme, newValue);
              }),
          SettingsToggle(
              title: AppLocalizations.of(context)!.settingsUseSystemAccentColor,
              setting: Settings.followSystemColor,
              onChanged: (value) {
                configProvider.set(Settings.followSystemColor, value);
                themeProvider.updateAccentColor();
              }),
          if (!configProvider.get(Settings.followSystemColor))
            SettingsIconAction(
              title: AppLocalizations.of(context)!.settingsCustomAccentColor,
              icon: Icon(Icons.colorize_rounded),
              onPressed: () async {
                _showAccentColorPopup(themeProvider);
              },
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: SettingsDropdown<String>(
                title: AppLocalizations.of(context)!.settingsFirstDayOfWeek,
                value: configProvider.get(Settings.startingDayOfWeek),
                options: _buildFirstDayOfWeekDropdownItems(context),
                onChanged: (String? newValue) async {
                  if (newValue == null) return;
                  await configProvider.set(
                      Settings.startingDayOfWeek, newValue);
                }),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: SettingsDropdown<String>(
                title: AppLocalizations.of(context)!.settingsCalendarSystem,
                value: configProvider.get(Settings.calendarSystem),
                options: [
                  DropdownMenuItem<String>(
                      value: "system",
                      child: Text(AppLocalizations.of(context)!.themeSystem)),
                  DropdownMenuItem<String>(
                      value: "gregorian",
                      child: Text(AppLocalizations.of(context)!
                          .calendarSystemGregorian)),
                  DropdownMenuItem<String>(
                      value: "jalali",
                      child: Text(
                          AppLocalizations.of(context)!.calendarSystemJalali)),
                ],
                onChanged: (String? newValue) async {
                  if (newValue == null) return;
                  await configProvider.set(Settings.calendarSystem, newValue);
                }),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SettingsDropdown<String>(
                title: AppLocalizations.of(context)!.settingsGalleryViewLayout,
                value: configProvider.get(Settings.galleryPageViewMode),
                options: [
                  DropdownMenuItem<String>(
                      value: "list",
                      child:
                          Text(AppLocalizations.of(context)!.viewLayoutList)),
                  DropdownMenuItem<String>(
                      value: "grid",
                      child:
                          Text(AppLocalizations.of(context)!.viewLayoutGrid)),
                ],
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    configProvider.set(Settings.galleryPageViewMode, newValue);
                  }
                }),
          ),
          SettingsIconAction(
            title: AppLocalizations.of(context)!.settingsHideImages,
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () => _showHideImagesDialog(context, configProvider),
          ),
        ],
      ),
    );
  }
}
