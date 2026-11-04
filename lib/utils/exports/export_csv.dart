// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/storage/file_store.dart';
import 'package:daily_you/utils/exports/export_naming.dart';
import 'package:daily_you/utils/exports/export_snapshot.dart';

const csvDocumentName = 'daily_you_export.csv';
const _trackerColumnPrefix = 'tracker:';
const _listSeparator = ', ';

const _fixedColumns = [
  'date',
  'modified',
  'mood',
  'moodLabel',
  'text',
  'tags',
  'attachments',
];

Future<Map<String, String>> writeCsv(
    ExportSnapshot snapshot, FileStore store) async {
  final namedEntries = nameExportEntries(snapshot);
  final trackerNames = [
    for (final tag in snapshot.tagDefinitions)
      if (tag.tagType == TagType.tracker) tag.name
  ];

  final rows = [
    [
      ..._fixedColumns,
      for (final name in trackerNames) '$_trackerColumnPrefix$name'
    ],
    for (final named in namedEntries) _row(snapshot, named, trackerNames),
  ];

  await store.write(csvDocumentName,
      utf8.encode(const CsvEncoder(addBom: true).convert(rows)));

  return attachmentSourcesOf(namedEntries);
}

List<Object?> _row(ExportSnapshot snapshot, NamedExportEntry named,
    List<String> trackerNames) {
  final entry = named.exported.entry;
  final mood = entry.mood;
  final trackerValues = {
    for (final tag in named.exported.tags)
      if (tag.tagType == TagType.tracker) tag.name: tag.value
  };

  return [
    entry.timeCreate.toIso8601String(),
    entry.timeModified.toIso8601String(),
    mood,
    if (mood == null) null else snapshot.moodLabelOf(mood),
    entry.text,
    [
      for (final tag in named.exported.tags)
        if (tag.tagType == TagType.label) tag.name
    ].join(_listSeparator),
    [for (final attachment in named.attachments) attachment.path]
        .join(_listSeparator),
    for (final name in trackerNames) trackerValues[name],
  ];
}
