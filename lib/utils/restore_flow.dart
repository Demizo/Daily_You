// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/utils/backup_restore_utils.dart';
import 'package:daily_you/utils/operation_outcome.dart';
import 'package:daily_you/widgets/failure_dialog.dart';
import 'package:daily_you/widgets/settings_dialog.dart';
import 'package:daily_you/widgets/settings_rows.dart';
import 'package:material_ui/material_ui.dart';

abstract final class RestoreFlow {
  static Future<OperationOutcome> run(BuildContext context) async {
    final loadingStatus = LoadingStatusDialog(context);

    final OperationOutcome outcome;
    try {
      outcome = await BackupRestoreUtils.restoreFromZip(
          context, loadingStatus.update, onFilePicked: loadingStatus.show,
          confirm: (fileName, entryCount) async {
        if (!context.mounted) return false;
        final confirmed = await loadingStatus
            .whileHidden(() => _confirm(context, fileName, entryCount));
        return confirmed && context.mounted;
      });
    } finally {
      loadingStatus.dispose();
    }

    if (context.mounted && outcome.failed) {
      await showFailureDialog(context,
          description: AppLocalizations.of(context)!.restoreErrorDescription,
          error: outcome.error);
    }
    return outcome;
  }

  static Future<bool> _confirm(
      BuildContext context, String fileName, int entryCount) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showSettingsDialog<bool>(
      context: context,
      builder: (context) => [
        SettingsInfoRow(
          title: fileName,
          subtitle: Text(l10n.logCount(entryCount)),
        ),
        SettingsInfoRow(
          title: l10n.warningTitle,
          subtitle: Text(l10n.settingsRestorePromptDescription),
        ),
      ],
      actions: (context) => [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.settingsRestore),
        ),
      ],
    );
    return confirmed ?? false;
  }
}
