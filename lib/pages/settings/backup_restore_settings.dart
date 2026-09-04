import 'package:daily_you/config_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/utils/backup_restore_utils.dart';
import 'package:daily_you/utils/imports/import_registry.dart';
import 'package:daily_you/utils/export_utils.dart';
import 'package:daily_you/utils/operation_outcome.dart';
import 'package:daily_you/utils/password_store.dart';
import 'package:daily_you/widgets/auth_popup.dart';
import 'package:daily_you/widgets/failure_dialog.dart';
import 'package:daily_you/widgets/settings_icon_action.dart';
import 'package:daily_you/widgets/settings_toggle.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

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

    final outcome =
        await ImportRegistry.instance.optionFor(format).run(context, (status) {
      statusNotifier.value = status;
    });

    if (!mounted) return;
    Navigator.of(context).pop();

    if (outcome.failed) {
      await showFailureDialog(context,
          description: AppLocalizations.of(context)!.importErrorDescription,
          error: outcome.error);
    }
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

    if (chosenFormat == ExportFormat.none) return;
    if (!mounted) return;

    ValueNotifier<String> statusNotifier = ValueNotifier<String>("");

    BackupRestoreUtils.showLoadingStatus(context, statusNotifier);

    var outcome = const OperationOutcome.cancelled();
    if (chosenFormat == ExportFormat.markdown) {
      outcome = await ExportUtils.exportToMarkdown(context, (status) {
        statusNotifier.value = status;
      });
    }

    if (!mounted) return;
    Navigator.of(context).pop();

    if (outcome.failed) {
      await showFailureDialog(context,
          description: AppLocalizations.of(context)!.exportErrorDescription,
          error: outcome.error);
    }
  }

  Future<void> _backupData(BuildContext context) async {
    ValueNotifier<String> statusNotifier = ValueNotifier<String>("");

    BackupRestoreUtils.showLoadingStatus(context, statusNotifier);

    final outcome = await BackupRestoreUtils.backupToZip(context, (status) {
      statusNotifier.value = status;
    });

    if (!context.mounted) return;
    Navigator.of(context).pop();

    if (outcome.failed) {
      await showFailureDialog(context,
          description: AppLocalizations.of(context)!.backupErrorDescription,
          error: outcome.error);
    }
  }

  Future<void> _restoreData(BuildContext context) async {
    ValueNotifier<String> statusNotifier = ValueNotifier<String>("");

    BackupRestoreUtils.showLoadingStatus(context, statusNotifier);

    final outcome = await BackupRestoreUtils.restoreFromZip(context, (status) {
      statusNotifier.value = status;
    });

    if (!context.mounted) return;
    Navigator.of(context).pop();

    if (outcome.failed) {
      await showFailureDialog(context,
          description: AppLocalizations.of(context)!.restoreErrorDescription,
          error: outcome.error);
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

  String _lastBackupText(String lastBackup) {
    final time = DateTime.tryParse(lastBackup);
    if (time == null) {
      return AppLocalizations.of(context)!.settingsBackupNever;
    }
    return AppLocalizations.of(context)!
        .settingsBackupLast(_dateTimeText(time));
  }

  String _dateTimeText(DateTime time) =>
      "${TimeManager.formatDate(time, context)} "
      "${TimeManager.timeOfDayString(context, TimeOfDay.fromDateTime(time))}";

  Future<void> _showBackupPasswordDialog(String title) async {
    await showDialog(
        context: context,
        builder: (context) => AuthPopup(
              mode: AuthPopupMode.setPassword,
              title: title,
              showBiometrics: false,
              dismissable: true,
              store: const BackupPasswordStore(),
            ));
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<ConfigProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settingsBackupRestoreTitle),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          SettingsIconAction(
              title: AppLocalizations.of(context)!.settingsBackup,
              hint: _lastBackupText(configProvider.get(Settings.lastBackup)),
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
          SettingsToggle(
            title: AppLocalizations.of(context)!.settingsBackupPasswordProtect,
            setting: Settings.backupPasswordEnabled,
            secondaryIcon: configProvider.get(Settings.backupPasswordEnabled)
                ? Icon(Icons.edit_rounded)
                : null,
            onSecondaryPressed: () async => _showBackupPasswordDialog(
                AppLocalizations.of(context)!.settingsSecurityChangePassword),
            onChanged: (value) async {
              if (value) {
                await _showBackupPasswordDialog(
                    AppLocalizations.of(context)!.settingsSecuritySetPassword);
                await configProvider.set(Settings.backupPasswordEnabled,
                    BackupPasswordStore.password.isNotEmpty);
              } else {
                await configProvider.set(Settings.backupPassword, "");
                await configProvider.set(
                    Settings.backupPasswordEnabled, false);
              }
            },
          ),
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
