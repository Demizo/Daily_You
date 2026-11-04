// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:convert';

import 'package:daily_you/storage/file_store.dart';
import 'package:daily_you/utils/exports/export_naming.dart';
import 'package:daily_you/utils/exports/export_snapshot.dart';

const jsonDocumentName = 'daily_you_export.json';
const jsonFormatMarker = 'daily-you';
const jsonFormatVersion = 2;

Future<Map<String, String>> writeJson(
    ExportSnapshot snapshot, FileStore store) async {
  final namedEntries = nameExportEntries(snapshot);

  final document = {
    'format': jsonFormatMarker,
    'version': jsonFormatVersion,
    'exportedAt': snapshot.exportedAt.toIso8601String(),
    'moodScale': [
      for (final level in snapshot.moodScale)
        {
          'mood': level.mood,
          'label': snapshot.moodLabelOf(level.mood),
          'icon': level.icon,
          'iconType': level.iconType.name,
          'color': level.color,
        }
    ],
    'categories': [
      for (final category in snapshot.categories)
        {
          'name': category.name,
          'icon': category.icon,
          'iconType': category.iconType.name,
          'color': category.color,
          'sortOrder': category.sortOrder,
        }
    ],
    'tags': [
      for (final tag in snapshot.tagDefinitions)
        {
          'name': tag.name,
          'type': tag.tagType.name,
          'category': tag.categoryName,
          'icon': tag.icon,
          'iconType': tag.iconType.name,
          'color': tag.color,
          'sortOrder': tag.sortOrder,
        }
    ],
    'entries': [for (final named in namedEntries) _entryJson(named)],
  };

  await store.write(jsonDocumentName,
      utf8.encode(const JsonEncoder.withIndent('  ').convert(document)));

  return attachmentSourcesOf(namedEntries);
}

Map<String, Object?> _entryJson(NamedExportEntry named) {
  final entry = named.exported.entry;
  return {
    'text': entry.text,
    'mood': entry.mood,
    'timeCreate': entry.timeCreate.toIso8601String(),
    'timeModified': entry.timeModified.toIso8601String(),
    'tags': [
      for (final tag in named.exported.tags)
        {'name': tag.name, 'type': tag.tagType.name, 'value': tag.value}
    ],
    'attachments': [
      for (final attachment in named.attachments)
        {
          'type': attachment.attachment.type.name,
          'path': attachment.path,
          'rank': attachment.attachment.rank,
          'timeCreate': attachment.attachment.timeCreate.toIso8601String(),
        }
    ],
  };
}
