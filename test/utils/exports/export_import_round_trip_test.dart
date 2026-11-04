// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:daily_you/database/attachment_storage.dart';
import 'package:daily_you/database/entry_attachment_dao.dart';
import 'package:daily_you/database/entry_dao.dart';
import 'package:daily_you/database/entry_tag_dao.dart';
import 'package:daily_you/database/tag_category_dao.dart';
import 'package:daily_you/database/tag_dao.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/models/mood_scale_level.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/providers/mood_scale_provider.dart';
import 'package:daily_you/storage/storage_picker.dart';
import 'package:daily_you/utils/exports/export_registry.dart';
import 'package:daily_you/utils/exports/export_runner.dart';
import 'package:daily_you/utils/imports/import_registry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../support/export_harness.dart';

void main() {
  final harness = ExportHarness();
  useExportHarness(harness);

  setUpAll(() => initializeDateFormatting('en'));

  Future<Map<String, Object?>> storedJournal() async {
    final categories = await TagCategoryDao.getAll();
    final tags = await TagDao.getAll();
    final entryTags = await EntryTagDao.getAll();
    final attachments = await EntryAttachmentDao.getAll();
    final entries = (await EntryDao.getAll()).reversed;

    String? categoryName(int? id) =>
        categories.where((category) => category.id == id).firstOrNull?.name;

    return {
      'categories': [
        for (final category in categories)
          {
            'name': category.name,
            'icon': category.icon,
            'iconType': category.iconType,
            'color': category.color,
            'sortOrder': category.sortOrder,
          }
      ],
      'tags': [
        for (final tag in tags)
          {
            'name': tag.name,
            'type': tag.tagType,
            'category': categoryName(tag.categoryId),
            'icon': tag.icon,
            'iconType': tag.iconType,
            'color': tag.color,
            'sortOrder': tag.sortOrder,
          }
      ],
      'entries': [
        for (final entry in entries)
          {
            'text': entry.text,
            'mood': entry.mood,
            'timeCreate': entry.timeCreate,
            'timeModified': entry.timeModified,
            'tags': {
              for (final entryTag
                  in entryTags.where((tag) => tag.entryId == entry.id))
                tags.firstWhere((tag) => tag.id == entryTag.tagId).name:
                    entryTag.value
            },
            'attachments': [
              for (final attachment in attachments
                  .where((attachment) => attachment.entryId == entry.id))
                {
                  'type': attachment.type,
                  'rank': attachment.rank,
                  'timeCreate': attachment.timeCreate,
                  'bytes': File((await AttachmentStorage.instance
                          .getLocalPath(attachment.filePath, attachment.type))!)
                      .readAsBytesSync(),
                }
            ]..sort((first, second) =>
                (first['rank'] as int).compareTo(second['rank'] as int)),
          }
      ],
    };
  }

  Future<void> seedJournal() async {
    final life = await harness.addCategory('Life', color: 0xFF2196F3);
    final health = await harness.addCategory('Health', sortOrder: 1);
    final work = await harness.addTag('Work', TagType.label,
        categoryId: life.id, color: 0xFF112233);
    final gym = await harness.addTag('Gym', TagType.label);
    final water =
        await harness.addTag('Water', TagType.tracker, categoryId: health.id);
    final sleep = await harness.addTag('Sleep', TagType.tracker, sortOrder: 1);

    await harness.addEntry(DateTime(2026, 3, 4, 8, 30),
        text: 'He said "hi", then left\r\nsecond line\n- not a list 🙂',
        mood: 4,
        timeModified: DateTime(2026, 3, 4, 9),
        tags: [
          SeededTag(work),
          SeededTag(water, value: '3'),
          SeededTag(sleep, value: '7.5'),
        ],
        attachments: [
          const SeededAttachment(AttachmentType.image, 'a.jpg', [1, 2, 3],
              rank: 1),
          const SeededAttachment(AttachmentType.video, 'a.mp4', [4, 5]),
          const SeededAttachment(AttachmentType.audio, 'a.m4a', [6], rank: 2),
        ]);
    await harness.addEntry(DateTime(2026, 3, 4, 20, 15),
        text: 'second entry of the day',
        tags: [
          SeededTag(gym)
        ],
        attachments: [
          const SeededAttachment(AttachmentType.image, 'b.png', [7, 8]),
        ]);
    await harness.addEntry(DateTime(2026, 3, 6), mood: 1);
  }

  testWidgets('moves a journal to a fresh install through the JSON zip',
      (tester) async {
    final context = await harness.pumpContext(tester);

    await tester.runAsync(() async {
      await harness.saveMoodScale(
          [const MoodScaleLevel(mood: 4, label: 'Exported scale')]);
      await seedJournal();
      final before = await storedJournal();

      final exportOutcome = await runExport(context, (_) {},
          option: ExportRegistry.instance.optionFor(ExportFormat.json),
          pickAttachmentTypes: (_) async => {...AttachmentType.values},
          pickDirectory: () async =>
              PickedDirectory(harness.destinationDirectory.path));
      final archive = harness.destinationDirectory.listSync().single.path;

      await harness.wipe();
      await harness.saveMoodScale(
          [const MoodScaleLevel(mood: 4, label: 'My own scale')]);
      final importOutcome = await ImportRegistry.instance
          .optionFor(ImportFormat.dailyYouJson)
          .run(context, (_) {},
              pickFile: ({allowedExtensions, mimeTypes}) async =>
                  PickedFile(archive));

      expect(exportOutcome.succeeded, isTrue);
      expect(importOutcome.succeeded, isTrue);
      expect(await storedJournal(), equals(before));
      expect(MoodScaleProvider.instance.levels.single.label, 'My own scale');
    });
  });
}
