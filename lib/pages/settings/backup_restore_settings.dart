// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/utils/backup_restore_utils.dart';
import 'package:daily_you/utils/restore_flow.dart';
import 'package:daily_you/widgets/backup_rows.dart';
import 'package:daily_you/utils/import_flow.dart';
import 'package:daily_you/utils/exports/export_runner.dart';
import 'package:daily_you/widgets/export_format_dialog.dart';
import 'package:daily_you/widgets/failure_dialog.dart';
import 'package:daily_you/widgets/segmented_group.dart';
import 'package:daily_you/widgets/settings_rows.dart';
import 'package:daily_you/widgets/settings_page_scaffold.dart';
import 'package:material_ui/material_ui.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class BackupRestoreSettings extends StatefulWidget {
  const BackupRestoreSettings({super.key});

  @override
  State<BackupRestoreSettings> createState() => _BackupRestoreSettingsState();
}

class _BackupRestoreSettingsState extends State<BackupRestoreSettings> {
  Future<void> _showExportSelectionPopup() async {
    final option = await showExportFormatDialog(context);
    if (option == null) return;
    if (!mounted) return;

    final outcome = await BackupRestoreUtils.runWithLoadingStatus(context,
        (updateStatus) => runExport(context, updateStatus, option: option));

    if (!mounted) return;

    if (outcome.failed) {
      await showFailureDialog(context,
          description: AppLocalizations.of(context)!.exportErrorDescription,
          error: outcome.error);
    }
  }

  Future<void> _backupData(BuildContext context) async {
    final outcome = await BackupRestoreUtils.runWithLoadingStatus(
        context,
        (updateStatus) =>
            BackupRestoreUtils.backupToZip(context, updateStatus));

    if (!context.mounted) return;

    if (outcome.failed) {
      await showFailureDialog(context,
          description: AppLocalizations.of(context)!.backupErrorDescription,
          error: outcome.error);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final configProvider = Provider.of<ConfigProvider>(context);

    return SettingsPageScaffold(
      title: l10n.settingsBackupRestoreTitle,
      children: [
        SegmentedGroup(children: [
          SettingsActionRow(
            icon: Icons.backup_rounded,
            title: l10n.settingsBackup,
            subtitle: _lastBackupText(configProvider.get(Settings.lastBackup)),
            onTap: () => _backupData(context),
          ),
          if (Platform.isAndroid) BackupRows.autoBackup(context),
          BackupRows.passwordProtect(context),
          SettingsActionRow(
            icon: Icons.restore_rounded,
            title: l10n.settingsRestore,
            onTap: () => RestoreFlow.run(context),
          ),
        ]),
        SegmentedGroup(children: [
          SettingsActionRow(
            icon: Icons.download_rounded,
            title: l10n.settingsImportFromAnotherApp,
            onTap: () => ImportFlow.run(context),
          ),
          SettingsActionRow(
            icon: Icons.upload_rounded,
            title: l10n.settingsExportToAnotherFormat,
            onTap: _showExportSelectionPopup,
          ),
        ]),
      ],
    );
  }
}
