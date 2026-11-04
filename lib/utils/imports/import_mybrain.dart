// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:convert';

import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/mood.dart';
import 'package:daily_you/utils/imports/import_bundle.dart';
import 'package:daily_you/utils/imports/import_source.dart';
import 'package:daily_you/utils/imports/import_text.dart';

const _moodByName = {
  'TERRIBLE': Mood.veryUnpleasant,
  'BAD': Mood.unpleasant,
  'OKAY': Mood.neutral,
  'GOOD': Mood.pleasant,
  'AWESOME': Mood.veryPleasant,
};

Future<ImportBundle> parseMyBrain(ImportSource source) async {
  final root = json.decode(utf8.decode(await source.file.readAsBytes()));

  return ImportBundle(entries: [
    for (final entry in root['diary'] as List<dynamic>)
      ImportedEntry(Entry(
        text: titledText(entry['title'], entry['content']),
        mood: _moodByName[entry['mood']],
        timeCreate: _localTime(entry['createdDate']),
        timeModified: _localTime(entry['updatedDate']),
      )),
  ]);
}

DateTime _localTime(int millisecondsSinceEpoch) =>
    DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch, isUtc: true)
        .toLocal();
