// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/mood_scale_level.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/models/tag_icon_type.dart';
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

const hardText = 'He said "hi", then left\r\nsecond line\nthird line 🙂';

ExportSnapshot kitchenSinkSnapshot() => ExportSnapshot(
      locale: 'en',
      exportedAt: exportedAtForTests,
      moodLabelOf: (mood) => moodLabelsForTests[mood]!,
      moodScale: [
        const MoodScaleLevel(mood: 1, label: 'Awful', color: 0xFFF44336),
        const MoodScaleLevel(mood: 2, label: 'Bad', icon: '😕'),
        const MoodScaleLevel(mood: 3, label: 'Okay'),
        const MoodScaleLevel(
            mood: 4,
            label: 'Good: really',
            icon: 'sentiment_satisfied',
            iconType: TagIconType.materialIcon,
            color: 0xFF4CAF50),
        const MoodScaleLevel(mood: 5, label: 'Great'),
      ],
      categories: const [
        ExportCategory(name: 'Life', color: 0xFF2196F3),
        ExportCategory(
            name: 'Health',
            icon: 'favorite',
            iconType: TagIconType.materialIcon,
            sortOrder: 1),
      ],
      tagDefinitions: const [
        ExportTagDefinition(
            name: 'Work',
            tagType: TagType.label,
            categoryName: 'Life',
            icon: '💼'),
        ExportTagDefinition(name: 'Gym', tagType: TagType.label, sortOrder: 1),
        ExportTagDefinition(
            name: 'Water',
            tagType: TagType.tracker,
            categoryName: 'Health',
            color: 0xFF03A9F4),
        ExportTagDefinition(
            name: 'Sleep', tagType: TagType.tracker, sortOrder: 1),
        ExportTagDefinition(
            name: 'date', tagType: TagType.tracker, sortOrder: 2),
      ],
      entries: [
        exportEntry(
          DateTime(2026, 3, 4, 8, 30),
          text: hardText,
          mood: 4,
          timeModified: DateTime(2026, 3, 4, 9),
          tags: const [
            ExportEntryTag(
                name: 'Work', tagType: TagType.label, categoryName: 'Life'),
            ExportEntryTag(name: 'Gym', tagType: TagType.label),
            ExportEntryTag(
                name: 'Water',
                tagType: TagType.tracker,
                categoryName: 'Health',
                value: 3),
            ExportEntryTag(name: 'Sleep', tagType: TagType.tracker, value: 7.5),
            ExportEntryTag(name: 'date', tagType: TagType.tracker, value: 1),
          ],
          attachments: [
            exportAttachment(AttachmentType.video, '/data/Video/clip.mp4',
                rank: 2, timeCreate: DateTime(2026, 3, 4, 8, 32)),
            exportAttachment(AttachmentType.image, '/data/Images/photo.png',
                rank: 1, timeCreate: DateTime(2026, 3, 4, 8, 31)),
            exportAttachment(AttachmentType.audio, '/data/Audio/memo.m4a',
                timeCreate: DateTime(2026, 3, 4, 8, 33)),
          ],
        ),
        exportEntry(DateTime(2026, 3, 4, 20, 15),
            text: '- starts with a dash\n=1+1'),
        exportEntry(DateTime(2026, 3, 5, 9), mood: 1, tags: const [
          ExportEntryTag(name: 'Water', tagType: TagType.tracker),
        ]),
      ],
    );
