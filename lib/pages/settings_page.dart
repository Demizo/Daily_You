import 'dart:io';

import 'package:daily_you/models/template.dart';
import 'package:daily_you/notification_manager.dart';
import 'package:daily_you/stats_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/template_manager.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:daily_you/entries_database.dart';
import 'package:daily_you/theme_mode_provider.dart';
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

  void _showThemeSelectionPopup(ThemeModeProvider themeModeProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Follow System'),
                onTap: () async {
                  await ConfigManager.instance.setField('theme', 'system');
                  setState(() {
                    _updateTheme(themeModeProvider, ThemeMode.system);
                  });
                },
              ),
              ListTile(
                title: const Text('Dark Theme'),
                onTap: () async {
                  await ConfigManager.instance.setField('theme', 'dark');
                  setState(() {
                    _updateTheme(themeModeProvider, ThemeMode.dark);
                  });
                },
              ),
              ListTile(
                  title: const Text('Light Theme'),
                  onTap: () async {
                    await ConfigManager.instance.setField('theme', 'light');
                    setState(() {
                      _updateTheme(themeModeProvider, ThemeMode.light);
                    });
                  }),
              ListTile(
                  title: const Text('AMOLED'),
                  onTap: () async {
                    await ConfigManager.instance.setField('theme', 'amoled');
                    setState(() {
                      _updateTheme(themeModeProvider, ThemeMode.dark);
                    });
                  }),
            ],
          ),
        );
      },
    );
  }

  void _showAccentColorPopup(ThemeModeProvider themeProvider) {
    Color accentColor = Color(ConfigManager.instance.getField('accentColor'));
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Accent Color'),
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
              const SizedBox(
                height: 8,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    child: const Text("Cancel"),
                    onPressed: () async {
                      Navigator.pop(context);
                    },
                  ),
                  TextButton(
                    child: const Text("Save"),
                    onPressed: () async {
                      setState(() {
                        themeProvider.accentColor = accentColor;
                        themeProvider.updateAccentColor();
                      });
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMoodEmojiPopup(int? value, String title) {
    String newEmoji = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                inputFormatters: [
                  LengthLimitingTextInputFormatter(1), // Limit to one character
                ],
                onChanged: (value) {
                  newEmoji = value;
                },
                decoration: const InputDecoration(
                  hintText: 'Enter an icon...',
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    child: const Text("Cancel"),
                    onPressed: () async {
                      Navigator.pop(context);
                    },
                  ),
                  TextButton(
                    child: const Text("Save"),
                    onPressed: () async {
                      if (newEmoji.isNotEmpty) {
                        if (value != null) {
                          await ConfigManager.instance.setField(
                              ConfigManager.moodValueFieldMapping[value]!,
                              newEmoji);
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
              ),
            ],
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

  Widget moodIconButton(int? index, String title) {
    return GestureDetector(
      child: Card(
          child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Container(
            constraints: const BoxConstraints(minWidth: 30),
            child: Center(child: MoodIcon(moodValue: index, size: 24))),
      )),
      onTap: () => _showMoodEmojiPopup(index, title),
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
                    icon: const Icon(
                      Icons.delete_rounded,
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
                    icon: const Icon(
                      Icons.cancel_rounded,
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

  void _updateTheme(ThemeModeProvider themeModeProvider, ThemeMode mode) {
    themeModeProvider.themeMode = mode;
    // setState(() {
    //   currentThemeMode = mode;
    // });
    Navigator.pop(context); // Close the popup
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

  Future<void> _loadTemplates() async {
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
                title: const Text("Settings"),
              ),
              body: ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  const Row(
                    children: [
                      Text(
                        "Appearance",
                        style: TextStyle(fontSize: 24),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Theme",
                          style: TextStyle(fontSize: 18),
                        ),
                        ElevatedButton.icon(
                          icon: Icon(
                            themeProvider.themeMode == ThemeMode.system
                                ? Icons.brightness_medium
                                : themeProvider.themeMode == ThemeMode.light
                                    ? Icons.brightness_high
                                    : Icons.brightness_2_rounded,
                          ),
                          label: themeProvider.themeMode == ThemeMode.system
                              ? const Text("System")
                              : themeProvider.themeMode == ThemeMode.light
                                  ? const Text("Light")
                                  : (ConfigManager.instance.getField('theme') ==
                                          'amoled')
                                      ? const Text("AMOLED")
                                      : const Text("Dark"),
                          onPressed: () async {
                            await ConfigManager.instance
                                .setField('theme', 'system');
                            _showThemeSelectionPopup(themeProvider);
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Use System Accent Color",
                                  style: TextStyle(fontSize: 18),
                                ),
                                Switch(
                                    value: ConfigManager.instance
                                        .getField('followSystemColor'),
                                    onChanged: (value) {
                                      setState(() {
                                        ConfigManager.instance.setField(
                                            'followSystemColor', value);
                                        themeProvider.updateAccentColor();
                                      });
                                    })
                              ]),
                          if (!ConfigManager.instance
                              .getField('followSystemColor'))
                            ElevatedButton.icon(
                              icon: const Icon(
                                Icons.color_lens_rounded,
                              ),
                              label: const Text("Custom Accent Color"),
                              onPressed: () async {
                                _showAccentColorPopup(themeProvider);
                              },
                            ),
                        ],
                      )),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Change Mood Icons",
                          style: TextStyle(fontSize: 18),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                moodIconButton(-2, "Very Sad Icon"),
                                moodIconButton(-1, "Sad Icon"),
                                moodIconButton(0, "Neutral Icon"),
                                moodIconButton(1, "Happy Icon"),
                                moodIconButton(2, "Very Happy Icon"),
                                moodIconButton(null, "Unknown Mood Icon"),
                              ],
                            ),
                            IconButton(
                                onPressed: _resetMoodIcons,
                                icon: const Icon(Icons.refresh_rounded))
                          ],
                        )
                      ],
                    ),
                  ),
                  Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Start Calendar Week on Monday",
                              style: TextStyle(fontSize: 18),
                            ),
                            Switch(
                                value: ConfigManager.instance
                                        .getField('startingDayOfWeek') !=
                                    'sunday',
                                onChanged: (value) {
                                  if (value) {
                                    setState(() {
                                      ConfigManager.instance.setField(
                                          'startingDayOfWeek', 'monday');
                                    });
                                  } else {
                                    setState(() {
                                      ConfigManager.instance.setField(
                                          'startingDayOfWeek', 'sunday');
                                    });
                                  }
                                })
                          ])),
                  Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Show Markdown Toolbar",
                              style: TextStyle(fontSize: 18),
                            ),
                            Switch(
                                value: ConfigManager.instance
                                    .getField('useMarkdownToolbar'),
                                onChanged: (value) async {
                                  await ConfigManager.instance
                                      .setField('useMarkdownToolbar', value);
                                  setState(() {});
                                })
                          ])),
                  const Divider(),
                  if (Platform.isAndroid)
                    const Row(
                      children: [
                        Text(
                          "Notifications",
                          style: TextStyle(fontSize: 24),
                        ),
                      ],
                    ),
                  if (Platform.isAndroid)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Daily Reminders",
                                  style: TextStyle(fontSize: 18),
                                ),
                                Text(
                                  "Allow app to run in background for best results",
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            Switch(
                                value: ConfigManager.instance
                                    .getField('dailyReminders'),
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
                          ],
                        ),
                        ElevatedButton.icon(
                            icon: const Icon(Icons.schedule_rounded),
                            onPressed: () async {
                              _selectTime(context);
                            },
                            label: Text(TimeManager.timeOfDayString(
                                TimeManager.scheduledReminderTime()))),
                      ],
                    ),
                  if (Platform.isAndroid) const Divider(),
                  const Row(
                    children: [
                      Text(
                        "Templates",
                        style: TextStyle(fontSize: 24),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Default Template",
                              style: TextStyle(fontSize: 18),
                            ),
                            if (!isLoading)
                              SizedBox(
                                width: 200,
                                child: DropdownButton<int>(
                                  underline: Container(),
                                  isDense: true,
                                  isExpanded: true,
                                  borderRadius: BorderRadius.circular(20),
                                  padding: const EdgeInsets.only(
                                      left: 8, right: 4, top: 4, bottom: 4),
                                  hint: const Text('Select a template'),
                                  value: ConfigManager.instance
                                      .getField("defaultTemplate"),
                                  items: _buildDefaultTemplateDropdownItems(),
                                  onChanged: (int? newValue) {
                                    setState(() {
                                      ConfigManager.instance.setField(
                                          "defaultTemplate", newValue);
                                    });
                                  },
                                ),
                              ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.edit_document),
                                label: const Text("Manage Templates"),
                                onPressed: () {
                                  _showTemplateManagementPopup(context);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  const Row(
                    children: [
                      Text(
                        "Storage",
                        style: TextStyle(fontSize: 24),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Log Folder",
                          style: TextStyle(fontSize: 18),
                        ),
                        FutureBuilder(
                            future:
                                EntriesDatabase.instance.getInternalDbPath(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data != null) {
                                if (EntriesDatabase.instance
                                    .usingExternalDb()) {
                                  return Text(ConfigManager.instance
                                      .getField('externalDbUri'));
                                }
                                return Text(snapshot.data!);
                              }
                              return const Text("...");
                            }),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(
                                Icons.folder_copy_rounded,
                              ),
                              label: const Text("Change Log Folder..."),
                              onPressed: () async {
                                if (Platform.isAndroid &&
                                    !await requestStoragePermission()) {
                                  return;
                                }
                                await _showChangeLogFolderWarning(context);
                              },
                            ),
                            IconButton(
                                onPressed: () async {
                                  EntriesDatabase.instance
                                      .resetDatabaseLocation();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.refresh_rounded))
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Image Folder",
                          style: TextStyle(fontSize: 18),
                        ),
                        FutureBuilder(
                            future: EntriesDatabase.instance
                                .getInternalImgDatabasePath(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data != null) {
                                if (EntriesDatabase.instance
                                    .usingExternalImg()) {
                                  return Text(ConfigManager.instance
                                      .getField('externalImgUri'));
                                }
                                return Text(snapshot.data!);
                              }
                              return const Text("...");
                            }),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(
                                Icons.folder_copy_rounded,
                              ),
                              label: const Text("Change Image Folder..."),
                              onPressed: () async {
                                if (Platform.isAndroid &&
                                    !await requestPhotosPermission()) {
                                  return;
                                }
                                await _showChangeImgFolderWarning(context);
                              },
                            ),
                            IconButton(
                                onPressed: () async {
                                  setState(() {
                                    EntriesDatabase.instance
                                        .resetImageFolderLocation();
                                  });
                                },
                                icon: const Icon(Icons.refresh_rounded))
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Export",
                          style: TextStyle(fontSize: 18),
                        ),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(
                                Icons.upload_rounded,
                              ),
                              label: const Text("Export Logs..."),
                              onPressed: () async {
                                if (Platform.isAndroid &&
                                    !await requestStoragePermission()) {
                                  return;
                                }
                                _showExportSelectionPopup();
                              },
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(
                                Icons.photo,
                              ),
                              label: const Text("Export Images..."),
                              onPressed: () async {
                                if (Platform.isAndroid &&
                                    !await requestPhotosPermission()) {
                                  return;
                                }
                                await EntriesDatabase.instance.exportImages();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Import",
                          style: TextStyle(fontSize: 18),
                        ),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(
                                Icons.download_rounded,
                              ),
                              label: const Text("Import Logs..."),
                              onPressed: () async {
                                if (Platform.isAndroid &&
                                    !await requestStoragePermission()) {
                                  return;
                                }
                                _showImportSelectionPopup();
                              },
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(
                                Icons.photo,
                              ),
                              label: const Text("Import Images..."),
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
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Delete All",
                          style: TextStyle(fontSize: 18),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(
                            Icons.delete_forever_rounded,
                          ),
                          label: const Text("Delete All Logs..."),
                          onPressed: () async {
                            _showDeleteEntriesPopup();
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  const Row(
                    children: [
                      Text(
                        "About",
                        style: TextStyle(fontSize: 24),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Version",
                          style: TextStyle(fontSize: 18),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(
                            Icons.new_releases_rounded,
                          ),
                          label: const Text("2.4.0"),
                          onPressed: () async {
                            await launchUrl(
                                Uri.https(
                                    "github.com", "/Demizo/Daily_You/releases"),
                                mode: LaunchMode.externalApplication);
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "License",
                          style: TextStyle(fontSize: 18),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.gavel_rounded),
                          label: const Text("GPL v3"),
                          onPressed: () async {
                            await launchUrl(
                                Uri.https("github.com",
                                    "/Demizo/Daily_You/blob/master/LICENSE.txt"),
                                mode: LaunchMode.externalApplication);
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Source Code",
                          style: TextStyle(fontSize: 18),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(
                            Icons.code_rounded,
                          ),
                          label: const Text("Github"),
                          onPressed: () async {
                            await launchUrl(
                                Uri.https("github.com", "/Demizo/Daily_You"),
                                mode: LaunchMode.externalApplication);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
