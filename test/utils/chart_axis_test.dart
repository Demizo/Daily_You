// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/utils/chart_axis.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('axisUnitInDays', () {
    test('keeps one day per step until the range exceeds the step cap', () {
      expect(axisUnitInDays(0), 1);
      expect(axisUnitInDays(365), 1);
      expect(axisUnitInDays(1000), 1);
    });

    test('widens the step so the axis never exceeds the step cap', () {
      expect(axisUnitInDays(1001), 2);
      for (final totalDays in [2500.0, 9500.0, 36500.0, 146000.0]) {
        expect(totalDays / axisUnitInDays(totalDays), lessThanOrEqualTo(1000));
      }
    });
  });

  group('axisYearStep', () {
    test('labels every year while they fit', () {
      expect(axisYearStep(1), 1);
      expect(axisYearStep(6), 1);
    });

    test('picks the smallest round step that keeps six labels or fewer', () {
      expect(axisYearStep(7), 2);
      expect(axisYearStep(12), 2);
      expect(axisYearStep(13), 5);
      expect(axisYearStep(30), 5);
      expect(axisYearStep(31), 10);
      expect(axisYearStep(127), 25);
      expect(axisYearStep(440), 100);
    });

    test('never exceeds six labels across realistic ranges', () {
      for (int yearCount = 1; yearCount <= 1500; yearCount++) {
        final step = axisYearStep(yearCount);
        expect((yearCount / step).ceil(), lessThanOrEqualTo(6),
            reason: '$yearCount years with step $step');
      }
    });
  });

  group('markers', () {
    test('draw quarterly lines for a few years', () {
      expect(markerMonths(8), [1, 4, 7, 10]);
      expect(markerYearStep(8), 1);
    });

    test('draw one line per year for longer ranges', () {
      expect(markerMonths(9), [1]);
      expect(markerYearStep(9), 1);
      expect(markerYearStep(40), 1);
    });

    test('follow the label step for very long ranges', () {
      expect(markerYearStep(41), axisYearStep(41));
      expect(markerYearStep(127), 25);
    });
  });

  group('bucketIndexAtOrBefore', () {
    final buckets = [
      DateTime(2020, 1, 1),
      DateTime(2020, 2, 1),
      DateTime(2020, 3, 1),
    ];

    test('returns -1 before the first bucket', () {
      expect(bucketIndexAtOrBefore(buckets, DateTime(2019, 12, 31)), -1);
      expect(bucketIndexAtOrBefore(const [], DateTime(2020, 1, 1)), -1);
    });

    test('returns the bucket a date falls in', () {
      expect(bucketIndexAtOrBefore(buckets, DateTime(2020, 1, 1)), 0);
      expect(bucketIndexAtOrBefore(buckets, DateTime(2020, 1, 31)), 0);
      expect(bucketIndexAtOrBefore(buckets, DateTime(2020, 2, 1)), 1);
      expect(bucketIndexAtOrBefore(buckets, DateTime(2020, 2, 29)), 1);
    });

    test('returns the last bucket for later dates', () {
      expect(bucketIndexAtOrBefore(buckets, DateTime(2030, 1, 1)), 2);
    });
  });
}
