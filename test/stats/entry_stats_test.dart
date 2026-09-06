import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/stats/entry_stats.dart';
import 'package:daily_you/stats/stats_range.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Entry entryAt(DateTime time, {int? id, int? mood, String text = ''}) => Entry(
      id: id, text: text, mood: mood, timeCreate: time, timeModified: time);

  EntryTag entryTag(int entryId, int tagId, {String? value}) => EntryTag(
      entryId: entryId,
      tagId: tagId,
      value: value,
      timeCreate: DateTime(2025, 1, 1));

  test('counts each great day once', () {
    final count = greatDayCount([
      entryAt(DateTime(2025, 6, 2, 20), mood: 2),
      entryAt(DateTime(2025, 6, 2, 8), mood: 1),
      entryAt(DateTime(2025, 6, 1), mood: 0),
      entryAt(DateTime(2025, 5, 31), mood: null),
      entryAt(DateTime(2025, 5, 30), mood: 1),
    ]);

    expect(count, 2);
  });

  test('totals every mood level including the unused ones', () {
    final totals = moodTotals([
      entryAt(DateTime(2025, 6, 2), mood: 2),
      entryAt(DateTime(2025, 6, 1), mood: 2),
      entryAt(DateTime(2025, 5, 31), mood: -2),
      entryAt(DateTime(2025, 5, 30)),
    ]);

    expect(totals, {-2: 1, -1: 0, 0: 0, 1: 0, 2: 2});
  });

  test('averages values per weekday and marks the empty ones', () {
    // 2025-06-02 is a Monday.
    final averages = averageByDayOfWeek(
      [
        entryAt(DateTime(2025, 6, 2), mood: 2),
        entryAt(DateTime(2025, 6, 9), mood: 0),
        entryAt(DateTime(2025, 6, 3), mood: -1),
      ],
      (entry) => entry.mood?.toDouble(),
    );

    expect(averages['Mon'], 1.0);
    expect(averages['Tue'], -1.0);
    expect(averages['Wed'], isNull);
  });

  test('falls back to the empty day value where nothing was written', () {
    final averages = averageByDayOfWeek(
      [entryAt(DateTime(2025, 6, 2), mood: 2)],
      (entry) => entry.mood?.toDouble(),
      emptyDayValue: -2,
    );

    expect(averages['Mon'], 2.0);
    expect(averages['Sun'], -2.0);
  });

  test('counts matching entries per weekday', () {
    final counts = countByDayOfWeek(
      [
        entryAt(DateTime(2025, 6, 2), mood: 2),
        entryAt(DateTime(2025, 6, 9), mood: 2),
        entryAt(DateTime(2025, 6, 3), mood: -1),
      ],
      (entry) => (entry.mood ?? 0) > 0,
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

  test('sums the words across every entry', () {
    expect(
        totalWordCount([
          entryAt(DateTime(2025, 6, 2), text: 'one two three'),
          entryAt(DateTime(2025, 6, 1), text: 'four'),
        ]),
        4);
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
