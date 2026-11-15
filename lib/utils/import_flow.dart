// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/utils/backup_restore_utils.dart';
import 'package:daily_you/utils/imports/import_registry.dart';
import 'package:daily_you/utils/operation_outcome.dart';
import 'package:daily_you/widgets/failure_dialog.dart';
import 'package:daily_you/widgets/settings_dialog.dart';
import 'package:daily_you/widgets/settings_rows.dart';
import 'package:material_ui/material_ui.dart';

abstract final class ImportFlow {
  static Future<OperationOutcome> run(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final format = await showSettingsDialog<ImportFormat>(
      context: context,
      title: l10n.logFormatTitle,
      actions: (context) => [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
      ],
      builder: (context) => [
        SettingsInfoRow(
            title: l10n.warningTitle,
            subtitle: Text(l10n.logFormatDescription)),
        for (final option in ImportRegistry.instance.options)
          SettingsActionRow(
            title: option.name(l10n),
            onTap: () => Navigator.of(context).pop(option.format),
          ),
      ],
    );

    if (format == null || !context.mounted) {
      return const OperationOutcome.cancelled();
    }

    final outcome = await BackupRestoreUtils.runWithLoadingStatus(
        context,
        (updateStatus) => ImportRegistry.instance
            .optionFor(format)
            .run(context, updateStatus));

    if (context.mounted && outcome.failed) {
      await showFailureDialog(context,
          description: l10n.importErrorDescription, error: outcome.error);
    }
    return outcome;
  }
}
