// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/storage/external_sync.dart';
import 'package:daily_you/storage/external_sync_settings.dart';
import 'package:daily_you/storage/storage_picker.dart';
import 'package:daily_you/storage/sync_progress.dart';
import 'package:daily_you/utils/operation_outcome.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/database_overwrite_dialog.dart';
import 'package:daily_you/widgets/external_sync_dialog.dart';
import 'package:daily_you/widgets/failure_dialog.dart';
import 'package:daily_you/widgets/sync_progress_dialog.dart';
import 'package:material_ui/material_ui.dart';

abstract final class ExternalSyncFlow {
  static Future<void> edit(BuildContext context,
      {ExternalSyncSettings? draft}) async {
    final saved = ExternalSyncSettings.load();
    final desired = await showAppDialog<ExternalSyncSettings>(
        context: context,
        builder: (_) => ExternalSyncDialog(initial: saved, draft: draft));
    if (desired != null && context.mounted) {
      await _apply(context, saved, desired);
    }
  }

  static Future<void> toggle(BuildContext context, bool enabled) async {
    if (!enabled) {
      await _apply(
          context, ExternalSyncSettings.load(), const ExternalSyncSettings());
      return;
    }

    final uri = (await StoragePicker.pickDirectoryWithAccess())?.uri;
    if (uri == null || !context.mounted) return;
    if (!await confirmDatabaseOverwrite(context, uri)) return;
    if (!context.mounted) return;
    await edit(context, draft: ExternalSyncSettings.withDefaults(uri));
  }

  static Future<void> _apply(BuildContext context, ExternalSyncSettings saved,
      ExternalSyncSettings desired) async {
    final sync = ExternalSync(saved, desired);
    if (!sync.hasWork) {
      await sync.run((_) {});
      return;
    }

    final navigator = Navigator.of(context);
    final progress = ValueNotifier(SyncProgress(sync.items.first));
    showSyncProgressDialog(context, progress);
    final OperationOutcome outcome;
    try {
      outcome = await sync.run((value) => progress.value = value);
    } finally {
      navigator.pop();
    }
    if (!context.mounted) return;

    if (outcome.failed) {
      await showFailureDialog(context,
          description: AppLocalizations.of(context)!.syncErrorDescription,
          error: outcome.error);
    }
  }
}
