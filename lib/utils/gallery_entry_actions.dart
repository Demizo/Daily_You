// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/gallery_selection.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/utils/backup_restore_utils.dart';
import 'package:daily_you/utils/bulk_tag_editor.dart';
import 'package:daily_you/utils/exports/export_runner.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/delete_confirm_dialog.dart';
import 'package:daily_you/widgets/export_format_dialog.dart';
import 'package:daily_you/widgets/failure_dialog.dart';
import 'package:daily_you/widgets/gallery_action_menu.dart';
import 'package:daily_you/widgets/icons/svg_icon.dart';
import 'package:daily_you/widgets/partial_matches_dialog.dart';
import 'package:daily_you/widgets/tag_picker_dialog.dart';
import 'package:material_ui/material_ui.dart';

Future<void> exportEntries(
  BuildContext context,
  List<Entry> entries, {
  ExportDestination destination = ExportDestination.folder,
}) async {
  final option = await showExportFormatDialog(context, showWarning: false);
  if (option == null || !context.mounted) return;

  final outcome = await BackupRestoreUtils.runWithLoadingStatus(
      context,
      (updateStatus) => runExport(context, updateStatus,
          option: option, entries: entries, destination: destination));
  if (!context.mounted || !outcome.failed) return;

  await showFailureDialog(context,
      description: AppLocalizations.of(context)!.exportErrorDescription,
      error: outcome.error);
}

Future<void> editEntryTags(
  BuildContext context,
  List<Entry> entries,
  TagChange change,
) async {
  final entryIds = {for (final entry in entries) entry.id!};
  final editor = BulkTagEditor(
    change,
    entryIds.length,
    TagsProvider.instance.tagPresenceFor(entryIds),
  );
  try {
    final applied = await showAppDialog<bool>(
      context: context,
      builder: (_) =>
          TagPickerDialog(mode: TagPickerMode.bulkEdit, editor: editor),
    );
    if (!(applied ?? false)) return;
    await TagsProvider.instance.applyTagChanges(
      entryIds,
      additions: editor.additions,
      removals: editor.removals,
    );
  } finally {
    editor.dispose();
  }
}

Future<void> selectAllEntries(
  BuildContext context,
  GallerySelection selection,
) async {
  if (!selection.offersPartialMatches) {
    selection.selectAll();
    return;
  }
  final includePartial = await showPartialMatchesDialog(
    context,
    partialMatchCount: selection.partialMatchCount,
  );
  if (includePartial == null) return;
  selection.selectAll(includePartial: includePartial);
}

Future<bool> deleteEntries(BuildContext context, List<Entry> entries) async {
  final confirmed = await showDeleteConfirmDialog(context,
      message: AppLocalizations.of(context)!.deleteLogsMessage(entries.length));
  if (!confirmed) return false;
  await EntriesProvider.instance.deleteMany(entries);
  return true;
}

Future<void> deleteSelectedEntries(
  BuildContext context,
  GallerySelection selection,
) async {
  if (await deleteEntries(context, selection.selectedEntries)) {
    selection.clear();
  }
}

GalleryAction? shareSelectionAction(
  BuildContext context,
  GallerySelection selection,
) {
  if (!Platform.isAndroid) return null;
  return GalleryAction(
    label: AppLocalizations.of(context)!.shareButtonLabel,
    icon: const Icon(Icons.share_rounded),
    onPressed: () => exportEntries(context, selection.selectedEntries,
        destination: ExportDestination.shareSheet),
  );
}

List<GalleryAction> selectionActions(
  BuildContext context,
  GallerySelection selection,
) {
  final l10n = AppLocalizations.of(context)!;
  return [
    GalleryAction(
      label: l10n.settingsExport,
      icon: const Icon(Icons.file_download_outlined),
      onPressed: () => exportEntries(context, selection.selectedEntries),
    ),
    GalleryAction(
      label: l10n.addTagsTitle,
      icon: const SvgIcon('assets/icons/tag_add.svg'),
      onPressed: () =>
          editEntryTags(context, selection.selectedEntries, TagChange.add),
    ),
    GalleryAction(
      label: l10n.removeTagsTitle,
      icon: const SvgIcon('assets/icons/tag_remove.svg'),
      onPressed: () =>
          editEntryTags(context, selection.selectedEntries, TagChange.remove),
    ),
    GalleryAction(
      label: l10n.deleteTitle,
      icon: const Icon(Icons.delete_rounded),
      onPressed: () => deleteSelectedEntries(context, selection),
    ),
  ];
}
