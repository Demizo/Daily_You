// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math' as math;

import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/mood.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/stats/stats_range.dart';
import 'package:daily_you/utils/chart_axis.dart';
import 'package:daily_you/utils/word_counter.dart';

const int sparklineBucketCount = 24;
const int frequencyBucketCount = 14;
const int minimumChartDataPoints = 2;
const int _minimumDaysForBusiestWeekday = 14;
const int _recentDayCount = 14;
const int _minimumPriorDaysForTrend = 5;
const double _minimumBucketWeight = 1e-9;

bool hasEnoughChartData(int dataPointCount) =>
    dataPointCount >= minimumChartDataPoints;

typedef StatsWindow = ({DateTime start, DateTime end, int dayCount});

class StatsDay {
  final DateTime date;
  final int logCount;
  final int wordCount;
  final int longestLogWordCount;
  final double? mood;
  final Set<int> labelTagIds;
  final Map<int, double> trackerValues;

  const StatsDay({
    required this.date,
    required this.logCount,
    required this.wordCount,
    required this.longestLogWordCount,
    required this.mood,
    required this.labelTagIds,
    required this.trackerValues,
  });
}

class WeekdayMood {
  final int weekdayIndex;
  final List<int> tierCounts;
  final double? meanMood;

  const WeekdayMood({
    required this.weekdayIndex,
    required this.tierCounts,
    required this.meanMood,
  });
}

class LabelSummary {
  final StatsWindow window;
  final int daysPresent;
  final int daysAbsent;
  final double presentFraction;
  final int bestStreak;
  final int? trendPoints;
  final Set<DateTime> presentDays;

  const LabelSummary({
    required this.window,
    required this.daysPresent,
    required this.daysAbsent,
    required this.presentFraction,
    required this.bestStreak,
    required this.trendPoints,
    required this.presentDays,
  });
}

class TrackerSummary {
  final double? average;
  final double? highest;
  final double? lowest;
  final int daysLogged;
  final double? trend;

  const TrackerSummary({
    required this.average,
    required this.highest,
    required this.lowest,
    required this.daysLogged,
    required this.trend,
  });
}

class MoodSummary {
  final List<({DateTime date, double value})> dayMeans;
  final List<int> tierCounts;

  const MoodSummary({required this.dayMeans, required this.tierCounts});

  int get moodCount => tierCounts.fold(0, (total, count) => total + count);

  List<double> get tierShares => [
        for (final count in tierCounts) moodCount == 0 ? 0 : count / moodCount,
      ];
}

class TagTileSummary {
  final double? value;
  final num? trend;
  final List<double?> series;

  const TagTileSummary({
    required this.value,
    required this.trend,
    required this.series,
  });
}

class WritingSummary {
  final StatsWindow window;
  final int logCount;
  final int wordCount;
  final int daysWritten;
  final double averageWordsPerLog;
  final ({int wordCount, DateTime date})? longestLog;
  final List<int> logsByWeekday;
  final List<int> busiestWeekdayIndexes;
  final List<double> wordSeries;
  final List<double> logSeries;
  final List<double?> wordsPerLogSeries;
  final Set<DateTime> writtenDays;

  const WritingSummary({
    required this.window,
    required this.logCount,
    required this.wordCount,
    required this.daysWritten,
    required this.averageWordsPerLog,
    required this.longestLog,
    required this.logsByWeekday,
    required this.busiestWeekdayIndexes,
    required this.wordSeries,
    required this.logSeries,
    required this.wordsPerLogSeries,
    required this.writtenDays,
  });
}

StatsWindow? priorStatsWindow(
  List<Entry> entries,
  StatsRange range, {
  DateTime? now,
}) {
  if (range == StatsRange.allTime) return null;
  final window = statsWindow(entries, range, now: now);
  return (
    start: DateTime(
      window.start.year,
      window.start.month,
      window.start.day - window.dayCount,
    ),
    end: DateTime(window.start.year, window.start.month, window.start.day - 1),
    dayCount: window.dayCount,
  );
}

List<int> weekdayDisplayOrder(int firstDayIndex) => [
      for (var offset = 0; offset < DateTime.daysPerWeek; offset++)
        (firstDayIndex + offset) % DateTime.daysPerWeek,
    ];

StatsWindow statsWindow(
  List<Entry> entries,
  StatsRange range, {
  DateTime? now,
}) {
  final today = _calendarDay(now ?? DateTime.now());
  final logDays = entries.map(_calendarDayOf);
  final end = logDays.fold(today, _later);
  final rangeStart = statsRangeStart(
    entries.isEmpty && range == StatsRange.allTime ? StatsRange.year : range,
    now: now,
  );
  final start = rangeStart != null
      ? _calendarDay(rangeStart)
      : logDays.fold(today, _earlier);
  return (
    start: start,
    end: end,
    dayCount: calendarDaysBetween(start, end) + 1
  );
}

List<StatsDay> statsDays(
  List<Entry> entries,
  List<EntryTag> entryTags,
  List<Tag> tags,
) {
  final tagById = {for (final tag in tags) tag.id: tag};
  final entryTagsByEntryId = <int, List<EntryTag>>{};
  for (final entryTag in entryTags) {
    (entryTagsByEntryId[entryTag.entryId] ??= []).add(entryTag);
  }
  final entriesByDay = <DateTime, List<Entry>>{};
  for (final entry in entries) {
    (entriesByDay[_calendarDayOf(entry)] ??= []).add(entry);
  }

  final days = <StatsDay>[];
  for (final MapEntry(key: date, value: dayEntries) in entriesByDay.entries) {
    var wordCount = 0;
    var longestLogWordCount = 0;
    final moods = <double>[];
    final labelTagIds = <int>{};
    final trackerValues = <int, List<double>>{};
    for (final entry in dayEntries) {
      final entryWordCount = _wordCountOf(entry);
      wordCount += entryWordCount;
      longestLogWordCount = math.max(longestLogWordCount, entryWordCount);
      if (entry.mood != null) moods.add(Mood.position(entry.mood!).toDouble());
      for (final entryTag in entryTagsByEntryId[entry.id] ?? const []) {
        final tag = tagById[entryTag.tagId];
        if (tag == null) continue;
        if (tag.tagType == TagType.label) {
          labelTagIds.add(tag.id!);
        } else if (double.tryParse(entryTag.value ?? '') case final value?) {
          (trackerValues[tag.id!] ??= []).add(value);
        }
      }
    }
    days.add(
      StatsDay(
        date: date,
        logCount: dayEntries.length,
        wordCount: wordCount,
        longestLogWordCount: longestLogWordCount,
        mood: moods.isEmpty ? null : _mean(moods),
        labelTagIds: labelTagIds,
        trackerValues: {
          for (final MapEntry(key: tagId, value: values)
              in trackerValues.entries)
            tagId: _mean(values),
        },
      ),
    );
  }
  days.sort((first, second) => first.date.compareTo(second.date));
  return days;
}

List<WeekdayMood> moodByWeekday(
  List<Entry> entries,
  StatsRange range, {
  required int firstDayIndex,
  DateTime? now,
}) {
  final days = _periodDays(entries, const [], const [], range, now).days;
  final moodsByWeekday = [
    for (var index = 0; index < DateTime.daysPerWeek; index++) <double>[],
  ];
  for (final day in days) {
    if (day.mood != null) {
      moodsByWeekday[day.date.weekday - DateTime.monday].add(day.mood!);
    }
  }
  return [
    for (final weekdayIndex in weekdayDisplayOrder(firstDayIndex))
      WeekdayMood(
        weekdayIndex: weekdayIndex,
        tierCounts: [
          for (var tier = 0; tier < Mood.count; tier++)
            moodsByWeekday[weekdayIndex]
                .where((mood) => mood.round() == tier)
                .length,
        ],
        meanMood: moodsByWeekday[weekdayIndex].isEmpty
            ? null
            : _mean(moodsByWeekday[weekdayIndex]),
      ),
  ];
}

LabelSummary labelSummary(
  List<Entry> entries,
  List<EntryTag> entryTags,
  List<Tag> tags,
  int tagId,
  StatsRange range, {
  DateTime? now,
}) =>
    _labelSummary(
      statsWindow(entries, range, now: now),
      _periodDays(entries, entryTags, tags, range, now),
      tagId,
    );

TrackerSummary trackerSummary(
  List<Entry> entries,
  List<EntryTag> entryTags,
  List<Tag> tags,
  int tagId,
  StatsRange range, {
  DateTime? now,
}) =>
    _trackerSummary(_periodDays(entries, entryTags, tags, range, now), tagId);

MoodSummary moodSummary(
  List<Entry> entries,
  StatsRange range, {
  DateTime? now,
}) {
  final rangedEntries = entriesInRange(entries, range, now: now);
  final tierCounts = List.filled(Mood.count, 0);
  for (final entry in rangedEntries) {
    if (entry.mood != null) tierCounts[Mood.position(entry.mood!)]++;
  }
  final dayMeans = [
    for (final day in statsDays(rangedEntries, const [], const []))
      if (day.mood != null) (date: day.date, value: day.mood!),
  ];
  return MoodSummary(dayMeans: dayMeans, tierCounts: tierCounts);
}

Map<int, TagTileSummary> tagTileSummaries(
  List<Entry> entries,
  List<EntryTag> entryTags,
  List<Tag> tags,
  List<int> tagIds,
  StatsRange range, {
  DateTime? now,
}) {
  final window = statsWindow(entries, range, now: now);
  final periods = _periodDays(entries, entryTags, tags, range, now);
  final tagById = {for (final tag in tags) tag.id: tag};
  return {
    for (final tagId in tagIds)
      if (tagById[tagId] case final tag?)
        tagId: tag.tagType == TagType.label
            ? _labelTileSummary(window, periods, tagId)
            : _trackerTileSummary(window, periods, tagId),
  };
}

WritingSummary writingSummary(
  List<Entry> entries,
  StatsRange range, {
  DateTime? now,
}) {
  final window = statsWindow(entries, range, now: now);
  final days = statsDays(
    entriesInRange(entries, range, now: now),
    const [],
    const [],
  );

  final logCount = days.fold(0, (total, day) => total + day.logCount);
  final wordCount = days.fold(0, (total, day) => total + day.wordCount);
  final logsByWeekday = List.filled(DateTime.daysPerWeek, 0);
  StatsDay? longestDay;
  for (final day in days) {
    logsByWeekday[day.date.weekday - DateTime.monday] += day.logCount;
    if (longestDay == null ||
        day.longestLogWordCount >= longestDay.longestLogWordCount) {
      longestDay = day;
    }
  }

  final wordSeries = _bucketSums(
    days,
    window,
    sparklineBucketCount,
    (day) => day.wordCount.toDouble(),
  );
  final sparklineLogCounts = _bucketSums(
    days,
    window,
    sparklineBucketCount,
    (day) => day.logCount.toDouble(),
  );

  return WritingSummary(
    window: window,
    logCount: logCount,
    wordCount: wordCount,
    daysWritten: days.length,
    averageWordsPerLog: logCount == 0 ? 0 : wordCount / logCount,
    longestLog: longestDay == null
        ? null
        : (wordCount: longestDay.longestLogWordCount, date: longestDay.date),
    logsByWeekday: logsByWeekday,
    busiestWeekdayIndexes: _busiestWeekdayIndexes(
      logsByWeekday,
      days.isEmpty ? null : days.first.date,
      window.end,
    ),
    wordSeries: wordSeries,
    logSeries: _bucketSums(
      days,
      window,
      frequencyBucketCount,
      (day) => day.logCount.toDouble(),
    ),
    wordsPerLogSeries: [
      for (var index = 0; index < sparklineBucketCount; index++)
        sparklineLogCounts[index] == 0
            ? null
            : wordSeries[index] / sparklineLogCounts[index],
    ],
    writtenDays: {for (final entry in entries) _calendarDayOf(entry)},
  );
}

List<bool> recentDaysWritten(
  List<Entry> entries, {
  DateTime? now,
  int dayCount = _recentDayCount,
}) {
  final today = _calendarDay(now ?? DateTime.now());
  final writtenDays = {
    for (final entry in entries) _calendarDayOf(entry),
  };
  return [
    for (var offset = dayCount - 1; offset >= 0; offset--)
      writtenDays.contains(
        DateTime(today.year, today.month, today.day - offset),
      ),
  ];
}

typedef _PeriodDays = ({
  List<StatsDay> days,
  List<StatsDay>? priorDays,
  List<StatsDay> allDays,
});

_PeriodDays _periodDays(
  List<Entry> entries,
  List<EntryTag> entryTags,
  List<Tag> tags,
  StatsRange range,
  DateTime? now,
) {
  final allDays = statsDays(entries, entryTags, tags);
  final start = statsRangeStart(range, now: now);
  final prior = priorStatsWindow(entries, range, now: now);
  return (
    days: start == null
        ? allDays
        : [
            for (final day in allDays)
              if (!day.date.isBefore(start)) day,
          ],
    allDays: allDays,
    priorDays: prior == null
        ? null
        : [
            for (final day in allDays)
              if (!day.date.isBefore(prior.start) &&
                  !day.date.isAfter(prior.end))
                day,
          ],
  );
}

LabelSummary _labelSummary(StatsWindow window, _PeriodDays periods, int tagId) {
  final presentDates = [
    for (final day in periods.days)
      if (day.labelTagIds.contains(tagId)) day.date,
  ];

  final presentFraction = _presentFraction(periods.days, tagId);
  final priorDays = periods.priorDays;
  final canTrend = periods.days.isNotEmpty &&
      priorDays != null &&
      priorDays.length >= _minimumPriorDaysForTrend;
  final trendPoints = canTrend
      ? ((presentFraction - _presentFraction(priorDays, tagId)) * 100).round()
      : 0;

  return LabelSummary(
    window: window,
    daysPresent: presentDates.length,
    daysAbsent: periods.days.length - presentDates.length,
    presentFraction: presentFraction,
    bestStreak: _longestRun(presentDates),
    trendPoints: trendPoints == 0 ? null : trendPoints,
    presentDays: {
      for (final day in periods.allDays)
        if (day.labelTagIds.contains(tagId)) day.date,
    },
  );
}

TrackerSummary _trackerSummary(_PeriodDays periods, int tagId) {
  final values = _trackerDayValues(periods.days, tagId);
  final priorDays = periods.priorDays;
  final priorValues =
      priorDays == null ? null : _trackerDayValues(priorDays, tagId);
  final canTrend = values.isNotEmpty &&
      priorValues != null &&
      priorValues.length >= _minimumPriorDaysForTrend;
  final trend =
      canTrend ? ((_mean(values) - _mean(priorValues)) * 10).round() / 10 : 0;

  return TrackerSummary(
    average: values.isEmpty ? null : _mean(values),
    highest: values.isEmpty ? null : values.reduce(math.max),
    lowest: values.isEmpty ? null : values.reduce(math.min),
    daysLogged: values.length,
    trend: trend == 0 ? null : trend.toDouble(),
  );
}

TagTileSummary _labelTileSummary(
  StatsWindow window,
  _PeriodDays periods,
  int tagId,
) {
  final summary = _labelSummary(window, periods, tagId);
  return TagTileSummary(
    value: periods.allDays.any((day) => day.labelTagIds.contains(tagId))
        ? summary.presentFraction
        : null,
    trend: summary.trendPoints,
    series: _bucketSums(
      periods.days,
      window,
      frequencyBucketCount,
      (day) => day.labelTagIds.contains(tagId) ? 1 : 0,
    ),
  );
}

TagTileSummary _trackerTileSummary(
  StatsWindow window,
  _PeriodDays periods,
  int tagId,
) {
  final summary = _trackerSummary(periods, tagId);
  return TagTileSummary(
    value: hasEnoughChartData(summary.daysLogged) ? summary.average : null,
    trend: summary.trend,
    series: _bucketMeans(
      periods.days,
      window,
      sparklineBucketCount,
      (day) => day.trackerValues[tagId],
    ),
  );
}

List<double> _trackerDayValues(List<StatsDay> days, int tagId) => [
      for (final day in days)
        if (day.trackerValues[tagId] != null) day.trackerValues[tagId]!,
    ];

double _presentFraction(List<StatsDay> days, int tagId) => days.isEmpty
    ? 0
    : days.where((day) => day.labelTagIds.contains(tagId)).length / days.length;

int _longestRun(List<DateTime> sortedDays) {
  var longest = 0;
  var run = 0;
  DateTime? previous;
  for (final day in sortedDays) {
    run = previous != null && calendarDaysBetween(previous, day) == 1
        ? run + 1
        : 1;
    longest = math.max(longest, run);
    previous = day;
  }
  return longest;
}

List<int> _busiestWeekdayIndexes(
  List<int> logsByWeekday,
  DateTime? firstLogDay,
  DateTime windowEnd,
) {
  if (firstLogDay == null) return const [];
  final dataDayCount = calendarDaysBetween(firstLogDay, windowEnd) + 1;
  if (dataDayCount < _minimumDaysForBusiestWeekday) return const [];

  final peak = logsByWeekday.reduce(math.max);
  final peakIndexes = [
    for (var index = 0; index < logsByWeekday.length; index++)
      if (logsByWeekday[index] == peak) index,
  ];
  return peakIndexes.length > 2 ? const [] : peakIndexes;
}

List<double> _bucketSums(
  List<StatsDay> days,
  StatsWindow window,
  int bucketCount,
  double Function(StatsDay day) valueOf,
) {
  final sums = List.filled(bucketCount, 0.0);
  final bucketsPerDay = bucketCount / window.dayCount;
  for (final day in days) {
    final dayStart =
        calendarDaysBetween(window.start, day.date) * bucketsPerDay;
    final dayEnd = dayStart + bucketsPerDay;
    final value = valueOf(day);
    for (var bucket = dayStart.floor();
        bucket < math.min(bucketCount, dayEnd.ceil());
        bucket++) {
      final overlap = math.min(dayEnd, bucket + 1.0) -
          math.max(dayStart, bucket.toDouble());
      if (overlap > 0) sums[bucket] += value * overlap / bucketsPerDay;
    }
  }
  return sums;
}

List<double?> _bucketMeans(
  List<StatsDay> days,
  StatsWindow window,
  int bucketCount,
  double? Function(StatsDay day) valueOf,
) {
  final sums = _bucketSums(
    days,
    window,
    bucketCount,
    (day) => valueOf(day) ?? 0,
  );
  final weights = _bucketSums(
    days,
    window,
    bucketCount,
    (day) => valueOf(day) == null ? 0 : 1,
  );
  return [
    for (var bucket = 0; bucket < bucketCount; bucket++)
      weights[bucket] < _minimumBucketWeight
          ? null
          : sums[bucket] / weights[bucket],
  ];
}

final Expando<int> _wordCounts = Expando<int>();

int _wordCountOf(Entry entry) => _wordCounts[entry] ??= countWords(entry.text);

final Expando<DateTime> _calendarDays = Expando<DateTime>();

DateTime _calendarDayOf(Entry entry) =>
    _calendarDays[entry] ??= _calendarDay(entry.timeCreate);

DateTime _calendarDay(DateTime dateTime) =>
    DateTime(dateTime.year, dateTime.month, dateTime.day);

DateTime _later(DateTime first, DateTime second) =>
    first.isAfter(second) ? first : second;

DateTime _earlier(DateTime first, DateTime second) =>
    first.isBefore(second) ? first : second;

double _mean(List<double> values) =>
    values.reduce((total, value) => total + value) / values.length;
