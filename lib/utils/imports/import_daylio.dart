// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:convert';
import 'dart:io';

import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/mood.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/storage/local_file_store.dart';
import 'package:daily_you/utils/imports/import_bundle.dart';
import 'package:daily_you/utils/imports/import_source.dart';
import 'package:daily_you/utils/imports/import_text.dart';
import 'package:daily_you/utils/imports/import_time.dart';
import 'package:daily_you/utils/tag_name_sanitizer.dart';
import 'package:html2md/html2md.dart' as html2md;
import 'package:path/path.dart';

Future<ImportBundle> parseDaylio(ImportSource source) async {
  final backupName = (await LocalFileStore(source.directoryPath).list())
      .firstWhere((name) => name.endsWith('backup.daylio'),
          orElse: () => throw Exception('backup.daylio not found in archive'));
  final encoded = utf8
      .decode(await File(join(source.directoryPath, backupName)).readAsBytes())
      .replaceAll('\r', '')
      .replaceAll('\n', '');
  final backup = json.decode(utf8.decode(base64.decode(encoded)));

  final photoFilesByChecksum = await _photoFilesByChecksum(source);
  final assetsById = {
    for (final asset in backup['assets'] as List<dynamic>) asset['id']: asset,
  };

  final groups = _sortedByOrder(backup['tag_groups']);
  final categoryNameByGroupId = <int, String>{};
  final categories = <ImportedCategory>[];
  for (final group in groups) {
    final groupId = group['id'] as int?;
    final name = sanitizeTagName((group['name'] as String?) ?? '');
    if (groupId == null || name.isEmpty) continue;
    categoryNameByGroupId[groupId] = name;
    categories.add(ImportedCategory(name: name));
  }

  final tagNameById = <int, String>{};
  final tagDefinitions = <ImportedTagDefinition>[];
  for (final tag in _sortedByOrder(backup['tags'])) {
    final tagId = tag['id'] as int?;
    final name = sanitizeTagName((tag['name'] as String?) ?? '');
    if (tagId == null || name.isEmpty) continue;
    tagNameById[tagId] = name;
    final createdAt = tag['createdAt'] as int?;
    tagDefinitions.add(ImportedTagDefinition(
      name: name,
      tagType: TagType.label,
      categoryName: categoryNameByGroupId[tag['id_tag_group']],
      timeCreate: createdAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(createdAt),
    ));
  }

  return ImportBundle(
    categories: categories,
    tagDefinitions: tagDefinitions,
    entries: [
      for (final entry in backup['dayEntries'] as List<dynamic>)
        _parseEntry(entry, assetsById, photoFilesByChecksum, tagNameById),
    ],
  );
}

List<dynamic> _sortedByOrder(Object? items) =>
    List<dynamic>.from((items as List?) ?? const [])
      ..sort((a, b) =>
          ((a['order'] as int?) ?? 0).compareTo((b['order'] as int?) ?? 0));

Future<Map<String, File>> _photoFilesByChecksum(ImportSource source) async {
  final photosFolder =
      Directory(join(source.directoryPath, 'assets', 'photos'));
  if (!await photosFolder.exists()) return {};

  return {
    for (final file in await photosFolder.list(recursive: true).toList())
      if (file is File) basenameWithoutExtension(file.path): file,
  };
}

ImportedEntry _parseEntry(
  Map<String, dynamic> entry,
  Map<dynamic, dynamic> assetsById,
  Map<String, File> photoFilesByChecksum,
  Map<int, String> tagNameById,
) {
  final timeCreate = wallClockOf(
      DateTime.fromMillisecondsSinceEpoch(entry['datetime'], isUtc: true)
          .add(Duration(milliseconds: entry['timeZoneOffset'] ?? 0)));

  final note = entry['note'] as String? ?? '';
  final mood = entry['mood'] as int?;

  final photoFiles = <File>[];
  for (final assetId in (entry['assets'] as List?)?.cast<int>() ?? <int>[]) {
    final asset = assetsById[assetId];
    if (asset == null || asset['type'] != 1) continue;
    final file = photoFilesByChecksum[asset['checksum']];
    if (file != null) photoFiles.add(file);
  }

  return ImportedEntry(
    Entry(
      text: titledText(
          entry['note_title'], note.isEmpty ? null : html2md.convert(note)),
      mood: mood == null ? null : Mood.fromRating(mood, bestFirst: true),
      timeCreate: timeCreate,
      timeModified: timeCreate,
    ),
    tags: [
      for (final tagId in (entry['tags'] as List?)?.cast<int>() ?? <int>[])
        if (tagNameById[tagId] != null)
          ImportedEntryTag(name: tagNameById[tagId]!, tagType: TagType.label),
    ],
    attachments: [
      for (final (index, file) in photoFiles.indexed)
        ImportedAttachment(
          type: AttachmentType.image,
          rank: photoFiles.length - 1 - index,
          timeCreate: timeCreate,
          media: FileMedia(file),
        ),
    ],
  );
}
