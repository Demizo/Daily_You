// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:convert';

import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/mood.dart';
import 'package:daily_you/utils/imports/import_bundle.dart';
import 'package:daily_you/utils/imports/import_source.dart';

const _moodByHappiness = {
  'VERY_SAD': Mood.veryUnpleasant,
  'SAD': Mood.unpleasant,
  'NEUTRAL': Mood.neutral,
  'HAPPY': Mood.pleasant,
  'VERY_HAPPY': Mood.veryPleasant,
};

Future<ImportBundle> parseOneShot(ImportSource source) async {
  final root = json.decode(utf8.decode(await source.file.readAsBytes()));

  return ImportBundle(entries: [
    for (final entry in root as List<dynamic>)
      _parseEntry(entry as Map<String, dynamic>),
  ]);
}

ImportedEntry _parseEntry(Map<String, dynamic> entry) {
  final timeCreate =
      DateTime.fromMillisecondsSinceEpoch((entry['created'] as int) * 1000);
  final relativePath = entry['relativePath'] as String?;

  return ImportedEntry(
    Entry(
      text: entry['textContent'],
      mood: _moodByHappiness[entry['happiness']],
      timeCreate: timeCreate,
      timeModified: timeCreate,
    ),
    attachments: [
      if (relativePath != null)
        ImportedAttachment(
          type: AttachmentType.image,
          rank: 0,
          timeCreate: timeCreate,
          media: ReferenceMedia(relativePath),
        ),
    ],
  );
}
