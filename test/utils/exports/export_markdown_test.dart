// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:convert';

import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/models/mood_scale_level.dart';
import 'package:daily_you/storage/in_memory_file_store.dart';
import 'package:daily_you/utils/exports/export_markdown.dart';
import 'package:daily_you/utils/exports/export_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../support/export_snapshots.dart';

void main() {
  late InMemoryFileStore store;

  setUpAll(() => initializeDateFormatting('en'));

  setUp(() => store = InMemoryFileStore());

  Future<Map<String, String>> write(ExportSnapshot snapshot) =>
      writeMarkdown(snapshot, store);

  Future<InMemoryFileStore> notes() async =>
      await store.subfolder(markdownNotesFolder) as InMemoryFileStore;

  Future<String> noteNamed(String name) async =>
      utf8.decode((await (await notes()).read(name))!);

  test('names a note after the day it was written', () async {
    await write(
        snapshotOf([exportEntry(DateTime(2026, 3, 4), text: 'a good day')]));

    expect(await (await notes()).list(), equals(['log_2026-03-04.md']));
    expect(await noteNamed('log_2026-03-04.md'),
        equals('Wed, Mar 4, 2026\na good day\n'));
  });

  test('puts the mood label before the date', () async {
    await write(snapshotOf([exportEntry(DateTime(2026, 3, 4), mood: 2)]));

    expect(await noteNamed('log_2026-03-04.md'),
        equals('Bad Wed, Mar 4, 2026\n\n'));
  });

  test('puts a text icon before the date instead of the label', () async {
    await write(snapshotOf(
      [exportEntry(DateTime(2026, 3, 4), mood: 4)],
      moodScale: const [MoodScaleLevel(mood: 4, label: 'Good', icon: '🙂')],
    ));

    expect(await noteNamed('log_2026-03-04.md'),
        equals('🙂 Wed, Mar 4, 2026\n\n'));
  });

  test('gives the earliest note of a day the plain name', () async {
    await write(snapshotOf([
      exportEntry(DateTime(2026, 3, 4, 8), text: 'morning'),
      exportEntry(DateTime(2026, 3, 4, 20), text: 'evening'),
      exportEntry(DateTime(2026, 3, 5)),
    ]));

    expect(
        await (await notes()).list(),
        unorderedEquals(
            ['log_2026-03-04.md', 'log_2026-03-04_2.md', 'log_2026-03-05.md']));
    expect(await noteNamed('log_2026-03-04.md'), contains('morning'));
    expect(await noteNamed('log_2026-03-04_2.md'), contains('evening'));
  });

  test('links images in the snapshot order and points each at its source',
      () async {
    final sources = await write(snapshotOf([
      exportEntry(DateTime(2026, 3, 4), text: 'body', attachments: [
        exportAttachment(AttachmentType.image, '/data/a.png', rank: 1),
        exportAttachment(AttachmentType.image, '/data/b.jpg'),
      ])
    ]));

    expect(sources, {
      'logs/Images/image_2026-03-04_1.png': '/data/a.png',
      'logs/Images/image_2026-03-04_0.jpg': '/data/b.jpg',
    });
    expect(
        await noteNamed('log_2026-03-04.md'),
        startsWith('![](Images/image_2026-03-04_1.png)\n'
            '![](Images/image_2026-03-04_0.jpg)\n'));
  });

  test('carries the note suffix into its image names', () async {
    final sources = await write(snapshotOf([
      for (final hour in [8, 9])
        exportEntry(DateTime(2026, 3, 4, hour), attachments: [
          exportAttachment(AttachmentType.image, '/data/a.png'),
        ])
    ]));

    expect(
        sources.keys,
        equals([
          'logs/Images/image_2026-03-04_0.png',
          'logs/Images/image_2026-03-04_2_0.png'
        ]));
  });

  test('links a video into its own folder as a plain link, not an image',
      () async {
    final sources = await write(snapshotOf([
      exportEntry(DateTime(2026, 3, 4), text: 'body', attachments: [
        exportAttachment(AttachmentType.video, '/data/a.mp4'),
      ])
    ]));

    expect(sources.keys, equals(['logs/Video/video_2026-03-04_0.mp4']));
    expect(await noteNamed('log_2026-03-04.md'),
        startsWith('[video_2026-03-04_0.mp4](Video/video_2026-03-04_0.mp4)\n'));
  });

  test('copies no attachment bytes into the note folder', () async {
    await write(snapshotOf([
      exportEntry(DateTime(2026, 3, 4), attachments: [
        exportAttachment(AttachmentType.audio, '/data/a.m4a'),
      ])
    ]));

    expect(await (await notes()).list(), equals(['log_2026-03-04.md']));
  });
}
