import 'dart:io';
import 'package:daily_you/backup_restore_utils.dart';
import 'package:daily_you/config_provider.dart';
import 'package:daily_you/entries_database.dart';
import 'package:daily_you/stats_provider.dart';
import 'package:daily_you/widgets/settings_dropdown.dart';
import 'package:daily_you/widgets/settings_icon_action.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class StorageSettings extends StatefulWidget {
  const StorageSettings({super.key});

  @override
  State<StorageSettings> createState() => _StorageSettingsState();
}

class _StorageSettingsState extends State<StorageSettings> {
  bool isSyncing = false;

  @override
  void initState() {
    super.initState();
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

  Future<void> _deleteAllLogs(BuildContext context) async {
    ValueNotifier<String> statusNotifier = ValueNotifier<String>("");

    BackupRestoreUtils.showLoadingStatus(context, statusNotifier);

    await EntriesDatabase.instance.deleteAllEntries((status) {
      statusNotifier.value = status;
    });

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final statsProvider = Provider.of<StatsProvider>(context);
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
                  title:
                      Text(AppLocalizations.of(context)!.settingsStorageTitle),
                  centerTitle: true,
                ),
                body: ListView(
                  children: [
                    SettingsDropdown<int>(
                        title:
                            AppLocalizations.of(context)!.settingsImageQuality,
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
                              child: Text(AppLocalizations.of(context)!
                                  .imageQualityLow)),
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
                              title: AppLocalizations.of(context)!
                                  .settingsLogFolder,
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
                                EntriesDatabase.instance
                                    .resetDatabaseLocation();
                              },
                            );
                          }
                          return const SizedBox();
                        }),
                    FutureBuilder(
                        future: EntriesDatabase.instance
                            .getInternalImgDatabasePath(),
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
                        title: AppLocalizations.of(context)!
                            .settingsDeleteAllLogsTitle,
                        icon: Icon(Icons.delete_forever_rounded),
                        onPressed: () => _showDeleteAllLogsDialog(
                            context,
                            AppLocalizations.of(context)!
                                .settingsDeleteAllLogsTitle,
                            () => _deleteAllLogs(context))),
                  ],
                ),
              ));
  }
}
