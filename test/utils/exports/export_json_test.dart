// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:convert';

import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/storage/in_memory_file_store.dart';
import 'package:daily_you/utils/exports/export_json.dart';
import 'package:daily_you/utils/exports/export_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../support/export_golden.dart';
import '../../support/export_snapshots.dart';

void main() {
  late InMemoryFileStore store;

  setUpAll(() => initializeDateFormatting('en'));

  setUp(() => store = InMemoryFileStore());

  Future<Map<String, Object?>> documentOf(ExportSnapshot snapshot) async {
    await writeJson(snapshot, store);
    return jsonDecode(utf8.decode((await store.read(jsonDocumentName))!))
        as Map<String, Object?>;
  }

  test('matches the pinned file format', () async {
    await writeJson(kitchenSinkSnapshot(), store);

    await expectMatchesGolden(
        'export.json', (await store.read(jsonDocumentName))!);
  });

  test('marks the format and version', () async {
    final document = await documentOf(kitchenSinkSnapshot());

    expect(document['format'], 'daily-you');
    expect(document['version'], 2);
    expect(document['exportedAt'], '2026-04-01T12:00:00.000');
  });

  test('describes the mood scale, categories and tags by name', () async {
    final document = await documentOf(kitchenSinkSnapshot());

    final moodScale = (document['moodScale'] as List).cast<Map>();
    expect(moodScale.map((level) => level['mood']), [1, 2, 3, 4, 5]);
    expect(moodScale[3], {
      'mood': 4,
      'label': 'Good: really',
      'icon': 'sentiment_satisfied',
      'iconType': 'materialIcon',
      'color': 0xFF4CAF50,
    });
    final categories = (document['categories'] as List).cast<Map>();
    expect(categories.map((category) => category['name']), ['Life', 'Health']);
    final tags = (document['tags'] as List).cast<Map>();
    expect(tags.first, {
      'name': 'Work',
      'type': 'label',
      'category': 'Life',
      'icon': '💼',
      'iconType': 'character',
      'color': null,
      'sortOrder': 0,
    });
    expect(tags.map((tag) => tag['type']),
        ['label', 'label', 'tracker', 'tracker', 'tracker']);
    expect(jsonEncode(document), isNot(contains('"id"')));
  });

  test('keeps entry text exactly as written', () async {
    final document = await documentOf(kitchenSinkSnapshot());

    final entries = (document['entries'] as List).cast<Map>();
    expect(entries[0]['text'], hardText);
    expect(entries[1]['text'], '- starts with a dash\n=1+1');
  });

  test('writes local wall-clock times without a zone', () async {
    final document = await documentOf(kitchenSinkSnapshot());

    final entry = (document['entries'] as List).first as Map;
    expect(entry['timeCreate'], '2026-03-04T08:30:00.000');
    expect(entry['timeModified'], '2026-03-04T09:00:00.000');
  });

  test('lists entry tags with numeric tracker values', () async {
    final document = await documentOf(kitchenSinkSnapshot());

    final entries = (document['entries'] as List).cast<Map>();
    expect((entries[0]['tags'] as List).cast<Map>().map((tag) => tag['value']),
        [null, null, 3, 7.5, 1]);
    expect(entries[1]['tags'], isEmpty);
    expect(entries[1]['mood'], isNull);
    expect((entries[2]['tags'] as List).single, containsPair('value', isNull));
  });

  test('points each attachment at its path inside the archive', () async {
    final sources = await writeJson(kitchenSinkSnapshot(), store);

    final document =
        jsonDecode(utf8.decode((await store.read(jsonDocumentName))!))
            as Map<String, Object?>;
    final attachments =
        ((document['entries'] as List).first as Map)['attachments'] as List;
    expect(attachments.map((attachment) => attachment['path']), [
      'Video/video_2026-03-04_2.mp4',
      'Images/image_2026-03-04_1.png',
      'Audio/audio_2026-03-04_0.m4a',
    ]);
    expect(sources, {
      'Video/video_2026-03-04_2.mp4': '/data/Video/clip.mp4',
      'Images/image_2026-03-04_1.png': '/data/Images/photo.png',
      'Audio/audio_2026-03-04_0.m4a': '/data/Audio/memo.m4a',
    });
  });

  test('uses the same attachment names for a same-day second entry', () async {
    final snapshot = snapshotOf([
      for (final hour in [8, 9])
        exportEntry(DateTime(2026, 3, 4, hour), attachments: [
          exportAttachment(AttachmentType.image, '/data/a.png'),
        ])
    ]);

    final sources = await writeJson(snapshot, store);

    expect(sources.keys, [
      'Images/image_2026-03-04_0.png',
      'Images/image_2026-03-04_2_0.png',
    ]);
  });
}
