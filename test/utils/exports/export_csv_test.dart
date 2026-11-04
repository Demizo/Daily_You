// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/storage/in_memory_file_store.dart';
import 'package:daily_you/utils/exports/export_csv.dart';
import 'package:daily_you/utils/exports/export_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../support/export_golden.dart';
import '../../support/export_snapshots.dart';

void main() {
  late InMemoryFileStore store;

  setUpAll(() => initializeDateFormatting('en'));

  setUp(() => store = InMemoryFileStore());

  const byteOrderMark = [0xEF, 0xBB, 0xBF];

  Future<List<int>> documentBytes(ExportSnapshot snapshot) async {
    await writeCsv(snapshot, store);
    return (await store.read(csvDocumentName))!;
  }

  Future<List<Map<String, String>>> rowsOf(ExportSnapshot snapshot) async {
    final bytes = await documentBytes(snapshot);
    final table = const CsvDecoder().convert(utf8.decode(bytes.sublist(3)));
    final header = table.first.cast<String>();
    return [
      for (final row in table.skip(1))
        {
          for (final (index, name) in header.indexed)
            name: row[index].toString()
        }
    ];
  }

  test('matches the pinned file format', () async {
    await expectMatchesGolden(
        'export.csv', await documentBytes(kitchenSinkSnapshot()));
  });

  test('starts with a UTF-8 byte order mark ahead of the header', () async {
    final bytes = await documentBytes(kitchenSinkSnapshot());

    expect(bytes.sublist(0, 3), byteOrderMark);
    expect(utf8.decode(bytes.sublist(3)), startsWith('date,modified,mood,'));
  });

  test('has the fixed columns, then one column per tracker', () async {
    final bytes = await documentBytes(kitchenSinkSnapshot());

    final header =
        const CsvDecoder().convert(utf8.decode(bytes.sublist(3))).first;
    expect(header, [
      'date',
      'modified',
      'mood',
      'moodLabel',
      'text',
      'tags',
      'attachments',
      'tracker:Water',
      'tracker:Sleep',
      'tracker:date',
    ]);
  });

  test('keeps text with quotes, commas and line breaks intact', () async {
    final rows = await rowsOf(kitchenSinkSnapshot());

    expect(rows[0]['text'], hardText);
    expect(rows[1]['text'], '- starts with a dash\n=1+1');
  });

  test('keeps CRLF and LF line breaks as written', () async {
    final rows = await rowsOf(snapshotOf([
      exportEntry(DateTime(2026, 3, 4), text: 'one\r\ntwo\nthree\rfour'),
    ]));

    expect(rows.single['text'], 'one\r\ntwo\nthree\rfour');
  });

  test('writes one row per entry in snapshot order with local times', () async {
    final rows = await rowsOf(kitchenSinkSnapshot());

    expect(rows.map((row) => row['date']), [
      '2026-03-04T08:30:00.000',
      '2026-03-04T20:15:00.000',
      '2026-03-05T09:00:00.000',
    ]);
    expect(rows[0]['modified'], '2026-03-04T09:00:00.000');
  });

  test('writes the mood as a number and as its label', () async {
    final rows = await rowsOf(kitchenSinkSnapshot());

    expect(rows[0]['mood'], '4');
    expect(rows[0]['moodLabel'], 'Good: really');
    expect(rows[1]['mood'], '');
    expect(rows[1]['moodLabel'], '');
  });

  test('lists label tags and leaves trackers out of the tags column', () async {
    final rows = await rowsOf(kitchenSinkSnapshot());

    expect(rows[0]['tags'], 'Work, Gym');
    expect(rows[1]['tags'], '');
  });

  test('puts each tracker value in its own numeric column', () async {
    final rows = await rowsOf(kitchenSinkSnapshot());

    expect(rows[0]['tracker:Water'], '3');
    expect(rows[0]['tracker:Sleep'], '7.5');
    expect(rows[0]['tracker:date'], '1');
    expect(rows[1]['tracker:Water'], '');
    expect(rows[2]['tracker:Water'], '');
    expect(rows[0]['date'], '2026-03-04T08:30:00.000');
  });

  test('lists attachment paths and returns their sources', () async {
    final snapshot = kitchenSinkSnapshot();

    final sources = await writeCsv(snapshot, store);
    final rows = await rowsOf(snapshot);

    expect(rows[0]['attachments'],
        'Video/video_2026-03-04_2.mp4, Images/image_2026-03-04_1.png, Audio/audio_2026-03-04_0.m4a');
    expect(rows[1]['attachments'], '');
    expect(sources.keys, [
      'Video/video_2026-03-04_2.mp4',
      'Images/image_2026-03-04_1.png',
      'Audio/audio_2026-03-04_0.m4a',
    ]);
  });

  test('writes only the header for an empty journal', () async {
    final rows = await rowsOf(snapshotOf([]));

    expect(rows, isEmpty);
  });

  test('names a same-day second entry attachment like the other formats',
      () async {
    final sources = await writeCsv(
        snapshotOf([
          for (final hour in [8, 9])
            exportEntry(DateTime(2026, 3, 4, hour), attachments: [
              exportAttachment(AttachmentType.image, '/data/a.png'),
            ])
        ]),
        store);

    expect(sources.keys, [
      'Images/image_2026-03-04_0.png',
      'Images/image_2026-03-04_2_0.png',
    ]);
  });
}
