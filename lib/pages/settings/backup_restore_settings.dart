import 'package:daily_you/backup_restore_utils.dart';
import 'package:daily_you/import_utils.dart';
import 'package:daily_you/widgets/settings_icon_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BackupRestoreSettings extends StatefulWidget {
  const BackupRestoreSettings({super.key});

  @override
  State<BackupRestoreSettings> createState() => _BackupRestoreSettingsState();
}

class _BackupRestoreSettingsState extends State<BackupRestoreSettings> {
  @override
  void initState() {
    super.initState();
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
                  title: Text(AppLocalizations.of(context)!.formatDiarium),
                  onTap: () {
                    chosenFormat = ImportFormat.diarium;
                    Navigator.of(context).pop();
                  }),
              ListTile(
                  title: Text(AppLocalizations.of(context)!.formatMyBrain),
                  onTap: () {
                    chosenFormat = ImportFormat.myBrain;
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

      BackupRestoreUtils.showLoadingStatus(context, statusNotifier);

      if (chosenFormat == ImportFormat.dailyYouJson) {
        await ImportUtils.importFromJson((status) {
          statusNotifier.value = status;
        });
      } else if (chosenFormat == ImportFormat.diarium) {
        await ImportUtils.importFromDiarium(context, (status) {
          statusNotifier.value = status;
        });
      } else if (chosenFormat == ImportFormat.myBrain) {
        await ImportUtils.importFromMyBrain((status) {
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

  Future<void> _backupData(BuildContext context) async {
    ValueNotifier<String> statusNotifier = ValueNotifier<String>("");

    BackupRestoreUtils.showLoadingStatus(context, statusNotifier);

    bool success = await BackupRestoreUtils.backupToZip(context, (status) {
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

    BackupRestoreUtils.showLoadingStatus(context, statusNotifier);

    bool success = await BackupRestoreUtils.restoreFromZip(context, (status) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settingsBackupRestoreTitle),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          SettingsIconAction(
              title: AppLocalizations.of(context)!.settingsImportFromAnotherApp,
              icon: Icon(Icons.download_rounded),
              onPressed: () async {
                await _showImportSelectionPopup();
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
        ],
      ),
    );
  }
}
