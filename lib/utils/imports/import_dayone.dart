// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:convert';
import 'dart:io';

import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/utils/imports/import_archive.dart';
import 'package:daily_you/utils/imports/import_bundle.dart';
import 'package:daily_you/utils/imports/import_dayone_text.dart';
import 'package:daily_you/utils/imports/import_source.dart';
import 'package:daily_you/utils/imports/import_time.dart';
import 'package:daily_you/utils/tag_name_sanitizer.dart';
import 'package:path/path.dart';

const _mediaKinds = [
  (name: 'photos', type: AttachmentType.image),
  (name: 'videos', type: AttachmentType.video),
  (name: 'audios', type: AttachmentType.audio),
];
Future<ImportBundle> parseDayOne(ImportSource source,
    {required String favoriteTagName}) async {
  final extractedPath = await extractIfArchive(source);
  final journalFiles = extractedPath == null
      ? [source.file]
      : (Directory(extractedPath)
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => extension(file.path).toLowerCase() == '.json')
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path)));

  final journals = <(String, List<ImportedEntry>)>[];
  for (final file in journalFiles) {
    final Object? root;
    try {
      root = await _decodeJson(file);
    } on FormatException {
      continue;
    }
    if (root is! Map || root['entries'] is! List) continue;

    final entries = <ImportedEntry>[];
    for (final entry in root['entries']) {
      entries.add(await _parseEntry(entry, dirname(file.path),
          favoriteTagName: favoriteTagName));
    }
    journals
        .add((sanitizeTagName(basenameWithoutExtension(file.path)), entries));
  }
  if (journals.isEmpty) throw const FormatException('Not a Day One export');

  final labelJournals = journals.length > 1;
  final entries = [
    for (final (journalName, journalEntries) in journals)
      for (final entry in journalEntries)
        labelJournals && journalName.isNotEmpty
            ? _withLabel(entry, journalName)
            : entry,
  ];
  entries.sort((a, b) => a.entry.timeCreate.compareTo(b.entry.timeCreate));
  return ImportBundle(entries: entries);
}

Future<Object?> _decodeJson(File file) =>
    file.openRead().transform(utf8.decoder).transform(json.decoder).single;

ImportedEntry _withLabel(ImportedEntry imported, String name) => ImportedEntry(
      imported.entry,
      tags: [
        ...imported.tags,
        ImportedEntryTag(name: name, tagType: TagType.label),
      ],
      attachments: imported.attachments,
    );

Future<ImportedEntry> _parseEntry(Map entry, String mediaPath,
    {required String favoriteTagName}) async {
  final timeZoneName = entry['timeZone'] as String?;
  final timeCreate =
      wallClockIn(DateTime.parse(entry['creationDate']), timeZoneName);
  final modifiedDate = entry['modifiedDate'] as String?;
  final timeModified = modifiedDate == null
      ? timeCreate
      : wallClockIn(DateTime.parse(modifiedDate), timeZoneName);

  final tagNames = [
    for (final tag in entry['tags'] as List? ?? const [])
      sanitizeTagName(tag as String),
    if (entry['starred'] == true) favoriteTagName,
  ].where((name) => name.isNotEmpty);

  return ImportedEntry(
    Entry(
      text: dayOneText(entry['text'] as String? ?? ''),
      timeCreate: timeCreate,
      timeModified: timeModified,
    ),
    tags: [
      for (final name in tagNames)
        ImportedEntryTag(name: name, tagType: TagType.label),
    ],
    attachments: await _parseAttachments(entry, mediaPath, timeCreate),
  );
}

Future<List<ImportedAttachment>> _parseAttachments(
    Map entry, String mediaPath, DateTime timeCreate) async {
  final media = <({int order, int position, AttachmentType type, File file})>[];
  for (final kind in _mediaKinds) {
    for (final item in entry[kind.name] as List? ?? const []) {
      final file =
          File(join(mediaPath, kind.name, '${item['md5']}.${item['type']}'));
      if (!isWithin(join(mediaPath, kind.name), normalize(file.path))) {
        throw FormatException('Media path leaves the export', file.path);
      }
      if (!await file.exists()) continue;
      media.add((
        order: item['orderInEntry'] as int? ?? 0,
        position: media.length,
        type: kind.type,
        file: file,
      ));
    }
  }
  media.sort((a, b) {
    final byOrder = a.order.compareTo(b.order);
    return byOrder != 0 ? byOrder : a.position.compareTo(b.position);
  });

  return [
    for (final (index, item) in media.indexed)
      ImportedAttachment(
        type: item.type,
        rank: media.length - 1 - index,
        timeCreate: timeCreate,
        media: FileMedia(item.file),
      ),
  ];
}
