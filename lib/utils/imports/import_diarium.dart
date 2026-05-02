import 'dart:io';
import 'dart:typed_data';

import 'package:daily_you/database/image_storage.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
import 'package:daily_you/utils/file_layer.dart';
import 'package:daily_you/utils/imports/import_helpers.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:html2md/html2md.dart' as html2md;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

Future<bool> importFromDiarium(
    BuildContext context, Function(String) updateStatus) async {
  updateStatus("0%");

  var tempDir = await getTemporaryDirectory();
  const tempDbName = "temp_diarium.db";
  Database? db;
  bool success = true;

  try {
    final dbPath = await FileLayer.pickFile();
    if (dbPath == null) return false;

    updateStatus(AppLocalizations.of(context)!.tranferStatus("0"));
    await FileLayer.copyFromExternalLocation(dbPath, tempDir.path, tempDbName,
        onProgress: (percent) {
      updateStatus(
          AppLocalizations.of(context)!.tranferStatus("${percent.round()}"));
    });

    db = await openDatabase(join(tempDir.path, tempDbName), readOnly: true);
    final entries = await db.rawQuery('SELECT * FROM Entries');
    final media = await db.rawQuery('SELECT * FROM Media WHERE Type = 0');

    final Map<int, DateTime> idToTimestamp = {};
    for (final entry in entries) {
      final id = entry['DiaryEntryId'] as int;
      idToTimestamp[id] = diariumIdToDateTime(id);
    }

    final mediaByEntryId = <int, List<Map<String, Object?>>>{};
    for (final item in media) {
      final entryId = item['DiaryEntryId'] as int;
      mediaByEntryId.putIfAbsent(entryId, () => []).add(item);
    }

    // Sort entries chronologically
    final sortedEntries = List<Map<String, Object?>>.from(entries)
      ..sort((a, b) =>
          (a['DiaryEntryId'] as int).compareTo(b['DiaryEntryId'] as int));

    final totalEntries = sortedEntries.length;
    int processedEntries = 0;

    for (final entry in sortedEntries) {
      final id = entry['DiaryEntryId'] as int;
      final timestamp = idToTimestamp[id]!;

      final heading = entry['Heading'] as String? ?? '';
      var body = entry['Text'] as String? ?? '';
      if (body.isNotEmpty) {
        body = html2md.convert(body);
      }

      final rating = entry['Rating'] as int?;
      final mood = rating != null ? rating.clamp(1, 5) - 3 : null;

      final parts = <String>[];
      if (heading.isNotEmpty) parts.add("# $heading");
      if (body.isNotEmpty) parts.add(body);

      if (!EntriesProvider.instance.hasEntryAtTimestamp(timestamp)) {
        final addedEntry = await EntriesProvider.instance.add(
            Entry(
              text: parts.join('\n\n'),
              mood: mood,
              timeCreate: timestamp,
              timeModified: timestamp,
            ),
            skipUpdate: true);

        final entryMedia = mediaByEntryId[id] ?? [];
        for (final img in entryMedia) {
          final data = img['Data'] as Uint8List?;
          final rank = entryMedia.length - 1 - (img['Index'] as int? ?? 0);
          if (data != null) {
            final newImage = await ImageStorage.instance.create(
              null,
              data,
              currTime: timestamp,
            );
            if (newImage != null) {
              await EntryImagesProvider.instance.add(
                  EntryImage(
                    id: null,
                    entryId: addedEntry.id!,
                    imgPath: newImage,
                    imgRank: rank,
                    timeCreate: timestamp,
                  ),
                  skipUpdate: true);
            }
          }
        }
      }

      processedEntries++;
      updateStatus("${((processedEntries / totalEntries) * 100).round()}%");
    }
  } catch (e) {
    updateStatus("$e");
    await Future.delayed(const Duration(seconds: 5));
    success = false;
  }

  updateStatus(AppLocalizations.of(context)!.cleanUpStatus);

  await EntriesProvider.instance.load();
  await EntryImagesProvider.instance.load();

  if (db != null && db.isOpen) {
    await db.close();
  }

  if (await File(join(tempDir.path, tempDbName)).exists()) {
    await File(join(tempDir.path, tempDbName)).delete();
  }

  return success;
}
