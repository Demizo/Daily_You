// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:typed_data';

import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/mood.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/utils/imports/import_bundle.dart';
import 'package:daily_you/utils/imports/import_source.dart';
import 'package:daily_you/utils/imports/import_text.dart';
import 'package:daily_you/utils/imports/import_time.dart';
import 'package:daily_you/utils/tag_name_sanitizer.dart';
import 'package:html2md/html2md.dart' as html2md;
import 'package:sqflite/sqflite.dart';

const int _labelTagType = 0;
const int _numericTrackerType = 2;
const int _ticksAtUnixEpoch = 621355968000000000;

Future<ImportBundle> parseDiarium(ImportSource source) async {
  final database = await openDatabase(source.file.path, readOnly: true);
  try {
    final entries = await database.rawQuery('SELECT * FROM Entries');
    final media = await database.rawQuery('SELECT * FROM Media WHERE Type = 0');
    final tags = await database.rawQuery('SELECT * FROM Tags');
    final entryTags = await database.rawQuery('SELECT * FROM EntryTags');

    final tagDefinitionById = <int, ImportedTagDefinition>{};
    for (final tag in tags) {
      final tagType = switch (tag['Type']) {
        _labelTagType => TagType.label,
        _numericTrackerType => TagType.tracker,
        _ => null,
      };
      final name = sanitizeTagName((tag['Value'] as String?) ?? '');
      if (tagType == null || name.isEmpty) continue;
      tagDefinitionById[tag['DiaryTagId'] as int] = ImportedTagDefinition(
        name: name,
        tagType: tagType,
        color: _parseColor(tag['Color'] as String?),
      );
    }

    final mediaByEntryId = _groupByEntryId(media);
    final entryTagsByEntryId = _groupByEntryId(entryTags);

    final sortedEntries = [...entries]..sort((a, b) =>
        (a['DiaryEntryId'] as int).compareTo(b['DiaryEntryId'] as int));

    return ImportBundle(
      tagDefinitions: tagDefinitionById.values.toList(),
      entries: [
        for (final entry in sortedEntries)
          _parseEntry(
            entry,
            mediaByEntryId[entry['DiaryEntryId']] ?? const [],
            entryTagsByEntryId[entry['DiaryEntryId']] ?? const [],
            tagDefinitionById,
          ),
      ],
    );
  } finally {
    await database.close();
  }
}

Map<int, List<Map<String, Object?>>> _groupByEntryId(
    List<Map<String, Object?>> rows) {
  final grouped = <int, List<Map<String, Object?>>>{};
  for (final row in rows) {
    grouped.putIfAbsent(row['DiaryEntryId'] as int, () => []).add(row);
  }
  return grouped;
}

ImportedEntry _parseEntry(
  Map<String, Object?> entry,
  List<Map<String, Object?>> media,
  List<Map<String, Object?>> entryTags,
  Map<int, ImportedTagDefinition> tagDefinitionById,
) {
  final timeCreate = _timeOfEntryId(entry['DiaryEntryId'] as int);
  final body = entry['Text'] as String? ?? '';
  final rating = entry['Rating'] as int?;

  return ImportedEntry(
    Entry(
      text: titledText(entry['Heading'] as String?,
          body.isEmpty ? null : html2md.convert(body)),
      mood: rating == null ? null : Mood.fromRating(rating),
      timeCreate: timeCreate,
      timeModified: timeCreate,
    ),
    tags: entryTags
        .map((entryTag) => _parseEntryTag(entryTag, tagDefinitionById))
        .nonNulls
        .toList(),
    attachments: _imageAttachments(media, timeCreate),
  );
}

List<ImportedAttachment> _imageAttachments(
    List<Map<String, Object?>> media, DateTime timeCreate) {
  final images = [
    for (final item in media)
      if (item['Data'] != null) item
  ];
  int mediaIndex(int imagePosition) =>
      images[imagePosition]['Index'] as int? ?? 0;

  final orderedPositions = List.generate(images.length, (position) => position)
    ..sort((a, b) {
      final byIndex = mediaIndex(a).compareTo(mediaIndex(b));
      return byIndex != 0 ? byIndex : a.compareTo(b);
    });

  return [
    for (final (rankFromEnd, imagePosition) in orderedPositions.indexed)
      ImportedAttachment(
        type: AttachmentType.image,
        rank: images.length - 1 - rankFromEnd,
        timeCreate: timeCreate,
        media: BytesMedia(images[imagePosition]['Data'] as Uint8List),
      ),
  ];
}

ImportedEntryTag? _parseEntryTag(Map<String, Object?> entryTag,
    Map<int, ImportedTagDefinition> tagDefinitionById) {
  final definition = tagDefinitionById[entryTag['DiaryTagId']];
  if (definition == null) return null;

  String? value;
  if (definition.tagType == TagType.tracker) {
    value = (entryTag['TrackingValue'] as String?)?.trim();
    if (!(double.tryParse(value ?? '')?.isFinite ?? false)) return null;
  }
  return ImportedEntryTag(
      name: definition.name, tagType: definition.tagType, value: value);
}

DateTime _timeOfEntryId(int ticks) =>
    wallClockOf(DateTime.fromMicrosecondsSinceEpoch(
        ((ticks - _ticksAtUnixEpoch) / 10).round(),
        isUtc: true));

int? _parseColor(String? hex) {
  if (hex == null || !RegExp(r'^#[0-9a-fA-F]{8}$').hasMatch(hex)) return null;
  return int.parse(hex.substring(1), radix: 16);
}
