// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/mood.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('levels run from worst to best', () {
    expect(Mood.levels, hasLength(Mood.count));
    expect(Mood.levels.map(Mood.position), [0, 1, 2, 3, 4]);
  });

  test('positions round trip through levels', () {
    for (var position = 0; position < Mood.count; position++) {
      expect(Mood.position(Mood.fromPosition(position)), position);
    }
  });

  test('the two lowest levels are bad days', () {
    expect(Mood.levels.where(Mood.isBadDay), Mood.levels.take(2));
  });

  test('the two highest levels are great days', () {
    expect(Mood.levels.where(Mood.isGreatDay), Mood.levels.skip(3));
  });

  test('ratings map onto levels, optionally best first', () {
    final ratings = [for (var rating = 1; rating <= 5; rating++) rating];

    expect(ratings.map(Mood.fromRating), Mood.levels);
    expect(
      ratings.map((rating) => Mood.fromRating(rating, bestFirst: true)),
      Mood.levels.reversed,
    );
    expect(Mood.fromRating(0), Mood.levels.first);
    expect(Mood.fromRating(9), Mood.levels.last);
  });

  test('a missing mood sorts below every level', () {
    expect(Mood.compare(null, Mood.levels.first), isNegative);
    expect(Mood.compare(Mood.levels.last, Mood.levels.first), isPositive);
    expect(Mood.compare(null, null), isZero);
  });

  test('a missing mood is neither bad nor great', () {
    expect(Mood.isBadDay(null), isFalse);
    expect(Mood.isGreatDay(null), isFalse);
  });

  test('maps the legacy scale onto the levels', () {
    expect(
      [for (var legacy = -2; legacy <= 2; legacy++) Mood.fromLegacy(legacy)],
      Mood.levels,
    );
    expect(Mood.fromLegacy(null), isNull);
  });
}
