// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math' as math;

const int _maxAxisSteps = 1000;
const int _maxYearLabels = 6;
const int _quarterlyMarkerMaxYears = 8;
const int _everyYearMarkerMaxYears = 40;
const List<int> _yearSteps = [1, 2, 5, 10, 20, 25, 50, 100, 250];

// The axis asks for a title at every whole x, so long ranges are measured in
// coarser steps to keep the number of title widgets bounded
double axisUnitInDays(double totalDays) =>
    math.max(1, (totalDays / _maxAxisSteps).ceil()).toDouble();

int axisYearStep(int yearCount) {
  final wanted = (yearCount / _maxYearLabels).ceil();
  return _yearSteps.firstWhere((step) => step >= wanted,
      orElse: () => _yearSteps.last);
}

List<int> markerMonths(int yearCount) =>
    yearCount <= _quarterlyMarkerMaxYears ? const [1, 4, 7, 10] : const [1];

int markerYearStep(int yearCount) =>
    yearCount <= _everyYearMarkerMaxYears ? 1 : axisYearStep(yearCount);

// Index of the last bucket starting at or before the date, or -1
int bucketIndexAtOrBefore(List<DateTime> buckets, DateTime date) {
  int lowIndex = 0, highIndex = buckets.length - 1, foundIndex = -1;
  while (lowIndex <= highIndex) {
    final middleIndex = (lowIndex + highIndex) >> 1;
    if (buckets[middleIndex].isAfter(date)) {
      highIndex = middleIndex - 1;
    } else {
      foundIndex = middleIndex;
      lowIndex = middleIndex + 1;
    }
  }
  return foundIndex;
}
