// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/tag.dart';
import 'package:daily_you/stats/stats_influence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 1, 1);
  Tag tag(int id, String name, TagType tagType) => Tag(
        id: id,
        name: name,
        tagType: tagType,
        timeCreate: now,
        timeModified: now,
      );
  final exercise = tag(1, 'exercise', TagType.label);
  final reading = tag(2, 'reading', TagType.label);
  final sleep = tag(3, 'sleep', TagType.tracker);
  final tags = [exercise, reading, sleep];

  InfluenceSample sample(int index,
          {double? mood, Set<int> labels = const {99}, double? slept}) =>
      InfluenceSample(
        mood: mood,
        labelTagIds: labels,
        trackerValues: slept == null ? {} : {3: slept},
      );

  List<InfluenceSample> splitSamples(int perSide) => [
        for (var index = 0; index < perSide; index++)
          sample(index,
              mood: 3 + (index.isEven ? 0.2 : -0.2), labels: {1, 2}, slept: 8),
        for (var index = 0; index < perSide; index++)
          sample(perSide + index,
              mood: 1 + (index.isEven ? 0.2 : -0.2), slept: 5),
      ];

  test('lists tags whose days differ in the measure', () {
    final influences =
        tagInfluences(splitSamples(12), tags, (sample) => sample.mood);
    expect(influences.map((influence) => influence.tag.id).toSet(), {1, 2});
    final exerciseInfluence =
        influences.firstWhere((influence) => influence.tag.id == 1);
    expect(exerciseInfluence.presentMean, closeTo(3, 0.01));
    expect(exerciseInfluence.absentMean, closeTo(1, 0.01));
  });

  test('caps the list at the maximum', () {
    final manyTags = [
      for (var id = 10; id < 25; id++) tag(id, 'label $id', TagType.label),
    ];
    final samples = [
      for (var index = 0; index < 24; index++)
        sample(index,
            mood: index.isEven ? 3 : 1,
            labels:
                index.isEven ? {for (final item in manyTags) item.id!} : {99}),
    ];
    expect(tagInfluences(samples, manyTags, (sample) => sample.mood).length,
        maximumInfluences);
  });

  test('ignores trackers', () {
    final influences =
        tagInfluences(splitSamples(12), tags, (sample) => sample.mood);
    expect(influences.map((influence) => influence.tag.id), isNot(contains(3)));
  });

  test('skips tags with too few days on a side', () {
    expect(
        tagInfluences(splitSamples(3), tags, (sample) => sample.mood), isEmpty);
  });

  test('skips tags that do not change the measure', () {
    final samples = [
      for (var index = 0; index < 30; index++)
        sample(index,
            mood: index.isEven ? 3 : 1, labels: index % 4 < 2 ? {1} : {99}),
    ];
    expect(
        tagInfluences(samples, [exercise], (sample) => sample.mood), isEmpty);
  });

  List<InfluenceSample> moodSamples(
    double presentMood,
    double absentMood, {
    double spread = 0.2,
  }) =>
      [
        for (var index = 0; index < 12; index++)
          sample(index,
              mood: presentMood + (index.isEven ? spread : -spread),
              labels: {1}),
        for (var index = 0; index < 12; index++)
          sample(12 + index,
              mood: absentMood + (index.isEven ? spread : -spread)),
      ];

  List<int> influencedIds(
    List<InfluenceSample> samples, {
    bool requireDistinctLevels = false,
  }) =>
      tagInfluences(
        samples,
        [exercise],
        (sample) => sample.mood,
        scaleRange: 4,
        requireDistinctLevels: requireDistinctLevels,
      ).map((influence) => influence.tag.id!).toList();

  test('skips a swing under 10 percent of the scale', () {
    expect(influencedIds(moodSamples(2.3, 2.0, spread: 0.01)), isEmpty);
  });

  test('keeps a swing of 30 percent of the scale', () {
    expect(influencedIds(moodSamples(3.4, 2.0, spread: 1)), [1]);
  });

  test('keeps a swing from 20 to 30 percent only when it tracks closely', () {
    expect(influencedIds(moodSamples(3.4, 2.4, spread: 0.2)), [1]);
    expect(influencedIds(moodSamples(3.4, 2.4, spread: 1.5)), isEmpty);
  });

  test('keeps a swing from 10 to 20 percent only when it tracks very closely',
      () {
    expect(influencedIds(moodSamples(2.9, 2.4, spread: 0.05)), [1]);
    expect(influencedIds(moodSamples(2.9, 2.4, spread: 0.3)), isEmpty);
  });

  test('can require the averages to land in different levels', () {
    final samples = moodSamples(3.45, 2.6, spread: 0.1);
    expect(influencedIds(samples), [1]);
    expect(influencedIds(samples, requireDistinctLevels: true), isEmpty);
    expect(
        influencedIds(moodSamples(3.45, 2.4, spread: 0.1),
            requireDistinctLevels: true),
        [1]);
  });

  test('measures the swing against a given scale instead of the data', () {
    final samples = [
      for (var index = 0; index < 12; index++)
        sample(index, labels: {1}, slept: 6.5 + (index.isEven ? 0.1 : -0.1)),
      for (var index = 0; index < 12; index++)
        sample(12 + index, slept: 5.0 + (index.isEven ? 0.1 : -0.1)),
    ];
    double? slept(InfluenceSample sample) => sample.trackerValues[3];
    expect(tagInfluences(samples, [exercise], slept).length, 1);
    expect(tagInfluences(samples, [exercise], slept, scaleRange: 20), isEmpty);
  });

  test('leaves out the excluded tag', () {
    final influences = tagInfluences(
      splitSamples(12),
      tags,
      (sample) => sample.mood,
      excludedTagId: 1,
    );
    expect(influences.map((influence) => influence.tag.id), [2]);
  });

  test('uses a tag as the measure', () {
    final influences = tagInfluences(
      splitSamples(12),
      tags,
      (sample) => sample.labelTagIds.contains(1) ? 1.0 : 0.0,
      excludedTagId: 1,
    );
    expect(influences.single.tag.id, 2);
    expect(influences.single.presentMean, 1);
    expect(influences.single.absentMean, 0);
  });

  test('ignores entries without any tags', () {
    final samples = [
      ...moodSamples(3.4, 2.4, spread: 0.2),
      for (var index = 0; index < 40; index++)
        sample(100 + index, mood: 0.5, labels: const {}),
    ];
    final influences =
        tagInfluences(samples, [exercise], (sample) => sample.mood);
    expect(influences.single.absentMean, closeTo(2.4, 0.01));
  });
}
