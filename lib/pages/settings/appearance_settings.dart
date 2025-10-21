import 'package:daily_you/config_provider.dart';
import 'package:daily_you/stats_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:daily_you/widgets/settings_dropdown.dart';
import 'package:daily_you/widgets/settings_icon_action.dart';
import 'package:daily_you/widgets/settings_toggle.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
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

  void _showAccentColorPopup(ThemeModeProvider themeProvider) {
    Color accentColor =
        Color(ConfigProvider.instance.get(ConfigKey.accentColor));
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          actions: [
            TextButton(
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
              onPressed: () async {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text(MaterialLocalizations.of(context).okButtonLabel),
              onPressed: () async {
                themeProvider.accentColor = accentColor;
                themeProvider.updateAccentColor();
                Navigator.pop(context);
              },
            ),
          ],
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ColorPicker(
                  enableAlpha: false,
                  labelTypes: const [ColorLabelType.rgb, ColorLabelType.hex],
                  paletteType: PaletteType.hueWheel,
                  pickerColor:
                      Color(ConfigProvider.instance.get(ConfigKey.accentColor)),
                  onColorChanged: (color) {
                    accentColor = color;
                  }),
            ],
          ),
        );
      },
    );
  }

  void _showMoodEmojiPopup(int? value) {
    String newEmoji = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(
            child: MoodIcon(
              moodValue: value,
              size: 32,
            ),
          ),
          actions: [
            TextButton(
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
              onPressed: () async {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text(MaterialLocalizations.of(context).okButtonLabel),
              onPressed: () async {
                if (newEmoji.isNotEmpty) {
                  if (value != null) {
                    await ConfigProvider.instance.set(
                        ConfigProvider.moodValueFieldMapping[value]!, newEmoji);
                  } else {
                    await ConfigProvider.instance
                        .set(ConfigKey.noMoodIcon, newEmoji);
                  }
                }
                Navigator.pop(context);
              },
            ),
          ],
          content: TextField(
            inputFormatters: [
              LengthLimitingTextInputFormatter(1), // Limit to one character
            ],
            onChanged: (value) {
              newEmoji = value;
            },
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.moodIconPrompt,
            ),
          ),
        );
      },
    );
  }

  _resetMoodIcons() async {
    for (var mood in ConfigProvider.defaultMoodIconFieldMapping.entries) {
      await ConfigProvider.instance.set(mood.key, mood.value);
    }
  }

  Widget moodIconButton(int? index) {
    return GestureDetector(
      child: Card(
          child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Container(
            constraints: const BoxConstraints(minWidth: 30),
            child: Center(child: MoodIcon(moodValue: index, size: 24))),
      )),
      onTap: () => _showMoodEmojiPopup(index),
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
    final statsProvider = Provider.of<StatsProvider>(context);
    final themeProvider = Provider.of<ThemeModeProvider>(context);
    final configProvider = Provider.of<ConfigProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settingsAppearanceTitle),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          SettingsDropdown<String>(
              title: AppLocalizations.of(context)!.settingsTheme,
              value: configProvider.get(ConfigKey.theme),
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
                configProvider.set(ConfigKey.theme, newValue);
              }),
          SettingsToggle(
              title: AppLocalizations.of(context)!.settingsUseSystemAccentColor,
              settingsKey: ConfigKey.followSystemColor,
              onChanged: (value) {
                configProvider.set(ConfigKey.followSystemColor, value);
                themeProvider.updateAccentColor();
              }),
          if (!configProvider.get(ConfigKey.followSystemColor))
            SettingsIconAction(
              title: AppLocalizations.of(context)!.settingsCustomAccentColor,
              icon: Icon(Icons.colorize_rounded),
              onPressed: () async {
                _showAccentColorPopup(themeProvider);
              },
            ),
          SettingsDropdown<String>(
              title: AppLocalizations.of(context)!.settingsFirstDayOfWeek,
              value: configProvider.get(ConfigKey.startingDayOfWeek),
              options: _buildFirstDayOfWeekDropdownItems(context),
              onChanged: (String? newValue) async {
                await configProvider.set(ConfigKey.startingDayOfWeek, newValue);
                statsProvider.updateStats();
              }),
          SettingsToggle(
              title: AppLocalizations.of(context)!.settingsShowMarkdownToolbar,
              settingsKey: ConfigKey.useMarkdownToolbar,
              onChanged: (value) {
                configProvider.set(ConfigKey.useMarkdownToolbar, value);
              }),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: SettingsDropdown<String>(
                title:
                    AppLocalizations.of(context)!.settingsFlashbacksViewLayout,
                value: configProvider.get(ConfigKey.homePageViewMode),
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
                    configProvider.set(ConfigKey.homePageViewMode, newValue);
                  }
                }),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SettingsDropdown<String>(
                title: AppLocalizations.of(context)!.settingsGalleryViewLayout,
                value: configProvider.get(ConfigKey.galleryPageViewMode),
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
                    configProvider.set(ConfigKey.galleryPageViewMode, newValue);
                  }
                }),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0, left: 16.0),
            child: Text(
              AppLocalizations.of(context)!.settingsChangeMoodIcons,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    moodIconButton(-2),
                    moodIconButton(-1),
                    moodIconButton(0),
                    moodIconButton(1),
                    moodIconButton(2),
                    moodIconButton(null),
                  ],
                ),
                IconButton(
                    onPressed: _resetMoodIcons,
                    icon: const Icon(Icons.refresh_rounded))
              ],
            ),
          ),
        ],
      ),
    );
  }
}
