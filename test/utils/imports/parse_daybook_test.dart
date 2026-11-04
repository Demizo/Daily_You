// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:daily_you/utils/imports/import_bundle.dart';
import 'package:daily_you/utils/imports/import_daybook.dart';
import 'package:daily_you/utils/imports/import_registry.dart';
import 'package:daily_you/utils/imports/import_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' show basename, join;

import '../../support/import_fixtures.dart';
import '../../support/pinned_time_zone.dart';

void main() {
  usePinnedTimeZone();

  late ImportBundle bundle;

  setUpAll(() async => bundle = await parseFixture(ImportFormat.daybook));

  test('matches the expected bundle', () async {
    await expectMatchesExpectedBundle(ImportFormat.daybook, bundle);
  });

  test('is a valid bundle', () => expectValidBundle(bundle));

  test('reads the written minute as local wall-clock time', () {
    expect(bundle.entries.first.entry.timeCreate, DateTime(2026, 1, 2, 9));
    expect(bundle.entries[1].entry.timeCreate, DateTime(2026, 1, 2, 21, 30));
  });

  test('builds the text from the title and text', () {
    expect(
        bundle.entries.map((imported) => imported.entry.text).take(3),
        equals([
          '# Morning\n\nWrote, with a comma',
          'Evening text only',
          '# Title only'
        ]));
    expect(
        bundle.entries.last.entry.text, '# Multi line\n\nline one\nline two');
  });

  test('has no mood', () {
    expect(bundle.entries.map((imported) => imported.entry.mood),
        everyElement(isNull));
  });

  test('ranks images in the listed order and skips missing files', () {
    final photos = bundle.entries[3].attachments;

    expect(
        photos.map((photo) => basename((photo.media as FileMedia).file.path)),
        equals(['b.jpg', 'a.jpg']));
    expect(photos.map((photo) => photo.rank), equals([0, 1]));
    expect(bundle.entries[5].attachments, isEmpty);
  });

  test('skips rows without a date', () {
    expect(bundle.entries.map((imported) => imported.entry.text),
        isNot(contains(contains('Skipped'))));
  });

  group('rejects', () {
    late Directory directory;

    setUp(
        () => directory = Directory.systemTemp.createTempSync('parse_daybook'));
    tearDown(() => directory.deleteSync(recursive: true));

    Future<void> parseCsv(String? content) {
      if (content != null) {
        File(join(directory.path, 'entries.csv')).writeAsStringSync(content);
      }
      return parseDaybook(ImportSource(directory.path, 'daybook.zip'));
    }

    test('an archive without entries.csv', () {
      expect(parseCsv(null), throwsException);
    });

    test('a file with an unexpected header', () {
      expect(parseCsv('Day,Note\n1,2\n'), throwsException);
    });

    test('a date in another layout', () {
      expect(parseCsv('Date,Title,Text,Images\n2026/01/02,a,b,\n'),
          throwsFormatException);
    });
  });
}
