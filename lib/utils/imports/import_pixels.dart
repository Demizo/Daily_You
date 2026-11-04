// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:convert';

import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/mood.dart';
import 'package:daily_you/utils/imports/import_bundle.dart';
import 'package:daily_you/utils/imports/import_source.dart';
import 'package:intl/intl.dart';

Future<ImportBundle> parsePixels(ImportSource source) async {
  final root = json.decode(utf8.decode(await source.file.readAsBytes()));

  return ImportBundle(entries: [
    for (final entry in root as List<dynamic>)
      if (entry['type'] == 'Mood') _parseEntry(entry as Map<String, dynamic>),
  ]);
}

ImportedEntry _parseEntry(Map<String, dynamic> entry) {
  final timeCreate = DateFormat("yyyy-MM-dd").parse(entry['date']);
  final scores = (entry['scores'] as List<dynamic>).cast<int>();
  final averageScore = scores.reduce((a, b) => a + b) ~/ scores.length;

  return ImportedEntry(Entry(
    text: entry['notes'] ?? '',
    mood: Mood.fromRating(averageScore),
    timeCreate: timeCreate,
    timeModified: timeCreate,
  ));
}
