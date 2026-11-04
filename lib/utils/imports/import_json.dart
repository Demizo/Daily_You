// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:convert';

import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/mood.dart';
import 'package:daily_you/utils/imports/import_bundle.dart';
import 'package:daily_you/utils/imports/import_source.dart';

Future<ImportBundle> parseJson(ImportSource source) async {
  final root = json.decode(utf8.decode(await source.file.readAsBytes()));
  if (root is! List) throw const FormatException('Not a Daily You JSON file');
  return ImportBundle(entries: [for (final entry in root) _parseEntry(entry)]);
}

ImportedEntry _parseEntry(Map<String, dynamic> entry) {
  final timeCreate = _parseTime(entry['timeCreated']);
  final hasLegacyImage = entry['imgPath'] != null;
  return ImportedEntry(
    Entry(
      text: entry['text'],
      mood: Mood.fromLegacy(entry['mood'] as int?),
      timeCreate: timeCreate,
      timeModified: _parseTime(entry['timeModified']),
    ),
    attachments: [
      if (hasLegacyImage)
        ImportedAttachment(
          type: AttachmentType.image,
          rank: 0,
          timeCreate: timeCreate,
          media: ReferenceMedia(entry['imgPath']),
        ),
      if (entry['images'] != null)
        for (final image in entry['images'])
          ImportedAttachment(
            type: AttachmentType.image,
            rank: (image['imgRank'] as int) + (hasLegacyImage ? 1 : 0),
            timeCreate: _parseTime(image['timeCreated']),
            media: ReferenceMedia(image['imgPath']),
          ),
    ],
  );
}

DateTime _parseTime(String text) {
  final parsed = DateTime.parse(text);
  return parsed.isUtc ? parsed.toLocal() : parsed;
}
