// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/mood.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/stats/stats_analysis.dart';
import 'package:daily_you/stats/stats_range.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 28, 20);

  Entry entryAt(DateTime time, {int? id, int? mood, String text = ''}) => Entry(
        id: id,
        text: text,
        mood: mood,
        timeCreate: time,
        timeModified: time,
      );

  Tag tagOf(int id, TagType type) => Tag(
        id: id,
        name: 'tag$id',
        tagType: type,
        timeCreate: DateTime(2025, 1, 1),
        timeModified: DateTime(2025, 1, 1),
      );

  EntryTag entryTag(int entryId, int tagId, {String? value}) => EntryTag(
        entryId: entryId,
        tagId: tagId,
        value: value,
        timeCreate: DateTime(2025, 1, 1),
      );

  String words(int count) => List.filled(count, 'word').join(' ');

  List<Entry> everyDay(DateTime first, DateTime last, {String text = 'word'}) {
    final entries = <Entry>[];
    for (var day = last;
        !day.isBefore(first);
        day = DateTime(day.year, day.month, day.day - 1, 12)) {
      entries.add(entryAt(day, text: text));
    }
    return entries;
  }

  group('statsWindow', () {
    test('spans from a month ago through today', () {
      final window = statsWindow([], StatsRange.month, now: now);

      expect(window.start, DateTime(2026, 9, 28));
      expect(window.end, DateTime(2026, 10, 28));
      expect(window.dayCount, 31);
    });

    test('spans six months and a year back', () {
      expect(
        statsWindow([], StatsRange.sixMonths, now: now).start,
        DateTime(2026, 4, 28),
      );
      expect(
        statsWindow([], StatsRange.year, now: now).start,
        DateTime(2025, 10, 28),
      );
      expect(statsWindow([], StatsRange.year, now: now).dayCount, 366);
    });

    test('starts all time at the first log day', () {
      final window = statsWindow(
        [
          entryAt(DateTime(2026, 10, 20, 9)),
          entryAt(DateTime(2026, 10, 1, 23)),
        ],
        StatsRange.allTime,
        now: now,
      );

      expect(window.start, DateTime(2026, 10, 1));
      expect(window.dayCount, 28);
    });

    test('spans a year for an empty all time window', () {
      final window = statsWindow([], StatsRange.allTime, now: now);

      expect(window.start, DateTime(2025, 10, 28));
      expect(window.end, DateTime(2026, 10, 28));
      expect(window.dayCount, 366);
    });

    test('counts calendar days across a daylight saving change', () {
      final window = statsWindow(
        [],
        StatsRange.sixMonths,
        now: DateTime(2026, 11, 2, 8),
      );

      expect(window.dayCount, 185);
    });

    test('extends the end to a log written after today', () {
      final window = statsWindow(
        [entryAt(DateTime(2026, 10, 30, 8))],
        StatsRange.month,
        now: now,
      );

      expect(window.end, DateTime(2026, 10, 30));
      expect(window.dayCount, 33);
    });
  });

  group('statsDays', () {
    test('merges several logs on one day into one record', () {
      final days = statsDays(
        [
          entryAt(DateTime(2026, 10, 2, 20), text: words(3), id: 1),
          entryAt(DateTime(2026, 10, 2, 8), text: words(5), id: 2),
          entryAt(DateTime(2026, 10, 1, 9), text: words(2), id: 3),
        ],
        const [],
        const [],
      );

      expect(days.map((day) => day.date), [
        DateTime(2026, 10, 1),
        DateTime(2026, 10, 2),
      ]);
      expect(days.last.logCount, 2);
      expect(days.last.wordCount, 8);
      expect(days.last.longestLogWordCount, 5);
    });

    test('averages mood across the day logs', () {
      final days = statsDays(
        [
          entryAt(DateTime(2026, 10, 2, 20), mood: Mood.veryPleasant, id: 1),
          entryAt(DateTime(2026, 10, 2, 8), mood: Mood.neutral, id: 2),
          entryAt(DateTime(2026, 10, 1, 8), id: 3),
        ],
        const [],
        const [],
      );

      expect(days.last.mood, 3.0);
      expect(days.first.mood, isNull);
    });

    test('marks a label present when any log of the day has it', () {
      final days = statsDays(
        [
          entryAt(DateTime(2026, 10, 2, 20), id: 1),
          entryAt(DateTime(2026, 10, 2, 8), id: 2),
          entryAt(DateTime(2026, 10, 1, 8), id: 3),
        ],
        [entryTag(2, 7)],
        [tagOf(7, TagType.label)],
      );

      expect(days.last.labelTagIds, {7});
      expect(days.first.labelTagIds, isEmpty);
    });

    test('averages tracker values across the day logs', () {
      final days = statsDays(
        [
          entryAt(DateTime(2026, 10, 2, 20), id: 1),
          entryAt(DateTime(2026, 10, 2, 8), id: 2),
        ],
        [
          entryTag(1, 4, value: '2'),
          entryTag(2, 4, value: '5'),
          entryTag(2, 9, value: 'nope'),
        ],
        [tagOf(4, TagType.tracker), tagOf(9, TagType.tracker)],
      );

      expect(days.single.trackerValues, {4: 3.5});
    });
  });

  group('writingSummary', () {
    test('summarises logs, words and days for the window', () {
      final summary = writingSummary(
        [
          entryAt(DateTime(2026, 10, 27, 20), text: words(10)),
          entryAt(DateTime(2026, 10, 27, 8), text: words(20)),
          entryAt(DateTime(2026, 10, 20, 8), text: words(30)),
          entryAt(DateTime(2026, 1, 1, 8), text: words(500)),
        ],
        StatsRange.month,
        now: now,
      );

      expect(summary.logCount, 3);
      expect(summary.wordCount, 60);
      expect(summary.daysWritten, 2);
      expect(summary.averageWordsPerLog, 20);
    });

    test('counts a day once when it holds several logs', () {
      final summary = writingSummary(
        [
          entryAt(DateTime(2026, 10, 27, 20)),
          entryAt(DateTime(2026, 10, 27, 8)),
          entryAt(DateTime(2026, 10, 27, 7)),
        ],
        StatsRange.month,
        now: now,
      );

      expect(summary.logCount, 3);
      expect(summary.daysWritten, 1);
    });

    test('finds the longest log and its date', () {
      final summary = writingSummary(
        [
          entryAt(DateTime(2026, 10, 27, 20), text: words(10)),
          entryAt(DateTime(2026, 10, 20, 8), text: words(40)),
          entryAt(DateTime(2026, 10, 12, 8), text: words(40)),
          entryAt(DateTime(2026, 10, 10, 8), text: words(5)),
        ],
        StatsRange.month,
        now: now,
      );

      expect(summary.longestLog?.wordCount, 40);
      expect(summary.longestLog?.date, DateTime(2026, 10, 20));
    });

    test('reports zeros and no longest log for an empty journal', () {
      final summary = writingSummary([], StatsRange.allTime, now: now);

      expect(summary.logCount, 0);
      expect(summary.wordCount, 0);
      expect(summary.daysWritten, 0);
      expect(summary.averageWordsPerLog, 0);
      expect(summary.longestLog, isNull);
      expect(summary.busiestWeekdayIndexes, isEmpty);
      expect(summary.writtenDays, isEmpty);
      expect(summary.wordSeries, everyElement(0));
      expect(summary.logSeries, everyElement(0));
      expect(summary.wordsPerLogSeries, everyElement(isNull));
    });

    test('collects every day with a log', () {
      final summary = writingSummary(
        [
          entryAt(DateTime(2026, 10, 28, 7)),
          entryAt(DateTime(2026, 10, 26, 7)),
          entryAt(DateTime(2026, 10, 24, 7)),
        ],
        StatsRange.allTime,
        now: now,
      );

      expect(summary.writtenDays, {
        DateTime(2026, 10, 28),
        DateTime(2026, 10, 26),
        DateTime(2026, 10, 24),
      });
    });

    test('keeps written days from before the window', () {
      final summary = writingSummary(
        [
          entryAt(DateTime(2026, 10, 20, 7)),
          entryAt(DateTime(2026, 8, 15, 7)),
        ],
        StatsRange.month,
        now: now,
      );

      expect(summary.daysWritten, 1);
      expect(summary.writtenDays, {
        DateTime(2026, 10, 20),
        DateTime(2026, 8, 15),
      });
    });

    test('counts logs per weekday starting on Monday', () {
      final summary = writingSummary(
        [
          entryAt(DateTime(2026, 10, 26, 9)),
          entryAt(DateTime(2026, 10, 19, 9)),
          entryAt(DateTime(2026, 10, 28, 9)),
        ],
        StatsRange.month,
        now: now,
      );

      expect(summary.logsByWeekday, [2, 0, 1, 0, 0, 0, 0]);
    });

    group('busiest weekday', () {
      Entry onWeekday(DateTime base, int weekdayIndex, int week) => entryAt(
            DateTime(
                base.year, base.month, base.day + weekdayIndex - 7 * week, 12),
          );

      final monday = DateTime(2026, 10, 26);

      List<Entry> weeks(List<int> logsPerWeekday, {int weekCount = 3}) => [
            for (var week = 1; week <= weekCount; week++)
              for (var weekday = 0; weekday < 7; weekday++)
                for (var log = 0; log < logsPerWeekday[weekday]; log++)
                  onWeekday(monday, weekday, week),
          ];

      List<int> busiest(List<Entry> entries) => writingSummary(
            entries,
            StatsRange.allTime,
            now: now,
          ).busiestWeekdayIndexes;

      test('is none when every weekday is equal', () {
        expect(busiest(weeks([1, 1, 1, 1, 1, 1, 1])), isEmpty);
      });

      test('is none with under two weeks of data', () {
        final entries = [
          for (var offset = 0; offset < 13; offset++)
            entryAt(DateTime(2026, 10, 28 - offset, 12)),
        ];
        entries.add(entryAt(DateTime(2026, 10, 28, 9)));

        expect(busiest(entries), isEmpty);
      });

      test('is the single winner', () {
        expect(busiest(weeks([1, 1, 3, 1, 1, 1, 1])), [2]);
      });

      test('lists both weekdays of a two way tie', () {
        expect(busiest(weeks([1, 1, 2, 2, 1, 1, 1])), [2, 3]);
      });

      test('is none for a three way tie at the top', () {
        expect(busiest(weeks([2, 1, 2, 1, 2, 1, 1])), isEmpty);
      });
    });

    group('bucketing', () {
      test('fills a fixed number of buckets', () {
        final summary = writingSummary(
          everyDay(DateTime(2026, 9, 1, 12), now, text: words(4)),
          StatsRange.allTime,
          now: now,
        );

        expect(summary.wordSeries.length, sparklineBucketCount);
        expect(summary.wordsPerLogSeries.length, sparklineBucketCount);
        expect(summary.logSeries.length, frequencyBucketCount);
        expect(
          summary.wordSeries.reduce((a, b) => a + b),
          closeTo(4 * 58, 1e-9),
        );
        expect(summary.logSeries.reduce((a, b) => a + b), closeTo(58, 1e-9));
        expect(
          summary.wordsPerLogSeries.whereType<double>(),
          everyElement(closeTo(4.0, 1e-9)),
        );
      });

      test('spreads a single log evenly across the buckets', () {
        final summary = writingSummary(
          [entryAt(DateTime(2026, 10, 28, 9), text: words(7))],
          StatsRange.allTime,
          now: now,
        );

        expect(summary.logSeries.reduce((a, b) => a + b), closeTo(1, 1e-9));
        expect(
          summary.logSeries,
          everyElement(closeTo(1 / frequencyBucketCount, 1e-9)),
        );
        expect(summary.wordSeries.reduce((a, b) => a + b), closeTo(7, 1e-9));
        expect(
          summary.wordsPerLogSeries.whereType<double>(),
          everyElement(closeTo(7, 1e-9)),
        );
      });

      test('weighs buckets evenly when days do not divide into them', () {
        final summary = writingSummary(
          everyDay(DateTime(2026, 10, 1, 12), now),
          StatsRange.allTime,
          now: now,
        );

        expect(summary.logSeries, everyElement(closeTo(2, 1e-9)));
      });

      test('keeps the first and last day inside the outer buckets', () {
        final summary = writingSummary(
          [
            entryAt(DateTime(2026, 10, 1, 9)),
            entryAt(DateTime(2026, 10, 28, 9)),
          ],
          StatsRange.allTime,
          now: now,
        );

        expect(summary.logSeries.first, closeTo(1, 1e-9));
        expect(summary.logSeries.last, closeTo(1, 1e-9));
      });
    });
  });

  group('recentDaysWritten', () {
    test('lists the last days oldest first with today last', () {
      final flags = recentDaysWritten(
        [
          entryAt(DateTime(2026, 10, 28, 7)),
          entryAt(DateTime(2026, 10, 27, 23)),
          entryAt(DateTime(2026, 10, 25, 7)),
          entryAt(DateTime(2026, 10, 1, 7)),
        ],
        now: now,
        dayCount: 5,
      );

      expect(flags, [false, true, false, true, true]);
    });

    test('defaults to fourteen days', () {
      expect(recentDaysWritten([], now: now), hasLength(14));
    });
  });

  group('priorStatsWindow', () {
    test('spans the same length right before the range', () {
      final month = priorStatsWindow([], StatsRange.month, now: now)!;

      expect(month.start, DateTime(2026, 8, 28));
      expect(month.end, DateTime(2026, 9, 27));
      expect(month.dayCount, 31);
    });

    test('ends the day before six months and a year ranges start', () {
      final sixMonths = priorStatsWindow([], StatsRange.sixMonths, now: now)!;
      final year = priorStatsWindow([], StatsRange.year, now: now)!;

      expect(sixMonths.end, DateTime(2026, 4, 27));
      expect(sixMonths.dayCount, 184);
      expect(year.end, DateTime(2025, 10, 27));
      expect(year.dayCount, 366);
      expect(year.start, DateTime(2024, 10, 27));
    });

    test('is not available for all time', () {
      expect(priorStatsWindow([], StatsRange.allTime, now: now), isNull);
    });
  });

  group('weekdayDisplayOrder', () {
    test('starts on the first day of the week', () {
      expect(weekdayDisplayOrder(0), [0, 1, 2, 3, 4, 5, 6]);
      expect(weekdayDisplayOrder(6), [6, 0, 1, 2, 3, 4, 5]);
      expect(weekdayDisplayOrder(5), [5, 6, 0, 1, 2, 3, 4]);
    });
  });

  group('moodByWeekday', () {
    final entries = [
      entryAt(DateTime(2026, 10, 26, 9), mood: Mood.veryPleasant),
      entryAt(DateTime(2026, 10, 19, 9), mood: Mood.veryUnpleasant),
      entryAt(DateTime(2026, 10, 27, 20), mood: Mood.unpleasant),
      entryAt(DateTime(2026, 10, 27, 8), mood: Mood.neutral),
    ];

    List<WeekdayMood> grouped(int firstDayIndex) => moodByWeekday(
          entries,
          StatsRange.month,
          firstDayIndex: firstDayIndex,
          now: now,
        );

    test('counts the day mood tiers per weekday', () {
      final monday = grouped(0).first;
      final tuesday = grouped(0)[1];

      expect(monday.tierCounts, [1, 0, 0, 0, 1]);
      expect(monday.meanMood, 2.0);
      expect(tuesday.tierCounts, [0, 0, 1, 0, 0]);
      expect(tuesday.meanMood, 1.5);
      expect(grouped(0)[2].meanMood, isNull);
    });

    test('orders weekdays from a Monday, Sunday or Saturday week start', () {
      List<int> order(int firstDayIndex) =>
          grouped(firstDayIndex).map((day) => day.weekdayIndex).toList();

      expect(order(0), [0, 1, 2, 3, 4, 5, 6]);
      expect(order(6), [6, 0, 1, 2, 3, 4, 5]);
      expect(order(5), [5, 6, 0, 1, 2, 3, 4]);
      expect(grouped(6).first.tierCounts, [0, 0, 0, 0, 0]);
      expect(grouped(6)[1].tierCounts, [1, 0, 0, 0, 1]);
    });
  });

  group('labelSummary', () {
    final label = tagOf(7, TagType.label);

    LabelSummary summaryOf(
      List<Entry> entries,
      List<EntryTag> entryTags, {
      StatsRange range = StatsRange.month,
      DateTime? at,
    }) =>
        labelSummary(entries, entryTags, [label], 7, range, now: at ?? now);

    test('counts logged days and not logs', () {
      final summary = summaryOf(
        [
          entryAt(DateTime(2026, 10, 27, 20), id: 1),
          entryAt(DateTime(2026, 10, 27, 8), id: 2),
          entryAt(DateTime(2026, 10, 26, 8), id: 3),
        ],
        [entryTag(1, 7), entryTag(2, 7)],
      );

      expect(summary.daysPresent, 1);
      expect(summary.daysAbsent, 1);
      expect(summary.presentFraction, 0.5);
    });

    test('lists present days', () {
      final summary = summaryOf(
        [
          entryAt(DateTime(2026, 10, 28, 8), id: 1),
          entryAt(DateTime(2026, 10, 27, 8), id: 2),
        ],
        [entryTag(1, 7)],
        range: StatsRange.allTime,
      );

      expect(summary.presentDays, {DateTime(2026, 10, 28)});
      expect(summary.window.start, DateTime(2026, 10, 27));
    });

    test('keeps present and logged days from before the window', () {
      final summary = summaryOf(
        [
          entryAt(DateTime(2026, 10, 20, 8), id: 1),
          entryAt(DateTime(2026, 8, 15, 8), id: 2),
          entryAt(DateTime(2026, 8, 14, 8), id: 3),
        ],
        [entryTag(2, 7)],
      );

      expect(summary.daysPresent, 0);
      expect(summary.daysAbsent, 1);
      expect(summary.presentDays, {DateTime(2026, 8, 15)});
    });

    test('finds the best streak across a month boundary', () {
      final days = [
        DateTime(2026, 9, 29, 8),
        DateTime(2026, 9, 30, 8),
        DateTime(2026, 10, 1, 8),
        DateTime(2026, 10, 2, 8),
        DateTime(2026, 10, 5, 8),
        DateTime(2026, 10, 6, 8),
      ];
      final summary = summaryOf(
        [for (final (index, day) in days.indexed) entryAt(day, id: index)],
        [for (var index = 0; index < days.length; index++) entryTag(index, 7)],
      );

      expect(summary.bestStreak, 4);
    });

    test('keeps a streak going across a daylight saving change', () {
      final days = [
        DateTime(2026, 10, 31, 23),
        DateTime(2026, 11, 1, 0, 30),
        DateTime(2026, 11, 2, 23, 30),
        DateTime(2026, 11, 3, 0, 15),
      ];
      final summary = summaryOf(
        [for (final (index, day) in days.indexed) entryAt(day, id: index)],
        [for (var index = 0; index < days.length; index++) entryTag(index, 7)],
        at: DateTime(2026, 11, 5, 12),
      );

      expect(summary.bestStreak, 4);
    });

    group('trend', () {
      Entry entryOn(DateTime day, int id) => entryAt(day, id: id);

      LabelSummary trendOf({
        required int priorDays,
        required int priorPresent,
        required int currentDays,
        required int currentPresent,
        StatsRange range = StatsRange.month,
      }) {
        final entries = <Entry>[];
        final links = <EntryTag>[];
        for (var index = 0; index < priorDays; index++) {
          entries.add(entryOn(DateTime(2026, 9, 1 + index, 12), index));
          if (index < priorPresent) links.add(entryTag(index, 7));
        }
        for (var index = 0; index < currentDays; index++) {
          final id = 100 + index;
          entries.add(entryOn(DateTime(2026, 10, 1 + index, 12), id));
          if (index < currentPresent) links.add(entryTag(id, 7));
        }
        return summaryOf(entries, links, range: range);
      }

      test('rises in percentage points', () {
        final summary = trendOf(
          priorDays: 10,
          priorPresent: 2,
          currentDays: 10,
          currentPresent: 5,
        );

        expect(summary.trendPoints, 30);
      });

      test('falls in percentage points', () {
        final summary = trendOf(
          priorDays: 10,
          priorPresent: 5,
          currentDays: 10,
          currentPresent: 2,
        );

        expect(summary.trendPoints, -30);
      });

      test('rounds to whole points', () {
        final summary = trendOf(
          priorDays: 6,
          priorPresent: 3,
          currentDays: 3,
          currentPresent: 2,
        );

        expect(summary.trendPoints, 17);
      });

      test('is hidden when the change is zero', () {
        final summary = trendOf(
          priorDays: 6,
          priorPresent: 2,
          currentDays: 3,
          currentPresent: 1,
        );

        expect(summary.trendPoints, isNull);
      });

      test('is hidden when the prior period has under five logged days', () {
        final summary = trendOf(
          priorDays: 4,
          priorPresent: 0,
          currentDays: 10,
          currentPresent: 5,
        );

        expect(summary.trendPoints, isNull);
      });

      test('is hidden for all time', () {
        final summary = trendOf(
          priorDays: 10,
          priorPresent: 2,
          currentDays: 10,
          currentPresent: 5,
          range: StatsRange.allTime,
        );

        expect(summary.trendPoints, isNull);
      });
    });
  });

  group('trackerSummary', () {
    final tracker = tagOf(4, TagType.tracker);

    TrackerSummary summaryOf(
      List<Entry> entries,
      List<EntryTag> entryTags, {
      StatsRange range = StatsRange.month,
    }) =>
        trackerSummary(entries, entryTags, [tracker], 4, range, now: now);

    test('reports the average, highest, lowest and logged days', () {
      final summary = summaryOf(
        [
          entryAt(DateTime(2026, 10, 27, 20), id: 1),
          entryAt(DateTime(2026, 10, 27, 8), id: 2),
          entryAt(DateTime(2026, 10, 26, 8), id: 3),
          entryAt(DateTime(2026, 10, 25, 8), id: 4),
        ],
        [
          entryTag(1, 4, value: '2'),
          entryTag(2, 4, value: '4'),
          entryTag(3, 4, value: '9'),
          entryTag(4, 4, value: '1'),
        ],
      );

      expect(summary.average, 13 / 3);
      expect(summary.highest, 9);
      expect(summary.lowest, 1);
      expect(summary.daysLogged, 3);
    });

    test('uses the same value for highest and lowest with one value', () {
      final summary = summaryOf(
        [entryAt(DateTime(2026, 10, 27, 8), id: 1)],
        [entryTag(1, 4, value: '6')],
      );

      expect(summary.average, 6);
      expect(summary.highest, 6);
      expect(summary.lowest, 6);
      expect(summary.daysLogged, 1);
    });

    test('has no numbers without values', () {
      final summary = summaryOf([entryAt(DateTime(2026, 10, 27, 8))], []);

      expect(summary.average, isNull);
      expect(summary.highest, isNull);
      expect(summary.lowest, isNull);
      expect(summary.daysLogged, 0);
      expect(summary.trend, isNull);
    });

    group('trend', () {
      TrackerSummary trendOf({
        required int priorDays,
        required double priorValue,
        required double currentValue,
        StatsRange range = StatsRange.month,
      }) {
        final entries = <Entry>[];
        final links = <EntryTag>[];
        for (var index = 0; index < priorDays; index++) {
          entries.add(entryAt(DateTime(2026, 9, 1 + index, 12), id: index));
          links.add(entryTag(index, 4, value: '$priorValue'));
        }
        for (var index = 0; index < 6; index++) {
          final id = 100 + index;
          entries.add(entryAt(DateTime(2026, 10, 1 + index, 12), id: id));
          links.add(entryTag(id, 4, value: '$currentValue'));
        }
        return summaryOf(entries, links, range: range);
      }

      test('rises by the change in the average to one decimal', () {
        final summary = trendOf(
          priorDays: 5,
          priorValue: 4.0,
          currentValue: 4.3,
        );

        expect(summary.trend, 0.3);
      });

      test('falls by the change in the average', () {
        final summary = trendOf(
          priorDays: 5,
          priorValue: 4.0,
          currentValue: 3.0,
        );

        expect(summary.trend, -1.0);
      });

      test('is hidden when the change rounds to zero', () {
        final summary = trendOf(
          priorDays: 5,
          priorValue: 4.0,
          currentValue: 4.04,
        );

        expect(summary.trend, isNull);
      });

      test('is hidden when the prior period has under five logged days', () {
        final summary = trendOf(
          priorDays: 4,
          priorValue: 4.0,
          currentValue: 6.0,
        );

        expect(summary.trend, isNull);
      });

      test('is hidden for all time', () {
        final summary = trendOf(
          priorDays: 5,
          priorValue: 4.0,
          currentValue: 6.0,
          range: StatsRange.allTime,
        );

        expect(summary.trend, isNull);
      });
    });
  });

  group('moodSummary', () {
    test('lists the day mean of each logged day with a mood', () {
      final summary = moodSummary(
        [
          entryAt(DateTime(2026, 10, 27, 20), mood: Mood.veryPleasant),
          entryAt(DateTime(2026, 10, 27, 8), mood: Mood.neutral),
          entryAt(DateTime(2026, 10, 26, 8), mood: Mood.unpleasant),
          entryAt(DateTime(2026, 10, 25, 8)),
        ],
        StatsRange.month,
        now: now,
      );

      expect(summary.dayMeans, [
        (date: DateTime(2026, 10, 26), value: 1.0),
        (date: DateTime(2026, 10, 27), value: 3.0),
      ]);
    });

    test('shares the logged moods among the mood tiers', () {
      final summary = moodSummary(
        [
          entryAt(DateTime(2026, 10, 27, 20), mood: Mood.veryPleasant),
          entryAt(DateTime(2026, 10, 26, 8), mood: Mood.veryPleasant),
          entryAt(DateTime(2026, 10, 25, 8), mood: Mood.neutral),
          entryAt(DateTime(2026, 10, 24, 8), mood: Mood.veryUnpleasant),
        ],
        StatsRange.month,
        now: now,
      );

      expect(summary.tierCounts, [1, 0, 1, 0, 2]);
      expect(summary.tierShares, [0.25, 0, 0.25, 0, 0.5]);
    });

    test('counts every log of a day in its own tier', () {
      final summary = moodSummary(
        [
          entryAt(DateTime(2026, 10, 27, 20), mood: Mood.veryPleasant),
          entryAt(DateTime(2026, 10, 27, 8), mood: Mood.neutral),
        ],
        StatsRange.month,
        now: now,
      );

      expect(summary.tierCounts, [0, 0, 1, 0, 1]);
      expect(summary.dayMeans, [(date: DateTime(2026, 10, 27), value: 3.0)]);
    });

    test('is empty without logged moods', () {
      final summary = moodSummary(
        [entryAt(DateTime(2026, 10, 27, 8))],
        StatsRange.month,
        now: now,
      );

      expect(summary.dayMeans, isEmpty);
      expect(summary.moodCount, 0);
      expect(summary.tierShares, [0, 0, 0, 0, 0]);
    });
  });

  group('tagTileSummaries', () {
    final label = tagOf(7, TagType.label);
    final tracker = tagOf(4, TagType.tracker);

    Map<int, TagTileSummary> summariesOf(
      List<Entry> entries,
      List<EntryTag> entryTags, {
      List<int> tagIds = const [7, 4],
      StatsRange range = StatsRange.month,
    }) =>
        tagTileSummaries(
          entries,
          entryTags,
          [label, tracker],
          tagIds,
          range,
          now: now,
        );

    test('reports a label as the share of logged days', () {
      final summaries = summariesOf(
        [
          entryAt(DateTime(2026, 10, 27, 20), id: 1),
          entryAt(DateTime(2026, 10, 27, 8), id: 2),
          entryAt(DateTime(2026, 10, 26, 8), id: 3),
        ],
        [entryTag(1, 7), entryTag(2, 7)],
      );

      expect(summaries[7]!.value, 0.5);
    });

    test('reports a tracker as the mean of its day values', () {
      final summaries = summariesOf(
        [
          entryAt(DateTime(2026, 10, 27, 20), id: 1),
          entryAt(DateTime(2026, 10, 27, 8), id: 2),
          entryAt(DateTime(2026, 10, 26, 8), id: 3),
        ],
        [
          entryTag(1, 4, value: '2'),
          entryTag(2, 4, value: '4'),
          entryTag(3, 4, value: '9'),
        ],
      );

      expect(summaries[4]!.value, 6);
    });

    test('reports a label that was only used before the range as zero', () {
      final summaries = summariesOf(
        [
          entryAt(DateTime(2026, 8, 1, 8), id: 1),
          entryAt(DateTime(2026, 10, 27, 8), id: 2),
        ],
        [entryTag(1, 7)],
      );

      expect(summaries[7]!.value, 0);
    });

    test('reports no value for a label that was never used', () {
      final summaries = summariesOf([entryAt(DateTime(2026, 10, 27, 8))], []);

      expect(summaries[7]!.value, isNull);
    });

    test('reports no value for a tracker with a single day of values', () {
      final summaries = summariesOf(
        [entryAt(DateTime(2026, 10, 27, 8), id: 1)],
        [entryTag(1, 4, value: '3')],
      );

      expect(summaries[4]!.value, isNull);
    });

    test('keeps the requested tags and skips ids that are not tags', () {
      final summaries = summariesOf(
        [entryAt(DateTime(2026, 10, 27, 8))],
        [],
        tagIds: [4, 99],
      );

      expect(summaries.keys, [4]);
    });

    test('carries the trend of the solo summaries', () {
      final entries = <Entry>[];
      final links = <EntryTag>[];
      for (var index = 0; index < 5; index++) {
        entries.add(entryAt(DateTime(2026, 9, 1 + index, 12), id: index));
        links.add(entryTag(index, 4, value: '4'));
        links.add(entryTag(index, 7));
      }
      for (var index = 0; index < 6; index++) {
        final id = 100 + index;
        entries.add(entryAt(DateTime(2026, 10, 1 + index, 12), id: id));
        links.add(entryTag(id, 4, value: '5'));
      }

      final summaries = summariesOf(entries, links);

      expect(summaries[4]!.trend, 1.0);
      expect(summaries[7]!.trend, -100);
    });

    test('has a dash and flat series for an empty window', () {
      final summaries = summariesOf([], []);

      expect(summaries[7]!.value, isNull);
      expect(summaries[7]!.trend, isNull);
      expect(summaries[7]!.series, List.filled(frequencyBucketCount, 0.0));
      expect(summaries[4]!.value, isNull);
      expect(summaries[4]!.series, List.filled(sparklineBucketCount, null));
    });

    test('buckets a label into frequency counts that sum to its days', () {
      final entries = <Entry>[];
      final links = <EntryTag>[];
      for (var index = 0; index < 28; index++) {
        entries.add(entryAt(DateTime(2026, 10, 1 + index, 12), id: index));
        if (index.isEven) links.add(entryTag(index, 7));
      }

      final series = summariesOf(entries, links)[7]!.series;

      expect(series, hasLength(frequencyBucketCount));
      expect(
        series.whereType<double>().fold(0.0, (a, b) => a + b),
        closeTo(14, 1e-9),
      );
    });

    test('buckets a tracker into means with gaps where nothing was logged', () {
      final entries = <Entry>[];
      final links = <EntryTag>[];
      for (var index = 0; index < 20; index++) {
        entries.add(entryAt(DateTime(2026, 10, 1 + index, 12), id: index));
        if (index < 10) links.add(entryTag(index, 4, value: '${index + 1}'));
      }

      final series = summariesOf(
        entries,
        links,
        range: StatsRange.allTime,
      )[4]!
          .series;

      expect(series, hasLength(sparklineBucketCount));
      expect(series.first, closeTo(8 / 7, 1e-9));
      expect(
        series.whereType<double>().reduce((a, b) => a > b ? a : b),
        closeTo(10, 1e-9),
      );
      expect(series.last, isNull);
    });

    test('averages two logs on one day before bucketing', () {
      final series = summariesOf(
        [
          entryAt(DateTime(2026, 10, 27, 20), id: 1),
          entryAt(DateTime(2026, 10, 27, 8), id: 2),
        ],
        [entryTag(1, 4, value: '2'), entryTag(2, 4, value: '4')],
        range: StatsRange.allTime,
      )[4]!
          .series;

      expect(series.whereType<double>(), everyElement(closeTo(3, 1e-9)));
    });
  });

  group('hasEnoughChartData', () {
    test('needs at least two data points', () {
      expect(hasEnoughChartData(0), isFalse);
      expect(hasEnoughChartData(1), isFalse);
      expect(hasEnoughChartData(2), isTrue);
      expect(hasEnoughChartData(200), isTrue);
    });
  });
}
