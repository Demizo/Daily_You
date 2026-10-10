// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:typed_data';

import 'package:daily_you/database/attachment_storage.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/utils/operation_outcome.dart';

class ImportedEntry {
  const ImportedEntry(this.entry, {this.attachments = const []});

  final Entry entry;
  final List<EntryAttachment> attachments;
}

Future<void> addImportedEntries(
    List<ImportedEntry> importedEntries, Function(String) updateStatus) async {
  final totalEntries = importedEntries.length;
  var processedEntries = 0;

  for (final imported in importedEntries) {
    if (!EntriesProvider.instance
        .hasEntryAtTimestamp(imported.entry.timeCreate)) {
      final addedEntry =
          await EntriesProvider.instance.add(imported.entry, skipUpdate: true);
      for (final attachment in imported.attachments) {
        await EntryAttachmentsProvider.instance
            .add(attachment.copy(entryId: addedEntry.id), skipUpdate: true);
      }
    }
    processedEntries += 1;
    updateStatus("${((processedEntries / totalEntries) * 100).round()}%");
  }
}

Future<void> addImportedImage(int entryId, Uint8List bytes, int rank,
    DateTime timeCreate, Set<String> takenNames) async {
  final filePath = await AttachmentStorage.instance.create(
      null, bytes, AttachmentType.image,
      currTime: timeCreate, skipExternalUpload: true, takenNames: takenNames);
  if (filePath == null) return;
  await EntryAttachmentsProvider.instance.add(
      EntryAttachment(
        entryId: entryId,
        type: AttachmentType.image,
        filePath: filePath,
        rank: rank,
        timeCreate: timeCreate,
      ),
      skipUpdate: true);
}

Future<OperationOutcome> finishImport(
    Function(String) updateStatus, OperationOutcome outcome) async {
  await EntriesProvider.instance.load();
  await EntryAttachmentsProvider.instance.load();
  if (AttachmentStorage.instance.usingExternalLocation()) {
    try {
      await AttachmentStorage.instance.syncAttachmentFolders(true,
          onProgress: (progress) => updateStatus(progress.counts ?? ''));
    } catch (error) {
      return outcome.failed ? outcome : OperationOutcome.failed(error);
    }
  }
  return outcome;
}

DateTime diariumIdToDateTime(int ticks) {
  const int ticksAtUnixEpoch = 621355968000000000;
  final usSinceEpoch = ((ticks - ticksAtUnixEpoch) / 10).round();
  // Wall-clock time the entry was written, with no zone attached
  final wallClock =
      DateTime.fromMicrosecondsSinceEpoch(usSinceEpoch, isUtc: true);
  return DateTime(
      wallClock.year,
      wallClock.month,
      wallClock.day,
      wallClock.hour,
      wallClock.minute,
      wallClock.second,
      wallClock.millisecond,
      wallClock.microsecond);
}

DateTime convertWithOffset(int millisUtc, String tzOffset) {
  final utc = DateTime.fromMillisecondsSinceEpoch(millisUtc, isUtc: true);
  final sign = tzOffset.startsWith('-') ? -1 : 1;
  final parts = tzOffset.substring(1).split(':');
  final hours = int.parse(parts[0]);
  final minutes = int.parse(parts[1]);
  final offsetDuration = Duration(
    hours: hours * sign,
    minutes: minutes * sign,
  );
  return utc.add(offsetDuration);
}

DateTime parseDaybookLocal(String s) {
  final match = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})-(\d{2}):(\d{2})$',
  ).firstMatch(s);

  if (match == null) {
    throw FormatException("Invalid Daybook date: $s");
  }

  return DateTime(
    int.parse(match[1]!),
    int.parse(match[2]!),
    int.parse(match[3]!),
    int.parse(match[4]!),
    int.parse(match[5]!),
  );
}
