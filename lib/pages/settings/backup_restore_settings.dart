import 'package:daily_you/utils/backup_restore_utils.dart';
import 'package:daily_you/utils/imports/import_registry.dart';
import 'package:daily_you/utils/export_utils.dart';
import 'package:daily_you/widgets/settings_icon_action.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';

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
    ImportFormat? chosenFormat;
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
              for (final option in ImportRegistry.instance.options)
                ListTile(
                    title: Text(option.name(AppLocalizations.of(context)!)),
                    onTap: () {
                      chosenFormat = option.format;
                      Navigator.of(context).pop();
                    }),
            ],
          ),
        );
      },
    );

    final format = chosenFormat;
    if (format == null) return;
    if (!mounted) return;

    ValueNotifier<String> statusNotifier = ValueNotifier<String>("");

    BackupRestoreUtils.showLoadingStatus(context, statusNotifier);

    await ImportRegistry.instance.optionFor(format).run(context, (status) {
      statusNotifier.value = status;
    });

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _showExportSelectionPopup() async {
    ExportFormat chosenFormat = ExportFormat.none;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.logFormatTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!
                  .settingsExportFormatDescription),
              Divider(),
              ListTile(
                  title: Text(AppLocalizations.of(context)!.formatMarkdown),
                  onTap: () {
                    chosenFormat = ExportFormat.markdown;
                    Navigator.of(context).pop();
                  }),
            ],
          ),
        );
      },
    );

    if (chosenFormat != ExportFormat.none) {
      if (!mounted) return;
      ValueNotifier<String> statusNotifier = ValueNotifier<String>("");

      BackupRestoreUtils.showLoadingStatus(context, statusNotifier);

      if (chosenFormat == ExportFormat.markdown) {
        await ExportUtils.exportToMarkdown(context, (status) {
          statusNotifier.value = status;
        });
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  Future<void> _backupData(BuildContext context) async {
    ValueNotifier<String> statusNotifier = ValueNotifier<String>("");

    BackupRestoreUtils.showLoadingStatus(context, statusNotifier);

    bool success = await BackupRestoreUtils.backupToZip(context, (status) {
      statusNotifier.value = status;
    });

    if (!context.mounted) return;
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

    if (!context.mounted) return;
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
      if (!mounted) return;
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
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            child: Divider(),
          ),
          SettingsIconAction(
              title: AppLocalizations.of(context)!.settingsImportFromAnotherApp,
              icon: Icon(Icons.download_rounded),
              onPressed: () async {
                await _showImportSelectionPopup();
              }),
          SettingsIconAction(
              title:
                  AppLocalizations.of(context)!.settingsExportToAnotherFormat,
              icon: Icon(Icons.upload_rounded),
              onPressed: () async {
                await _showExportSelectionPopup();
              }),
        ],
      ),
    );
  }
}
