// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/mood_scale_level.dart';
import 'package:daily_you/utils/exports/export_snapshot.dart';

final exportedAtForTests = DateTime(2026, 4, 1, 12);

const moodLabelsForTests = {
  1: 'Awful',
  2: 'Bad',
  3: 'Okay',
  4: 'Good: really',
  5: 'Great',
};

final moodScaleForTests = [
  for (final MapEntry(key: mood, value: label) in moodLabelsForTests.entries)
    MoodScaleLevel(mood: mood, label: label)
];

ExportSnapshot snapshotOf(
  List<ExportEntry> entries, {
  List<MoodScaleLevel>? moodScale,
  List<ExportCategory> categories = const [],
  List<ExportTagDefinition> tagDefinitions = const [],
}) =>
    ExportSnapshot(
      locale: 'en',
      exportedAt: exportedAtForTests,
      moodLabelOf: (mood) => moodLabelsForTests[mood]!,
      moodScale: moodScale ?? moodScaleForTests,
      categories: categories,
      tagDefinitions: tagDefinitions,
      entries: entries,
    );

ExportEntry exportEntry(
  DateTime timeCreate, {
  String text = '',
  int? mood,
  DateTime? timeModified,
  List<ExportEntryTag> tags = const [],
  List<ExportAttachment> attachments = const [],
}) =>
    ExportEntry(
      Entry(
          text: text,
          mood: mood,
          timeCreate: timeCreate,
          timeModified: timeModified ?? timeCreate),
      tags: tags,
      attachments: attachments,
    );

ExportAttachment exportAttachment(
  AttachmentType type,
  String sourcePath, {
  int rank = 0,
  DateTime? timeCreate,
}) =>
    ExportAttachment(
        type: type,
        rank: rank,
        timeCreate: timeCreate ?? DateTime(2026, 3, 4, 8),
        sourcePath: sourcePath);
