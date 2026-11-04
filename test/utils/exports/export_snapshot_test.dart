// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';
import 'dart:ui';

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/models/mood_scale_level.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/utils/exports/export_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' show join;

import '../../support/export_harness.dart';

void main() {
  final harness = ExportHarness();
  useExportHarness(harness);

  late AppLocalizations localizations;

  setUpAll(() async {
    localizations = await AppLocalizations.delegate.load(const Locale('en'));
  });

  Future<ExportSnapshot> snapshot(
          [Set<AttachmentType> includedTypes = const {
            AttachmentType.image,
            AttachmentType.audio,
            AttachmentType.video,
          }]) =>
      buildExportSnapshot(
          localizations: localizations,
          locale: 'en',
          includedTypes: includedTypes);

  test('orders entries by time, then by id', () async {
    final day = DateTime(2026, 3, 4, 9);
    await harness.addEntry(DateTime(2026, 3, 5), text: 'latest');
    final first = await harness.addEntry(day, text: 'first stored');
    final second = await harness.addEntry(day, text: 'second stored');
    await harness.addEntry(DateTime(2026, 3, 1), text: 'earliest');

    final entries = (await snapshot()).entries;

    expect(entries.map((exported) => exported.entry.text),
        ['earliest', 'first stored', 'second stored', 'latest']);
    expect(first.id! < second.id!, isTrue);
  });

  test('groups tags under their entry with the category name', () async {
    final category = await harness.addCategory('Body');
    final walk = await harness.addTag('Walk', TagType.label);
    final water =
        await harness.addTag('Water', TagType.tracker, categoryId: category.id);
    await harness.addEntry(DateTime(2026, 3, 4), tags: [
      SeededTag(walk),
      SeededTag(water, value: '2.5'),
    ]);
    await harness.addEntry(DateTime(2026, 3, 5), tags: [SeededTag(walk)]);
    await harness.addEntry(DateTime(2026, 3, 6));

    final entries = (await snapshot()).entries;

    expect(
        entries[0]
            .tags
            .map((tag) => (tag.name, tag.tagType, tag.categoryName, tag.value)),
        unorderedEquals([
          ('Walk', TagType.label, null, null),
          ('Water', TagType.tracker, 'Body', 2.5),
        ]));
    expect(entries[1].tags.map((tag) => tag.name), ['Walk']);
    expect(entries[2].tags, isEmpty);
  });

  test('keeps only the included attachment types', () async {
    await harness.addEntry(DateTime(2026, 3, 4), attachments: [
      const SeededAttachment(AttachmentType.image, 'a.jpg', [1]),
      const SeededAttachment(AttachmentType.audio, 'a.m4a', [2], rank: 1),
      const SeededAttachment(AttachmentType.video, 'a.mp4', [3], rank: 2),
    ]);

    final attachments =
        (await snapshot({AttachmentType.audio})).entries.single.attachments;

    expect(attachments.map((attachment) => attachment.type),
        [AttachmentType.audio]);
    expect(File(attachments.single.sourcePath).readAsBytesSync(), [2]);
  });

  test('includes no attachment when no type is included', () async {
    await harness.addEntry(DateTime(2026, 3, 4), attachments: [
      const SeededAttachment(AttachmentType.image, 'a.jpg', [1]),
    ]);

    expect((await snapshot({})).entries.single.attachments, isEmpty);
  });

  test('omits an attachment whose file is missing', () async {
    await harness.addEntry(DateTime(2026, 3, 4), attachments: [
      const SeededAttachment(AttachmentType.image, 'kept.jpg', [1], rank: 1),
      const SeededAttachment(AttachmentType.image, 'lost.jpg', [2]),
    ]);
    final lost = EntryAttachmentsProvider.instance.attachments
        .firstWhere((attachment) => attachment.rank == 0);
    File(join(harness.supportDirectory.path, 'Images', lost.filePath))
        .deleteSync();

    final attachments = (await snapshot()).entries.single.attachments;

    expect(attachments.map((attachment) => attachment.rank), [1]);
  });

  test('lists attachments from the highest rank down', () async {
    await harness.addEntry(DateTime(2026, 3, 4), attachments: [
      const SeededAttachment(AttachmentType.image, 'a.jpg', [1]),
      const SeededAttachment(AttachmentType.image, 'b.jpg', [2], rank: 1),
    ]);

    final attachments = (await snapshot()).entries.single.attachments;

    expect(attachments.map((attachment) => attachment.rank), [1, 0]);
  });

  test('labels each mood from the scale, falling back to the default',
      () async {
    await harness
        .saveMoodScale([const MoodScaleLevel(mood: 4, label: 'Good: really')]);

    final built = await snapshot();

    expect(built.moodLabelOf(4), 'Good: really');
    expect(built.moodLabelOf(2), localizations.moodUnpleasant);
    expect(built.moodScale.single.mood, 4);
  });

  test('lists tag definitions and categories', () async {
    final category = await harness.addCategory('Body', color: 0xff112233);
    await harness.addTag('Water', TagType.tracker,
        categoryId: category.id, color: 0xff445566);

    final built = await snapshot();

    expect(built.categories.single.name, 'Body');
    expect(built.categories.single.color, 0xff112233);
    expect(built.tagDefinitions.single.name, 'Water');
    expect(built.tagDefinitions.single.categoryName, 'Body');
    expect(built.tagDefinitions.single.tagType, TagType.tracker);
  });

  test('reports progress per entry', () async {
    await harness.addEntry(DateTime(2026, 3, 4));
    await harness.addEntry(DateTime(2026, 3, 5));
    final reported = <double>[];

    await buildExportSnapshot(
        localizations: localizations,
        locale: 'en',
        includedTypes: const {},
        onProgress: reported.add);

    expect(reported, [0.5, 1.0]);
  });
}
