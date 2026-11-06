// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math' as math;

import 'package:daily_you/time_manager.dart';

class DayGridLayout {
  DayGridLayout({
    required this.start,
    required this.dayCount,
    required this.firstWeekday,
    this.minimumWeekCount = 0,
  });

  static const List<int> labeledWeekdays = [
    DateTime.monday,
    DateTime.wednesday,
    DateTime.friday,
  ];

  static const double cellSize = 24;

  static int weekCountFor(double availableWidth) =>
      (availableWidth / cellSize).floor();

  final DateTime start;
  final int dayCount;
  final int firstWeekday;
  final int minimumWeekCount;

  late final List<DateTime> dates = [
    for (var dayIndex = 0; dayIndex < dayCount; dayIndex++) dateOf(dayIndex),
  ];

  late final int _startWeekdayOffset = (start.weekday - firstWeekday + 7) % 7;

  late final int _rangeWeekCount = (_startWeekdayOffset + dayCount + 6) ~/ 7;

  late final int weekCount = math.max(minimumWeekCount, _rangeWeekCount);

  late final int leadingDayCount = _startWeekdayOffset +
      (weekCount - _rangeWeekCount) * DateTime.daysPerWeek;

  int dayIndexOf(int column, int row) =>
      column * DateTime.daysPerWeek + row - leadingDayCount;

  bool isInRange(int dayIndex) => dayIndex >= 0 && dayIndex < dayCount;

  int columnOf(int dayIndex) =>
      (leadingDayCount + dayIndex) ~/ DateTime.daysPerWeek;

  int rowOf(int dayIndex) =>
      (leadingDayCount + dayIndex) % DateTime.daysPerWeek;

  DateTime dateOf(int dayIndex) =>
      DateTime(start.year, start.month, start.day + dayIndex);

  int weekdayOfRow(int row) => (firstWeekday - 1 + row) % 7 + 1;

  List<int> get labeledRows => [
        for (var row = 0; row < 7; row++)
          if (labeledWeekdays.contains(weekdayOfRow(row))) row,
      ];

  List<({int column, DateTime date})> monthLabels({required bool isJalali}) {
    final labels = <({int column, DateTime date})>[];
    var previousLabeledColumn = -1;
    for (var dayIndex = 0; dayIndex < dayCount; dayIndex++) {
      final date = dates[dayIndex];
      final column = columnOf(dayIndex);
      final startsMonth = TimeManager.isFirstDayOfCalendarMonth(date, isJalali);
      if (column != previousLabeledColumn && (startsMonth || dayIndex == 0)) {
        labels.add((column: column, date: date));
        previousLabeledColumn = column;
      }
    }
    return labels;
  }
}
