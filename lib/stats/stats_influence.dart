// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math' as math;

import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/mood.dart';
import 'package:daily_you/models/tag.dart';

const int maximumInfluences = 10;
const int minimumSamplesPerInfluenceSide = 8;
const List<({double swing, double correlation})> influenceThresholds = [
  (swing: 0.3, correlation: 0),
  (swing: 0.2, correlation: 0.5),
  (swing: 0.1, correlation: 0.7),
];
const double minimumInfluenceTStatistic = 2;

class InfluenceSample {
  final double? mood;
  final Set<int> labelTagIds;
  final Map<int, double> trackerValues;

  const InfluenceSample({
    required this.mood,
    required this.labelTagIds,
    required this.trackerValues,
  });

  bool get hasTags => labelTagIds.isNotEmpty || trackerValues.isNotEmpty;
}

typedef SampleMeasure = double? Function(InfluenceSample sample);

List<InfluenceSample> influenceSamples(
  List<Entry> entries,
  List<EntryTag> entryTags,
  List<Tag> tags,
) {
  final tagById = {for (final tag in tags) tag.id: tag};
  final entryTagsByEntryId = <int, List<EntryTag>>{};
  for (final entryTag in entryTags) {
    (entryTagsByEntryId[entryTag.entryId] ??= []).add(entryTag);
  }
  return [
    for (final entry in entries)
      _sampleOf(entry, entryTagsByEntryId[entry.id] ?? const [], tagById),
  ];
}

InfluenceSample _sampleOf(
  Entry entry,
  List<EntryTag> entryTags,
  Map<int?, Tag> tagById,
) {
  final labelTagIds = <int>{};
  final trackerValues = <int, double>{};
  for (final entryTag in entryTags) {
    final tag = tagById[entryTag.tagId];
    if (tag == null) continue;
    if (tag.tagType == TagType.label) {
      labelTagIds.add(tag.id!);
    } else if (double.tryParse(entryTag.value ?? '') case final value?) {
      trackerValues[tag.id!] = value;
    }
  }
  return InfluenceSample(
    mood: entry.mood == null ? null : Mood.position(entry.mood!).toDouble(),
    labelTagIds: labelTagIds,
    trackerValues: trackerValues,
  );
}

class TagInfluence {
  final Tag tag;
  final double presentMean;
  final double absentMean;

  const TagInfluence({
    required this.tag,
    required this.presentMean,
    required this.absentMean,
  });

  double get difference => presentMean - absentMean;
}

List<TagInfluence> tagInfluences(
  List<InfluenceSample> samples,
  List<Tag> tags,
  SampleMeasure measureOf, {
  int? excludedTagId,
  double? scaleRange,
  bool requireDistinctLevels = false,
}) {
  final taggedSamples = [
    for (final sample in samples)
      if (sample.hasTags) sample,
  ];
  final measuredValues = _measured(taggedSamples, measureOf);
  if (measuredValues.isEmpty) return const [];
  final range = scaleRange ??
      measuredValues.reduce(math.max) - measuredValues.reduce(math.min);
  if (range <= 0) return const [];
  final influences = <TagInfluence>[];
  for (final tag in tags) {
    if (tag.tagType != TagType.label ||
        tag.id == null ||
        tag.id == excludedTagId) {
      continue;
    }
    final (presentSamples, absentSamples) =
        _splitByPresence(taggedSamples, tag.id!);
    final presentValues = _measured(presentSamples, measureOf);
    final absentValues = _measured(absentSamples, measureOf);
    if (_isStrongInfluence(
      presentValues,
      absentValues,
      range: range,
      requireDistinctLevels: requireDistinctLevels,
    )) {
      influences.add(TagInfluence(
        tag: tag,
        presentMean: _mean(presentValues),
        absentMean: _mean(absentValues),
      ));
    }
  }
  influences.sort((first, second) =>
      second.difference.abs().compareTo(first.difference.abs()));
  return influences.take(maximumInfluences).toList();
}

(List<InfluenceSample>, List<InfluenceSample>) _splitByPresence(
  List<InfluenceSample> samples,
  int tagId,
) =>
    (
      [
        for (final sample in samples)
          if (sample.labelTagIds.contains(tagId)) sample,
      ],
      [
        for (final sample in samples)
          if (!sample.labelTagIds.contains(tagId)) sample,
      ],
    );

List<double> _measured(
        List<InfluenceSample> samples, SampleMeasure measureOf) =>
    [for (final sample in samples) measureOf(sample)].nonNulls.toList();

bool _isStrongInfluence(
  List<double> present,
  List<double> absent, {
  required double range,
  required bool requireDistinctLevels,
}) {
  if (present.length < minimumSamplesPerInfluenceSide ||
      absent.length < minimumSamplesPerInfluenceSide) {
    return false;
  }
  final presentMean = _mean(present);
  final absentMean = _mean(absent);
  final swing = (presentMean - absentMean).abs() / range;
  if (swing < influenceThresholds.last.swing) return false;
  if (requireDistinctLevels && presentMean.round() == absentMean.round()) {
    return false;
  }
  if (_tStatistic(present, absent) < minimumInfluenceTStatistic) return false;
  final correlation = _correlation(present, absent);
  return influenceThresholds.any((threshold) =>
      swing >= threshold.swing && correlation >= threshold.correlation);
}

double _tStatistic(List<double> first, List<double> second) {
  final standardError = math.sqrt(_sampleVariance(first) / first.length +
      _sampleVariance(second) / second.length);
  final difference = (_mean(first) - _mean(second)).abs();
  return standardError == 0 ? double.infinity : difference / standardError;
}

double _correlation(List<double> first, List<double> second) {
  final all = [...first, ...second];
  final mean = _mean(all);
  final spread = math.sqrt(
      all.fold(0.0, (total, value) => total + (value - mean) * (value - mean)) /
          all.length);
  if (spread == 0) return 0;
  return (_mean(first) - _mean(second)).abs() *
      math.sqrt(first.length * second.length) /
      (all.length * spread);
}

double _mean(List<double> values) =>
    values.reduce((total, value) => total + value) / values.length;

double _sampleVariance(List<double> values) {
  final mean = _mean(values);
  return values.fold(
          0.0, (total, value) => total + (value - mean) * (value - mean)) /
      (values.length - 1);
}
