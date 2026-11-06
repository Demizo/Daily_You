// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/mood.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/stats/entry_stats.dart';
import 'package:daily_you/stats/stats_range.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final bad = Mood.levels[1];
  final neutral = Mood.levels[2];
  final best = Mood.levels.last;

  Entry entryAt(DateTime time, {int? id, int? mood, String text = ''}) => Entry(
      id: id, text: text, mood: mood, timeCreate: time, timeModified: time);

  double? moodPosition(Entry entry) =>
      entry.mood == null ? null : Mood.position(entry.mood!).toDouble();

  EntryTag entryTag(int entryId, int tagId, {String? value}) => EntryTag(
      entryId: entryId,
      tagId: tagId,
      value: value,
      timeCreate: DateTime(2025, 1, 1));

  test('averages values per weekday and marks the empty ones', () {
    // 2025-06-02 is a Monday.
    final averages = averageByDayOfWeek(
      [
        entryAt(DateTime(2025, 6, 2), mood: best),
        entryAt(DateTime(2025, 6, 9), mood: neutral),
        entryAt(DateTime(2025, 6, 3), mood: bad),
      ],
      moodPosition,
    );

    expect(averages['Mon'], 3.0);
    expect(averages['Tue'], 1.0);
    expect(averages['Wed'], isNull);
  });

  test('falls back to the empty day value where nothing was written', () {
    final averages = averageByDayOfWeek(
      [entryAt(DateTime(2025, 6, 2), mood: best)],
      moodPosition,
      emptyDayValue: -1,
    );

    expect(averages['Mon'], 4.0);
    expect(averages['Sun'], -1.0);
  });

  test('counts matching entries per weekday', () {
    final counts = countByDayOfWeek(
      [
        entryAt(DateTime(2025, 6, 2), mood: best),
        entryAt(DateTime(2025, 6, 9), mood: best),
        entryAt(DateTime(2025, 6, 3), mood: bad),
      ],
      (entry) => Mood.isGreatDay(entry.mood),
    );

    expect(counts['Mon'], 2.0);
    expect(counts['Tue'], 0.0);
  });

  test('reads tracker values only for entries in the set', () {
    final entries = [entryAt(DateTime(2025, 6, 2), id: 1)];
    final values = trackerValuesByEntry(
      entries,
      [
        entryTag(1, 7, value: '3.5'),
        entryTag(1, 8, value: '9'),
        entryTag(2, 7, value: '4'),
        entryTag(1, 7, value: 'not a number'),
      ],
      7,
    );

    expect(values, {1: 3.5});
  });

  test('collects the entries carrying a label', () {
    final ids = entryIdsWithTag(
      [entryTag(1, 7), entryTag(2, 8), entryTag(3, 7)],
      7,
    );

    expect(ids, {1, 3});
  });

  test('anchors the tracker range at zero unless values go negative', () {
    expect(trackerYRange([]), (0.0, 10.0));
    expect(trackerYRange([2, 8]), (0.0, 8.0));
    expect(trackerYRange([-3, 5]), (-3.0, 5.0));
  });

  test('keeps only the entries inside the range', () {
    final entries = [
      entryAt(DateTime(2025, 6, 1)),
      entryAt(DateTime(2025, 3, 1)),
      entryAt(DateTime(2024, 1, 1)),
    ];
    final now = DateTime(2025, 6, 15);

    expect(entriesInRange(entries, StatsRange.month, now: now), hasLength(1));
    expect(
        entriesInRange(entries, StatsRange.sixMonths, now: now), hasLength(2));
    expect(entriesInRange(entries, StatsRange.allTime, now: now), hasLength(3));
  });
}
