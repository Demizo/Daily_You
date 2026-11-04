// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/mood.dart';
import 'package:daily_you/utils/imports/import_bundle.dart';
import 'package:daily_you/utils/imports/import_registry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/import_fixtures.dart';
import '../../support/pinned_time_zone.dart';

void main() {
  usePinnedTimeZone();

  late ImportBundle bundle;

  setUpAll(() async => bundle = await parseFixture(ImportFormat.pixels));

  test('matches the expected bundle', () async {
    await expectMatchesExpectedBundle(ImportFormat.pixels, bundle);
  });

  test('is a valid bundle', () => expectValidBundle(bundle));

  test('maps scores from worst to best and averages them down', () {
    expect(
        bundle.entries.map((imported) => imported.entry.mood),
        equals([
          Mood.veryUnpleasant,
          Mood.veryPleasant,
          Mood.neutral,
          Mood.unpleasant,
          Mood.pleasant,
        ]));
  });

  test('skips entries that are not moods', () {
    expect(bundle.entries.map((imported) => imported.entry.text),
        isNot(contains('Not a mood entry')));
  });

  test('dates an entry at local midnight of its day', () {
    expect(bundle.entries.first.entry.timeCreate, DateTime(2026, 1, 2));
    expect(bundle.entries.first.entry.timeCreate.isUtc, isFalse);
  });

  test('uses the notes as the text', () {
    expect(
        bundle.entries.map((imported) => imported.entry.text),
        equals([
          'Worst day',
          '',
          'Scores are averaged and rounded down',
          '',
          'Duplicate day'
        ]));
  });
}
