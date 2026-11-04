// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:convert';

import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/storage/file_store.dart';
import 'package:daily_you/utils/exports/export_naming.dart';
import 'package:daily_you/utils/exports/export_snapshot.dart';
import 'package:intl/intl.dart';

const markdownNotesFolder = 'logs';

Future<Map<String, String>> writeMarkdown(
    ExportSnapshot snapshot, FileStore store) async {
  final notes = await store.subfolder(markdownNotesFolder);
  final namedEntries = nameExportEntries(snapshot);

  for (final named in namedEntries) {
    await notes.write(
        'log_${named.fileStem}.md', utf8.encode(_note(snapshot, named)));
  }

  return attachmentSourcesOf(namedEntries, folder: markdownNotesFolder);
}

String _note(ExportSnapshot snapshot, NamedExportEntry named) {
  final entry = named.exported.entry;
  final note = StringBuffer(_frontMatter(snapshot, named.exported));

  for (final attachment in named.attachments) {
    note.writeln(attachment.attachment.type == AttachmentType.image
        ? '![](${attachment.path})'
        : '[${attachment.fileName}](${attachment.path})');
  }

  final date = DateFormat.yMMMEd(snapshot.locale).format(entry.timeCreate);
  note.writeln('${_moodPrefix(snapshot, entry.mood)}$date\n${entry.text}');
  return note.toString();
}

String _frontMatter(ExportSnapshot snapshot, ExportEntry exported) {
  final entry = exported.entry;
  final mood = entry.mood;
  final labels = [
    for (final tag in exported.tags)
      if (tag.tagType == TagType.label) tag.name
  ];
  final trackers = {
    for (final tag in exported.tags)
      if (tag.tagType == TagType.tracker && tag.value != null)
        tag.name: tag.value
  };
  final fields = {
    'date': entry.timeCreate.toIso8601String(),
    if (mood != null) 'mood': mood,
    if (mood != null) 'moodLabel': snapshot.moodLabelOf(mood),
    if (labels.isNotEmpty) 'tags': labels,
    if (trackers.isNotEmpty) 'trackers': trackers,
  };

  return [
    '---',
    for (final MapEntry(:key, :value) in fields.entries)
      '$key: ${jsonEncode(value)}',
    '---',
    '',
  ].join('\n');
}

String _moodPrefix(ExportSnapshot snapshot, int? mood) {
  final level = mood == null ? null : snapshot.levelOf(mood);
  if (level == null) return '';
  return '${level.hasTextIcon ? level.icon : snapshot.moodLabelOf(level.mood)} ';
}
