import 'dart:io';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/import_utils.dart';
import 'package:daily_you/models/template.dart';
import 'package:daily_you/notification_manager.dart';
import 'package:daily_you/stats_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:daily_you/widgets/settings_dropdown.dart';
import 'package:daily_you/widgets/settings_header.dart';
import 'package:daily_you/widgets/settings_icon_action.dart';
import 'package:daily_you/widgets/settings_toggle.dart';
import 'package:daily_you/widgets/template_manager.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:daily_you/entries_database.dart';
import 'package:daily_you/theme_mode_provider.dart';
import 'package:time_range_picker/time_range_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isSyncing = false;
  List<Template> _templates = [];
  bool isLoading = true;
  String versionString = "0.0.0";
  int versionTapCount = 0;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<bool> requestStoragePermission() async {
    DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
    if (androidInfo.version.sdkInt < 33) {
      //Legacy Permission
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
      if (status.isGranted) {
        return true;
      }
      return false;
    }

    //Modern Permission
    return true;
  }

  Future<bool> requestPhotosPermission() async {
    DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
    if (androidInfo.version.sdkInt < 33) {
      //Legacy Permission
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
      if (status.isGranted) {
        return true;
      }
      return false;
    } else {
      //Modern Photos Permission
      return true;
    }
  }

  Future<void> _showChangeLogFolderWarning() async {
    bool confirmed = false;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.warningTitle),
          content:
              Text(AppLocalizations.of(context)!.logFolderWarningDescription),
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
                confirmed = true;
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
    if (confirmed) {
      setState(() {
        isSyncing = true;
      });
      bool locationSet =
          await EntriesDatabase.instance.selectDatabaseLocation();
      setState(() {
        isSyncing = false;
      });
      if (!locationSet) {
        await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                  title: Text(AppLocalizations.of(context)!.errorTitle),
                  actions: [
                    TextButton(
                      child:
                          Text(MaterialLocalizations.of(context).okButtonLabel),
                      onPressed: () async {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                  content: Text(
                      AppLocalizations.of(context)!.logFolderErrorDescription));
            });
      }
    }
  }

  Future<void> _attemptImageFolderChange() async {
    setState(() {
      isSyncing = true;
    });
    bool locationSet = await EntriesDatabase.instance.selectImageFolder();
    setState(() {
      isSyncing = false;
    });
    if (!locationSet) {
      await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
                title: Text(AppLocalizations.of(context)!.errorTitle),
                actions: [
                  TextButton(
                    child:
                        Text(MaterialLocalizations.of(context).okButtonLabel),
                    onPressed: () async {
                      Navigator.pop(context);
                    },
                  ),
                ],
                content: Text(
                    AppLocalizations.of(context)!.imageFolderErrorDescription));
          });
    }
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

  Future<void> _showImportSelectionPopup() async {
    ImportFormat chosenFormat = ImportFormat.none;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.logFormatTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.logFormatDescription),
              Divider(),
              ListTile(
                  title: Text(AppLocalizations.of(context)!.formatDailyYouJson),
                  onTap: () {
                    chosenFormat = ImportFormat.dailyYouJson;
                    Navigator.of(context).pop();
                  }),
              ListTile(
                  title: Text(AppLocalizations.of(context)!.formatOneShot),
                  onTap: () {
                    chosenFormat = ImportFormat.oneShot;
                    Navigator.of(context).pop();
                  }),
              ListTile(
                  title: Text(AppLocalizations.of(context)!.formatPixels),
                  onTap: () {
                    chosenFormat = ImportFormat.pixels;
                    Navigator.of(context).pop();
                  }),
            ],
          ),
        );
      },
    );

    if (chosenFormat != ImportFormat.none) {
      ValueNotifier<String> statusNotifier = ValueNotifier<String>("");

      _showLoadingStatus(context, statusNotifier);

      if (chosenFormat == ImportFormat.dailyYouJson) {
        await ImportUtils.importFromJson((status) {
          statusNotifier.value = status;
        });
      } else if (chosenFormat == ImportFormat.oneShot) {
        await ImportUtils.importFromOneShot((status) {
          statusNotifier.value = status;
        });
      } else if (chosenFormat == ImportFormat.pixels) {
        await ImportUtils.importFromPixels((status) {
          statusNotifier.value = status;
        });
      }

      Navigator.of(context).pop();
    }
  }

  void _showLoadingStatus(
      BuildContext context, ValueNotifier<String> statusNotifier) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  ValueListenableBuilder<String>(
                    valueListenable: statusNotifier,
                    builder: (context, message, child) {
                      return Text(message, textAlign: TextAlign.center);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteAllLogs(BuildContext context) async {
    ValueNotifier<String> statusNotifier = ValueNotifier<String>("");

    _showLoadingStatus(context, statusNotifier);

    await EntriesDatabase.instance.deleteAllEntries((status) {
      statusNotifier.value = status;
    });

    Navigator.of(context).pop();
  }

  Future<void> _backupData(BuildContext context) async {
    ValueNotifier<String> statusNotifier = ValueNotifier<String>("");

    _showLoadingStatus(context, statusNotifier);

    bool success =
        await EntriesDatabase.instance.backupToZip(context, (status) {
      statusNotifier.value = status;
    });

    Navigator.of(context).pop();

    if (!success) {
      await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
                title: Text(AppLocalizations.of(context)!.errorTitle),
                actions: [
                  TextButton(
                    child:
                        Text(MaterialLocalizations.of(context).okButtonLabel),
                    onPressed: () async {
                      Navigator.pop(context);
                    },
                  ),
                ],
                content:
                    Text(AppLocalizations.of(context)!.backupErrorDescription));
          });
    }
  }

  Future<void> _restoreData(BuildContext context) async {
    ValueNotifier<String> statusNotifier = ValueNotifier<String>("");

    _showLoadingStatus(context, statusNotifier);

    bool success =
        await EntriesDatabase.instance.restoreFromZip(context, (status) {
      statusNotifier.value = status;
    });

    Navigator.of(context).pop();

    if (!success) {
      await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
                title: Text(AppLocalizations.of(context)!.errorTitle),
                actions: [
                  TextButton(
                    child:
                        Text(MaterialLocalizations.of(context).okButtonLabel),
                    onPressed: () async {
                      Navigator.pop(context);
                    },
                  ),
                ],
                content: Text(
                    AppLocalizations.of(context)!.restoreErrorDescription));
          });
    }
  }

  Future<void> _showRestoreWarning() async {
    bool confirmed = false;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.warningTitle),
          content: Text(
              AppLocalizations.of(context)!.settingsRestorePromptDescription),
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
                confirmed = true;
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
    if (confirmed) {
      await _restoreData(context);
    }
  }

  void _showDeleteAllLogsDialog(
      BuildContext context, String requiredText, VoidCallback onConfirm) {
    ThemeData theme = Theme.of(context);
    final TextEditingController controller = TextEditingController();
    final ValueNotifier<bool> isButtonEnabled = ValueNotifier(false);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.settingsDeleteAllLogsTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!
                  .settingsDeleteAllLogsDescription),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(AppLocalizations.of(context)!
                    .settingsDeleteAllLogsPrompt(requiredText)),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                    child: TextField(
                      decoration: InputDecoration(
                          hintStyle: TextStyle(fontStyle: FontStyle.italic),
                          hintText: requiredText,
                          border: InputBorder.none),
                      controller: controller,
                      onChanged: (value) {
                        isButtonEnabled.value = value.toLowerCase().trim() ==
                            requiredText.toLowerCase().trim();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: isButtonEnabled,
              builder: (context, isEnabled, child) {
                return TextButton(
                  onPressed: isEnabled
                      ? () {
                          Navigator.of(context).pop();
                          onConfirm();
                        }
                      : null,
                  child: Text(
                      style: TextStyle(
                          color: isEnabled ? null : theme.disabledColor),
                      MaterialLocalizations.of(context).deleteButtonTooltip),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeManager.scheduledReminderTime(),
    );

    if (picked != null) {
      await ConfigProvider.instance
          .set(ConfigKey.scheduledReminderHour, picked.hour);
      await ConfigProvider.instance
          .set(ConfigKey.scheduledReminderMinute, picked.minute);
      if (ConfigProvider.instance.get(ConfigKey.dailyReminders)) {
        await NotificationManager.instance.stopDailyReminders();
        await NotificationManager.instance.startScheduledDailyReminders();
      }
    }
  }

  Future<void> _selectTimeRange(BuildContext context) async {
    ThemeData theme = Theme.of(context);
    TimeRange currentRange = TimeManager.getReminderTimeRange();
    TimeRange? range = await showTimeRangePicker(
        context: context,
        toText: "",
        fromText: "",
        use24HourFormat: ConfigProvider.instance.is24HourFormat(),
        start: currentRange.startTime,
        end: currentRange.endTime,
        ticks: 24,
        handlerColor: theme.colorScheme.primary,
        strokeColor: theme.colorScheme.primary,
        selectedColor: theme.colorScheme.primary,
        backgroundColor: theme.disabledColor.withOpacity(0.2),
        ticksColor: theme.colorScheme.surface,
        interval: Duration(minutes: 10),
        ticksWidth: 2,
        autoAdjustLabels: false,
        labels: [
          ClockLabel.fromTime(
              time: TimeOfDay(hour: 0, minute: 0),
              text: DateFormat.j(WidgetsBinding
                      .instance.platformDispatcher.locale
                      .toString())
                  .format(TimeManager.addTimeOfDay(
                      TimeManager.startOfDay(DateTime.now()),
                      TimeOfDay(hour: 0, minute: 0)))),
          ClockLabel.fromTime(
              time: TimeOfDay(hour: 6, minute: 0),
              text: DateFormat.j(WidgetsBinding
                      .instance.platformDispatcher.locale
                      .toString())
                  .format(TimeManager.addTimeOfDay(
                      TimeManager.startOfDay(DateTime.now()),
                      TimeOfDay(hour: 6, minute: 0)))),
          ClockLabel.fromTime(
              time: TimeOfDay(hour: 12, minute: 0),
              text: DateFormat.j(WidgetsBinding
                      .instance.platformDispatcher.locale
                      .toString())
                  .format(TimeManager.addTimeOfDay(
                      TimeManager.startOfDay(DateTime.now()),
                      TimeOfDay(hour: 12, minute: 0)))),
          ClockLabel.fromTime(
              time: TimeOfDay(hour: 18, minute: 0),
              text: DateFormat.j(WidgetsBinding
                      .instance.platformDispatcher.locale
                      .toString())
                  .format(TimeManager.addTimeOfDay(
                      TimeManager.startOfDay(DateTime.now()),
                      TimeOfDay(hour: 18, minute: 0)))),
        ]);
    if (range != null) {
      await TimeManager.setReminderTimeRange(range);
      if (ConfigProvider.instance.get(ConfigKey.dailyReminders)) {
        await NotificationManager.instance.stopDailyReminders();
        await NotificationManager.instance.startScheduledDailyReminders();
      }
    }
  }

  Future<void> _loadTemplates() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    versionString = packageInfo.version;
    List<Template> templates = await EntriesDatabase.instance.getAllTemplates();
    setState(() {
      _templates = templates;
      isLoading = false;
    });
  }

  void _showTemplateManagementPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return TemplateManager(
          onTemplatesUpdated: _loadTemplates,
        );
      },
    );
  }

  List<DropdownMenuItem<int>> _buildDefaultTemplateDropdownItems(
      BuildContext context) {
    var dropdownItems = _templates.map((Template template) {
      return DropdownMenuItem<int>(
        value: template.id,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 180),
          child: Text(
            template.name,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }).toList();
    dropdownItems.add(DropdownMenuItem<int>(
      value: -1,
      child: Text(AppLocalizations.of(context)!.noTemplateTitle),
    ));
    return dropdownItems;
  }

  List<DropdownMenuItem<String>> _buildFirstDayOfWeekDropdownItems(
      BuildContext context) {
    final dayLabels = TimeManager.daysOfWeekLabels();
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
    final Color pinkAccentColor = const Color(0xffff00d5);
    final statsProvider = Provider.of<StatsProvider>(context);
    final themeProvider = Provider.of<ThemeModeProvider>(context);
    final configProvider = Provider.of<ConfigProvider>(context);

    return PopScope(
      canPop: !isSyncing,
      child: isSyncing
          ? Scaffold(
              body: Center(
                  child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                statsProvider.totalEntries == 0
                    ? Container()
                    : Text(
                        "${statsProvider.syncedEntries}/${statsProvider.totalEntries}"),
                const SizedBox(
                  height: 10,
                ),
              ],
            )))
          : Scaffold(
              appBar: AppBar(
                title: Text(AppLocalizations.of(context)!.pageSettingsTitle),
              ),
              body: ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  SettingsHeader(
                      text: AppLocalizations.of(context)!
                          .settingsAppearanceTitle),
                  SettingsDropdown<String>(
                      title: AppLocalizations.of(context)!.settingsTheme,
                      settingsKey: ConfigKey.theme,
                      options: [
                        DropdownMenuItem<String>(
                            value: "system",
                            child: Text(
                                AppLocalizations.of(context)!.themeSystem)),
                        DropdownMenuItem<String>(
                            value: "dark",
                            child:
                                Text(AppLocalizations.of(context)!.themeDark)),
                        DropdownMenuItem<String>(
                            value: "light",
                            child:
                                Text(AppLocalizations.of(context)!.themeLight)),
                        DropdownMenuItem<String>(
                            value: "amoled",
                            child: Text(
                                AppLocalizations.of(context)!.themeAmoled)),
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
                      title: AppLocalizations.of(context)!
                          .settingsUseSystemAccentColor,
                      settingsKey: ConfigKey.followSystemColor,
                      onChanged: (value) {
                        configProvider.set(ConfigKey.followSystemColor, value);
                        themeProvider.updateAccentColor();
                      }),
                  if (!configProvider.get(ConfigKey.followSystemColor))
                    SettingsIconAction(
                      title: AppLocalizations.of(context)!
                          .settingsCustomAccentColor,
                      icon: Icon(Icons.colorize_rounded),
                      onPressed: () async {
                        _showAccentColorPopup(themeProvider);
                      },
                    ),
                  SettingsDropdown<String>(
                      title:
                          AppLocalizations.of(context)!.settingsFirstDayOfWeek,
                      settingsKey: ConfigKey.startingDayOfWeek,
                      options: _buildFirstDayOfWeekDropdownItems(context),
                      onChanged: (String? newValue) async {
                        await configProvider.set(
                            ConfigKey.startingDayOfWeek, newValue);
                        statsProvider.updateStats();
                      }),
                  SettingsToggle(
                      title: AppLocalizations.of(context)!
                          .settingsShowMarkdownToolbar,
                      settingsKey: ConfigKey.useMarkdownToolbar,
                      onChanged: (value) {
                        configProvider.set(ConfigKey.useMarkdownToolbar, value);
                      }),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      AppLocalizations.of(context)!.settingsChangeMoodIcons,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Row(
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
                  const Divider(),
                  if (Platform.isAndroid)
                    SettingsHeader(
                        text: AppLocalizations.of(context)!
                            .settingsNotificationsTitle),
                  if (Platform.isAndroid)
                    SettingsToggle(
                        title: AppLocalizations.of(context)!
                            .settingsDailyReminderTitle,
                        hint: AppLocalizations.of(context)!
                            .settingsDailyReminderDescription,
                        settingsKey: ConfigKey.dailyReminders,
                        onChanged: (value) async {
                          if (await NotificationManager.instance
                              .hasNotificationPermission()) {
                            if (value) {
                              await NotificationManager.instance
                                  .startScheduledDailyReminders();
                            } else {
                              await NotificationManager.instance
                                  .stopDailyReminders();
                            }
                            await configProvider.set(
                                ConfigKey.dailyReminders, value);
                          }
                        }),
                  if (Platform.isAndroid &&
                      configProvider.get(ConfigKey.dailyReminders))
                    configProvider.get(ConfigKey.setReminderTime)
                        ? SettingsIconAction(
                            title: AppLocalizations.of(context)!
                                .settingsReminderTime,
                            hint: TimeManager.timeOfDayString(
                                TimeManager.scheduledReminderTime()),
                            icon: Icon(Icons.schedule_rounded),
                            onPressed: () async {
                              _selectTime(context);
                            })
                        : SettingsIconAction(
                            title: AppLocalizations.of(context)!
                                .settingsReminderTime,
                            hint: TimeManager.timeRangeString(
                                TimeManager.getReminderTimeRange()),
                            icon: Icon(Icons.timelapse_rounded),
                            onPressed: () async {
                              _selectTimeRange(context);
                            }),
                  if (Platform.isAndroid &&
                      configProvider.get(ConfigKey.dailyReminders))
                    SettingsToggle(
                        title: AppLocalizations.of(context)!
                            .settingsFixedReminderTimeTitle,
                        hint: AppLocalizations.of(context)!
                            .settingsFixedReminderTimeDescription,
                        settingsKey: ConfigKey.setReminderTime,
                        onChanged: (value) async {
                          await configProvider.set(
                              ConfigKey.setReminderTime, value);
                          await NotificationManager.instance
                              .stopDailyReminders();
                          await NotificationManager.instance
                              .startScheduledDailyReminders();
                        }),
                  if (Platform.isAndroid) const Divider(),
                  SettingsHeader(
                      text:
                          AppLocalizations.of(context)!.settingsTemplatesTitle),
                  if (!isLoading)
                    SettingsDropdown<int>(
                      title:
                          AppLocalizations.of(context)!.settingsDefaultTemplate,
                      settingsKey: ConfigKey.defaultTemplate,
                      options: _buildDefaultTemplateDropdownItems(context),
                      onChanged: (int? newValue) {
                        configProvider.set(ConfigKey.defaultTemplate, newValue);
                      },
                    ),
                  SettingsIconAction(
                      title: AppLocalizations.of(context)!.manageTemplates,
                      icon: Icon(Icons.edit_document),
                      onPressed: () => _showTemplateManagementPopup(context)),
                  const Divider(),
                  SettingsHeader(
                      text: AppLocalizations.of(context)!.settingsStorageTitle),
                  SettingsDropdown<int>(
                      title: AppLocalizations.of(context)!.settingsImageQuality,
                      settingsKey: ConfigKey.imageQuality,
                      options: [
                        DropdownMenuItem<int>(
                            value: 100,
                            child: Text(AppLocalizations.of(context)!
                                .imageQualityNoCompression)),
                        DropdownMenuItem<int>(
                            value: 90,
                            child: Text(AppLocalizations.of(context)!
                                .imageQualityHigh)),
                        DropdownMenuItem<int>(
                            value: 75,
                            child: Text(AppLocalizations.of(context)!
                                .imageQualityMedium)),
                        DropdownMenuItem<int>(
                            value: 50,
                            child: Text(
                                AppLocalizations.of(context)!.imageQualityLow)),
                      ],
                      onChanged: (int? newValue) {
                        configProvider.set(ConfigKey.imageQuality, newValue);
                      }),
                  FutureBuilder(
                      future: EntriesDatabase.instance.getInternalDbPath(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          var folderText = snapshot.data!;
                          if (EntriesDatabase.instance.usingExternalDb()) {
                            folderText =
                                configProvider.get(ConfigKey.externalDbUri);
                          }
                          return SettingsIconAction(
                            title:
                                AppLocalizations.of(context)!.settingsLogFolder,
                            hint: folderText,
                            icon: Icon(Icons.folder_rounded),
                            secondaryIcon: Icon(Icons.refresh_rounded),
                            onPressed: () async {
                              if (Platform.isAndroid &&
                                  !await requestStoragePermission()) {
                                return;
                              }
                              await _showChangeLogFolderWarning();
                            },
                            onSecondaryPressed: () async {
                              EntriesDatabase.instance.resetDatabaseLocation();
                            },
                          );
                        }
                        return const SizedBox();
                      }),
                  FutureBuilder(
                      future:
                          EntriesDatabase.instance.getInternalImgDatabasePath(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          var folderText = snapshot.data!;
                          if (EntriesDatabase.instance.usingExternalImg()) {
                            folderText =
                                configProvider.get(ConfigKey.externalImgUri);
                          }
                          return SettingsIconAction(
                            title: AppLocalizations.of(context)!
                                .settingsImageFolder,
                            hint: folderText,
                            icon: Icon(Icons.folder_rounded),
                            secondaryIcon: Icon(Icons.refresh_rounded),
                            onPressed: () async {
                              if (Platform.isAndroid &&
                                  !await requestPhotosPermission()) {
                                return;
                              }
                              await _attemptImageFolderChange();
                            },
                            onSecondaryPressed: () async {
                              EntriesDatabase.instance
                                  .resetImageFolderLocation();
                            },
                          );
                        }
                        return const SizedBox();
                      }),
                  SettingsIconAction(
                      title: AppLocalizations.of(context)!.settingsBackup,
                      icon: Icon(Icons.backup_rounded),
                      onPressed: () async {
                        await _backupData(context);
                      }),
                  SettingsIconAction(
                      title: AppLocalizations.of(context)!.settingsRestore,
                      icon: Icon(Icons.restore_rounded),
                      onPressed: () async {
                        await _showRestoreWarning();
                      }),
                  SettingsIconAction(
                      title: AppLocalizations.of(context)!.settingsImport,
                      icon: Icon(Icons.download_rounded),
                      onPressed: () async {
                        await _showImportSelectionPopup();
                      }),
                  SettingsIconAction(
                      title: AppLocalizations.of(context)!
                          .settingsDeleteAllLogsTitle,
                      icon: Icon(Icons.delete_forever_rounded),
                      onPressed: () => _showDeleteAllLogsDialog(
                          context,
                          AppLocalizations.of(context)!
                              .settingsDeleteAllLogsTitle,
                          () => _deleteAllLogs(context))),
                  const Divider(),
                  SettingsHeader(
                      text: AppLocalizations.of(context)!.settingsAboutTitle),
                  GestureDetector(
                    child: SettingsIconAction(
                        title: AppLocalizations.of(context)!.settingsVersion,
                        hint: versionString,
                        icon: Icon(Icons.open_in_new_rounded),
                        onPressed: () async {
                          await launchUrl(
                              Uri.https(
                                  "github.com", "/Demizo/Daily_You/releases"),
                              mode: LaunchMode.externalApplication);
                        }),
                    onTap: () async {
                      versionTapCount += 1;
                      if (versionTapCount > 5) {
                        versionTapCount = 0;

                        await configProvider.set(
                            ConfigKey.followSystemColor, false);

                        themeProvider.accentColor = pinkAccentColor;
                        themeProvider.updateAccentColor();

                        await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Center(child: Text("❤️❤️❤️")),
                            );
                          },
                        );
                      }
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
                  SettingsIconAction(
                      title: AppLocalizations.of(context)!.settingsSourceCode,
                      hint: "github.com/Demizo/Daily_You",
                      icon: Icon(Icons.open_in_new_rounded),
                      onPressed: () async {
                        await launchUrl(
                            Uri.https("github.com", "/Demizo/Daily_You"),
                            mode: LaunchMode.externalApplication);
                      }),
                ],
              ),
            ),
    );
  }
}
