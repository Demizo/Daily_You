import 'dart:io';

import 'package:daily_you/models/template.dart';
import 'package:daily_you/notification_manager.dart';
import 'package:daily_you/stats_provider.dart';
import 'package:daily_you/time_manager.dart';
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

import '../config_manager.dart';
import '../widgets/mood_icon.dart';

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

  Future<void> _showChangeLogFolderWarning(BuildContext context) async {
    bool confirmed = false;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Warning:'),
          content: const Text(
              "Backup your logs and images before changing the log folder! If the selected directory already contains \"daily_you.db\", it will be used to overwrite your current logs!"),
          actions: [
            ElevatedButton(
              child: const Text("Ok"),
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
              return const AlertDialog(
                  title: Text("Error:"),
                  content: Text("Permission Denied: Log folder not changed!"));
            });
      }

      setState(() {});
    }
  }

  Future<void> _showChangeImgFolderWarning(BuildContext context) async {
    bool confirmed = false;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Warning:'),
          content: const Text(
              "Backup your images before changing the image folder!"),
          actions: [
            ElevatedButton(
              child: const Text("Ok"),
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
      bool locationSet = await EntriesDatabase.instance.selectImageFolder();
      setState(() {
        isSyncing = false;
      });
      if (!locationSet) {
        await showDialog(
            context: context,
            builder: (BuildContext context) {
              return const AlertDialog(
                  title: Text("Error:"),
                  content:
                      Text("Permission Denied: Image folder not changed!"));
            });
      }

      setState(() {});
    }
  }

  void _showAccentColorPopup(ThemeModeProvider themeProvider) {
    Color accentColor = Color(ConfigManager.instance.getField('accentColor'));
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
                setState(() {
                  themeProvider.accentColor = accentColor;
                  themeProvider.updateAccentColor();
                });
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
                      Color(ConfigManager.instance.getField('accentColor')),
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
                    await ConfigManager.instance.setField(
                        ConfigManager.moodValueFieldMapping[value]!, newEmoji);
                  } else {
                    await ConfigManager.instance
                        .setField('noMoodIcon', newEmoji);
                  }
                  setState(() {});
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
    for (var mood in ConfigManager.defaultMoodIconFieldMapping.entries) {
      await ConfigManager.instance.setField(mood.key, mood.value);
    }
    setState(() {});
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

  void _showImportSelectionPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Import Logs From:'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("This will NOT modify existing logs..."),
              const SizedBox(
                height: 8,
              ),
              ListTile(
                  title: const Text('Daily You'),
                  onTap: () async {
                    Navigator.pop(context);
                    setState(() {
                      isSyncing = true;
                    });
                    await EntriesDatabase.instance.importFromJson();
                    setState(() {
                      isSyncing = false;
                    });
                  }),
              ListTile(
                  title: const Text('OneShot'),
                  onTap: () async {
                    Navigator.pop(context);
                    setState(() {
                      isSyncing = true;
                    });
                    await EntriesDatabase.instance.importFromOneShot();
                    setState(() {
                      isSyncing = false;
                    });
                  }),
            ],
          ),
        );
      },
    );
  }

  void _showExportSelectionPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Export Format:'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                  title: const Text('Daily You'),
                  onTap: () async {
                    Navigator.pop(context);
                    await EntriesDatabase.instance.exportToJson();
                  }),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteEntriesPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete All Logs?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Do you want to delete all of your logs?"),
              const SizedBox(
                height: 8,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(
                      Icons.delete_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    label: const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Text(
                        "Delete All",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await EntriesDatabase.instance.deleteAllEntries();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: Icon(
                      Icons.cancel_rounded,
                      color: Theme.of(context).colorScheme.surface,
                      size: 24,
                    ),
                    label: const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Text(
                        "Cancel",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.surface,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
      await ConfigManager.instance
          .setField('scheduledReminderHour', picked.hour);
      await ConfigManager.instance
          .setField('scheduledReminderMinute', picked.minute);
      setState(() {});
      if (ConfigManager.instance.getField('dailyReminders')) {
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
        use24HourFormat: ConfigManager.instance.is24HourFormat(),
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
      if (ConfigManager.instance.getField('dailyReminders')) {
        await NotificationManager.instance.stopDailyReminders();
        await NotificationManager.instance.startScheduledDailyReminders();
      }
      setState(() {});
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

  List<DropdownMenuItem<int>> _buildDefaultTemplateDropdownItems() {
    var dropdownItems = _templates.map((Template template) {
      return DropdownMenuItem<int>(
        value: template.id,
        child: Text(
          template.name,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }).toList();
    dropdownItems.add(const DropdownMenuItem<int>(
      value: -1,
      child: Text("None"),
    ));
    return dropdownItems;
  }

  @override
  Widget build(BuildContext context) {
    final statsProvider = Provider.of<StatsProvider>(context);
    final themeProvider = Provider.of<ThemeModeProvider>(context);
    return PopScope(
      canPop: !isSyncing,
      child: isSyncing
          ? Scaffold(
              body: Center(
                  child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Syncing...",
                  style: TextStyle(fontSize: 22),
                ),
                const Text(
                  "Do not close the app! This may take awhile...",
                  style: TextStyle(fontSize: 18),
                ),
                statsProvider.totalEntries == 0
                    ? const Text("Loading...")
                    : Text(
                        "Synced ${statsProvider.syncedEntries} out of ${statsProvider.totalEntries}"),
                const SizedBox(
                  height: 10,
                ),
                const CircularProgressIndicator(),
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
                      settingsKey: "theme",
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
                        setState(() {
                          themeProvider.themeMode = themeMode;
                          ConfigManager.instance.setField("theme", newValue);
                        });
                      }),
                  SettingsToggle(
                      title: AppLocalizations.of(context)!
                          .settingsUseSystemAccentColor,
                      settingsKey: "followSystemColor",
                      onChanged: (value) {
                        setState(() {
                          ConfigManager.instance
                              .setField('followSystemColor', value);
                          themeProvider.updateAccentColor();
                        });
                      }),
                  if (!ConfigManager.instance.getField('followSystemColor'))
                    SettingsIconAction(
                      title: AppLocalizations.of(context)!
                          .settingsCustomAccentColor,
                      icon: Icon(Icons.colorize_rounded),
                      onPressed: () async {
                        _showAccentColorPopup(themeProvider);
                      },
                    ),
                  SettingsToggle(
                      title: AppLocalizations.of(context)!
                          .settingsShowMarkdownToolbar,
                      settingsKey: "useMarkdownToolbar",
                      onChanged: (value) {
                        setState(() {
                          ConfigManager.instance
                              .setField("useMarkdownToolbar", value);
                        });
                      }),
                  Text(
                    AppLocalizations.of(context)!.settingsChangeMoodIcons,
                    style: TextStyle(fontSize: 16),
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
                        title: AppLocalizations.of(context)!.dailyReminderTitle,
                        hint: AppLocalizations.of(context)!
                            .dailyReminderDescription,
                        settingsKey: "dailyReminders",
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
                            await ConfigManager.instance
                                .setField('dailyReminders', value);
                            setState(() {});
                          }
                        }),
                  if (Platform.isAndroid &&
                      ConfigManager.instance.getField('dailyReminders'))
                    ConfigManager.instance.getField('setReminderTime')
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
                      ConfigManager.instance.getField('dailyReminders'))
                    SettingsToggle(
                        title: AppLocalizations.of(context)!
                            .settingsFixedReminderTimeTitle,
                        hint: AppLocalizations.of(context)!
                            .settingsFixedReminderTimeDescription,
                        settingsKey: 'setReminderTime',
                        onChanged: (value) async {
                          await ConfigManager.instance
                              .setField('setReminderTime', value);
                          await NotificationManager.instance
                              .stopDailyReminders();
                          await NotificationManager.instance
                              .startScheduledDailyReminders();
                          setState(() {});
                        }),
                  if (Platform.isAndroid) const Divider(),
                  SettingsHeader(text: "Templates"),
                  if (!isLoading)
                    SettingsDropdown<int>(
                      title: "Default Template",
                      settingsKey: "defaultTemplate",
                      options: _buildDefaultTemplateDropdownItems(),
                      onChanged: (int? newValue) {
                        setState(() {
                          ConfigManager.instance
                              .setField("defaultTemplate", newValue);
                        });
                      },
                    ),
                  SettingsIconAction(
                      title: 'Manage Templates',
                      icon: Icon(Icons.edit_document),
                      onPressed: () => _showTemplateManagementPopup(context)),
                  const Divider(),
                  SettingsHeader(text: "Storage"),
                  SettingsDropdown<int>(
                      title: "Image Quality",
                      settingsKey: "imageQuality",
                      options: [
                        DropdownMenuItem<int>(
                            value: 100, child: Text("No Compression")),
                        DropdownMenuItem<int>(value: 90, child: Text("High")),
                        DropdownMenuItem<int>(value: 75, child: Text("Medium")),
                        DropdownMenuItem<int>(value: 50, child: Text("Low")),
                      ],
                      onChanged: (int? newValue) {
                        setState(() {
                          ConfigManager.instance
                              .setField("imageQuality", newValue);
                        });
                      }),
                  FutureBuilder(
                      future: EntriesDatabase.instance.getInternalDbPath(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          var folderText = snapshot.data!;
                          if (EntriesDatabase.instance.usingExternalDb()) {
                            folderText = ConfigManager.instance
                                .getField('externalDbUri');
                          }
                          return SettingsIconAction(
                            title: 'Log Folder',
                            hint: folderText,
                            icon: Icon(Icons.folder_rounded),
                            secondaryIcon: Icon(Icons.refresh_rounded),
                            onPressed: () async {
                              if (Platform.isAndroid &&
                                  !await requestStoragePermission()) {
                                return;
                              }
                              await _showChangeLogFolderWarning(context);
                            },
                            onSecondaryPressed: () async {
                              EntriesDatabase.instance.resetDatabaseLocation();
                              setState(() {});
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
                            folderText = ConfigManager.instance
                                .getField('externalImgUri');
                          }
                          return SettingsIconAction(
                            title: 'Image Folder',
                            hint: folderText,
                            icon: Icon(Icons.folder_rounded),
                            secondaryIcon: Icon(Icons.refresh_rounded),
                            onPressed: () async {
                              if (Platform.isAndroid &&
                                  !await requestPhotosPermission()) {
                                return;
                              }
                              await _showChangeImgFolderWarning(context);
                            },
                            onSecondaryPressed: () async {
                              EntriesDatabase.instance
                                  .resetImageFolderLocation();
                              setState(() {});
                            },
                          );
                        }
                        return const SizedBox();
                      }),
                  SettingsIconAction(
                      title: "Export Logs",
                      icon: Icon(Icons.upload_rounded),
                      onPressed: () async {
                        if (Platform.isAndroid &&
                            !await requestStoragePermission()) {
                          return;
                        }
                        _showExportSelectionPopup();
                      }),
                  SettingsIconAction(
                      title: "Export Images",
                      icon: Icon(Icons.photo),
                      onPressed: () async {
                        if (Platform.isAndroid &&
                            !await requestPhotosPermission()) {
                          return;
                        }
                        await EntriesDatabase.instance.exportImages();
                      }),
                  SettingsIconAction(
                      title: "Import Logs",
                      icon: Icon(Icons.download_rounded),
                      onPressed: () async {
                        if (Platform.isAndroid &&
                            !await requestStoragePermission()) {
                          return;
                        }
                        _showImportSelectionPopup();
                      }),
                  SettingsIconAction(
                      title: "Import Images",
                      icon: Icon(Icons.photo),
                      onPressed: () async {
                        if (Platform.isAndroid &&
                            !await requestPhotosPermission()) {
                          return;
                        }
                        setState(() {
                          isSyncing = true;
                        });
                        await EntriesDatabase.instance.importImages();
                        setState(() {
                          isSyncing = false;
                        });
                      }),
                  SettingsIconAction(
                      title: "Delete All Logs",
                      icon: Icon(Icons.delete_forever_rounded),
                      onPressed: () => _showDeleteEntriesPopup()),
                  const Divider(),
                  SettingsHeader(text: "About"),
                  SettingsIconAction(
                      title: "Version",
                      hint: versionString,
                      icon: Icon(Icons.open_in_new_rounded),
                      onPressed: () async {
                        await launchUrl(
                            Uri.https(
                                "github.com", "/Demizo/Daily_You/releases"),
                            mode: LaunchMode.externalApplication);
                      }),
                  SettingsIconAction(
                      title: "License",
                      hint: "GPL-3.0",
                      icon: Icon(Icons.open_in_new_rounded),
                      onPressed: () async {
                        await launchUrl(
                            Uri.https("github.com",
                                "/Demizo/Daily_You/blob/master/LICENSE.txt"),
                            mode: LaunchMode.externalApplication);
                      }),
                  SettingsIconAction(
                      title: "Source Code",
                      hint: "Github",
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
