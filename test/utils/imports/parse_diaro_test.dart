// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/mood.dart';
import 'package:daily_you/utils/imports/import_bundle.dart';
import 'package:daily_you/utils/imports/import_registry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' show basename;

import '../../support/import_fixtures.dart';
import '../../support/pinned_time_zone.dart';

void main() {
  usePinnedTimeZone();

  late ImportBundle bundle;

  setUpAll(() async => bundle = await parseFixture(ImportFormat.diaro));

  test('matches the expected bundle', () async {
    await expectMatchesExpectedBundle(ImportFormat.diaro, bundle);
  });

  test('is a valid bundle', () => expectValidBundle(bundle));

  test('ranks mood from best to worst', () {
    expect(
        bundle.entries.map((imported) => imported.entry.mood),
        equals([
          Mood.veryPleasant,
          Mood.veryUnpleasant,
          null,
          Mood.neutral,
          null,
        ]));
  });

  test('builds local wall-clock time from the instant and recorded offset', () {
    final times = bundle.entries.map((imported) => imported.entry.timeCreate);

    expect(
        times,
        equals([
          DateTime(2026, 1, 1, 22),
          DateTime(2026, 1, 2, 9, 30),
          DateTime(2026, 1, 3, 3),
          DateTime(2026, 1, 3, 5),
          DateTime(2026, 1, 3, 5),
        ]));
    expect(times.every((time) => !time.isUtc), isTrue);
  });

  test('builds the text from the title and text', () {
    expect(
        bundle.entries.map((imported) => imported.entry.text),
        equals([
          '# Best mood\n\nRecorded at UTC minus five',
          'Worst mood, text only',
          '# Title only',
          '# With photos\n\nPositions decide the order',
          '# Duplicate\n\nSame time as the entry above',
        ]));
  });

  test('ranks photos by position and skips missing files and other types', () {
    final photos = bundle.entries[3].attachments;

    expect(
        photos.map((photo) => basename((photo.media as FileMedia).file.path)),
        equals(['first.jpg', 'second.jpg']));
    expect(photos.map((photo) => photo.rank), equals([0, 1]));
    expect(bundle.entries.first.attachments, isEmpty);
  });
}
