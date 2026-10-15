// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:convert';
import 'dart:io';

import 'package:daily_you/database/attachment_storage.dart';
import 'package:daily_you/storage/file_store.dart';
import 'package:daily_you/storage/local_file_store.dart';
import 'package:daily_you/storage/storage_picker.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/utils/operation_outcome.dart';
import 'package:daily_you/utils/zip_utils.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/attachment_type_presentation.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';

enum ExportFormat {
  none,
  markdown,
}

class ExportUtils {
  static Future<OperationOutcome> exportToMarkdown(
      BuildContext context, Function(String) updateStatus) async {
    final localizations = AppLocalizations.of(context)!;
    final locale = TimeManager.currentLocale(context);

    final includedTypes = await _pickIncludedTypes(context);
    if (includedTypes == null) return const OperationOutcome.cancelled();

    updateStatus("(1/2) 0%");

    PickedDirectory? exportFolder;
    try {
      exportFolder = await StoragePicker.pickDirectory();
    } catch (error) {
      return OperationOutcome.failed(error);
    }
    if (exportFolder == null) return const OperationOutcome.cancelled();

    var outcome = const OperationOutcome.succeeded();

    var tempDir = await getTemporaryDirectory();
    final tempExportFolder = Directory(join(tempDir.path, "logs"));
    await tempExportFolder.create(recursive: true);
    final exportedZipName =
        "daily_you_markdown_export_${DateTime.now().toIso8601String().replaceAll(':', '-')}.zip";

    final exportStore = LocalFileStore(tempExportFolder.path);

    try {
      final entries = EntriesProvider.instance.entries;
      final totalLogs = entries.length;
      int processedLogs = 0;
      final writer =
          MarkdownExportWriter(noteStore: exportStore, locale: locale);

      for (Entry entry in entries) {
        final attachments = <(EntryAttachment, String)>[];
        for (EntryAttachment attachment in EntryAttachmentsProvider.instance
            .getForEntry(entry)
            .where((attachment) => includedTypes.contains(attachment.type))) {
          final path = await AttachmentStorage.instance
              .getLocalPath(attachment.filePath, attachment.type);
          if (path != null) attachments.add((attachment, path));
        }

        await writer.write(entry, attachments);

        processedLogs++;
        updateStatus("(1/2) ${((processedLogs / totalLogs) * 100).round()}%");
      }

      final exportFolderName = basename(tempExportFolder.path);
      await ZipUtils.compress(join(tempDir.path, exportedZipName), [], [
        tempExportFolder.path
      ], filesByArchivePath: {
        for (final MapEntry(key: relativePath, value: sourcePath)
            in writer.attachmentSources.entries)
          '$exportFolderName/$relativePath': sourcePath
      }, onProgress: (percent) {
        updateStatus("(2/2) ${percent.round()}%");
      });

      // Save archive
      updateStatus(localizations.tranferStatus("0"));
      await exportFolder.copyFileInto(
          join(tempDir.path, exportedZipName), exportedZipName,
          mimeType: "application/zip", onProgress: (percent) {
        updateStatus(localizations.tranferStatus("${percent.round()}"));
      });
    } catch (error) {
      outcome = OperationOutcome.failed(error);
    }

    // Delete temp files
    updateStatus(localizations.cleanUpStatus);
    await File(join(tempDir.path, exportedZipName)).delete();
    if (await tempExportFolder.exists()) {
      await tempExportFolder.delete(recursive: true);
    }

    return outcome;
  }

  static Future<Set<AttachmentType>?> _pickIncludedTypes(
      BuildContext context) async {
    final included = {...AttachmentType.values};
    return showAppDialog<Set<AttachmentType>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setLocalState) => AlertDialog(
          title: Text(AppLocalizations.of(dialogContext)!.exportIncludeTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final type in AttachmentType.values)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: included.contains(type),
                  title: Text(type.label(AppLocalizations.of(dialogContext)!)),
                  onChanged: (value) => setLocalState(() {
                    if (value ?? false) {
                      included.add(type);
                    } else {
                      included.remove(type);
                    }
                  }),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                  MaterialLocalizations.of(dialogContext).cancelButtonLabel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, included),
              child: Text(AppLocalizations.of(dialogContext)!.settingsExport),
            ),
          ],
        ),
      ),
    );
  }
}

class MarkdownExportWriter {
  MarkdownExportWriter({required this.noteStore, required this.locale});

  final FileStore noteStore;
  final String locale;

  final Map<String, String> attachmentSources = {};

  final Map<String, int> _timestampCount = {};

  Future<void> write(
      Entry entry, List<(EntryAttachment, String)> attachments) async {
    final timestamp = DateFormat("yyyy-MM-dd", locale).format(entry.timeCreate);
    _timestampCount[timestamp] = (_timestampCount[timestamp] ?? 0) + 1;
    final index = _timestampCount[timestamp]!;
    final indexSuffix = index > 1 ? "_$index" : "";

    final noteBody = StringBuffer();
    for (final (attachment, sourcePath) in attachments) {
      final folderName = attachment.type.folderName;
      final prefix = attachment.type.name;
      final prettyName =
          "${prefix}_$timestamp${indexSuffix}_${attachment.rank}${extension(attachment.filePath)}";

      noteBody.writeln(attachment.type == AttachmentType.image
          ? '![]($folderName/$prettyName)'
          : '[$prettyName]($folderName/$prettyName)');

      attachmentSources['$folderName/$prettyName'] = sourcePath;
    }

    final moodText =
        entry.mood != null ? "${MoodIcon.getMoodIcon(entry.mood)} " : "";
    noteBody.writeln(
        "$moodText${DateFormat.yMMMEd(locale).format(entry.timeCreate)}\n${entry.text}");

    await noteStore.write(
        "log_$timestamp$indexSuffix.md", utf8.encode(noteBody.toString()));
  }
}
