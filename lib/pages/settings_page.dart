import 'dart:io';

import 'package:daily_you/notification_manager.dart';
import 'package:daily_you/time_manager.dart';
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
  Future<bool> requestStoragePermission() async {
    var hasPermission = false;

    //Legacy Permission
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    if (status.isGranted) {
      hasPermission = true;
    }

    //Modern Permission
    status = await Permission.manageExternalStorage.status;
    if (!status.isGranted && hasPermission == false) {
      status = await Permission.manageExternalStorage.request();
    }
    if (status.isGranted) {
      hasPermission = true;
    }

    return hasPermission;
  }

  void _showThemeSelectionPopup(ThemeModeProvider themeModeProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Theme:'),
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
          title: const Text('Choose Accent Color:'),
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
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(
                      Icons.check_circle_rounded,
                      size: 24,
                    ),
                    label: const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Text(
                        "Confirm",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    onPressed: () async {
                      setState(() {
                        themeProvider.accentColor = accentColor;
                        themeProvider.updateAccentColor();
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.background,
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
                      backgroundColor: Theme.of(context).colorScheme.background,
                      foregroundColor: Theme.of(context).colorScheme.primary,
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

  void _showMoodEmojiPopup(int? value) {
    String newEmoji = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Icon:'),
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
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(
                      Icons.check_circle_rounded,
                      size: 24,
                    ),
                    label: const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Text(
                        "Confirm",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
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
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.background,
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
                      backgroundColor: Theme.of(context).colorScheme.background,
                      foregroundColor: Theme.of(context).colorScheme.primary,
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
                    await EntriesDatabase.instance.importFromJson();
                    Navigator.pop(context);
                  }),
              ListTile(
                  title: const Text('OneShot'),
                  onTap: () async {
                    await EntriesDatabase.instance.importFromOneShot();
                    Navigator.pop(context);
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
                    await EntriesDatabase.instance.exportToJson();
                    Navigator.pop(context);
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
                      await EntriesDatabase.instance.deleteAllEntries();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      backgroundColor: Theme.of(context).colorScheme.background,
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
                      foregroundColor: Theme.of(context).colorScheme.background,
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeModeProvider>(context);
    return Scaffold(
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
                    await ConfigManager.instance.setField('theme', 'system');
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
                                ConfigManager.instance
                                    .setField('followSystemColor', value);
                                themeProvider.updateAccentColor();
                              });
                            })
                      ]),
                  if (!ConfigManager.instance.getField('followSystemColor'))
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
                  "Mood Icons",
                  style: TextStyle(fontSize: 18),
                ),
                Row(
                  children: [
                    moodIconButton(-2),
                    moodIconButton(-1),
                    moodIconButton(0),
                    moodIconButton(1),
                    moodIconButton(2),
                    moodIconButton(null),
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
                              ConfigManager.instance
                                  .setField('startingDayOfWeek', 'monday');
                            });
                          } else {
                            setState(() {
                              ConfigManager.instance
                                  .setField('startingDayOfWeek', 'sunday');
                            });
                          }
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Daily Reminders",
                          style: TextStyle(fontSize: 18),
                        ),
                        const Text(
                          "Allow app to run in background for best results",
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    Switch(
                        value:
                            ConfigManager.instance.getField('dailyReminders'),
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
                    future: EntriesDatabase.instance.getLogDatabasePath(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
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
                        bool locationSet = await EntriesDatabase.instance
                            .selectDatabaseLocation();
                        if (!locationSet) {
                          await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return const AlertDialog(
                                    title: Text("Error:"),
                                    content: Text(
                                        "Permission Denied: Log folder not changed!"));
                              });
                        }
                        setState(() {});
                      },
                    ),
                    IconButton(
                        onPressed: () async {
                          EntriesDatabase.instance.resetDatabaseLocation();
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
                    future: EntriesDatabase.instance.getImgDatabasePath(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
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
                            !await requestStoragePermission()) {
                          return;
                        }
                        bool locationSet =
                            await EntriesDatabase.instance.selectImageFolder();
                        if (!locationSet) {
                          await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return const AlertDialog(
                                    title: Text("Error:"),
                                    content: Text(
                                        "Permission Denied: Image folder not changed!"));
                              });
                        }
                        setState(() {});
                      },
                    ),
                    IconButton(
                        onPressed: () async {
                          setState(() {
                            EntriesDatabase.instance.resetImageFolderLocation();
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
                            !await requestStoragePermission()) {
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
                            !await requestStoragePermission()) {
                          return;
                        }
                        await EntriesDatabase.instance.importImages();
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
                  label: const Text("1.7.1"),
                  onPressed: () async {
                    await launchUrl(
                        Uri.https("github.com", "/Demizo/Daily_You/releases"),
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
    );
  }
}
