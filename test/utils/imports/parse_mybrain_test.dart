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

  setUpAll(() async => bundle = await parseFixture(ImportFormat.myBrain));

  test('matches the expected bundle', () async {
    await expectMatchesExpectedBundle(ImportFormat.myBrain, bundle);
  });

  test('is a valid bundle', () => expectValidBundle(bundle));

  test('maps mood names from worst to best', () {
    expect(
        bundle.entries.map((imported) => imported.entry.mood),
        equals([
          Mood.veryUnpleasant,
          Mood.veryPleasant,
          null,
          Mood.neutral,
          Mood.pleasant,
          Mood.unpleasant,
          null,
          null,
        ]));
  });

  test('joins the title and content into markdown', () {
    expect(
        bundle.entries.map((imported) => imported.entry.text).take(3),
        equals([
          '# Worst day\n\nEverything went wrong',
          'Best day, text only',
          '# Title only'
        ]));
  });

  test('converts the recorded instant to local wall-clock time', () {
    final first = bundle.entries.first.entry;

    expect(first.timeCreate, DateTime(2026, 1, 2, 10));
    expect(first.timeModified, DateTime(2026, 1, 2, 11));
    expect(first.timeCreate.isUtc, isFalse);
  });

  test('keeps two entries on one day at their own times', () {
    final first = bundle.entries[2].entry.timeCreate;
    final second = bundle.entries[3].entry.timeCreate;

    expect(first.day, second.day);
    expect(first, isNot(second));
  });
}
