// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/utils/day_grid_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DayGridLayout layoutFrom(DateTime start,
          {int dayCount = 60, int firstWeekday = DateTime.monday}) =>
      DayGridLayout(
          start: start, dayCount: dayCount, firstWeekday: firstWeekday);

  test('places the first day in the row of its weekday', () {
    final wednesday = DateTime(2026, 10, 28);

    expect(layoutFrom(wednesday).rowOf(0), 2);
    expect(layoutFrom(wednesday, firstWeekday: DateTime.sunday).rowOf(0), 3);
    expect(layoutFrom(wednesday, firstWeekday: DateTime.wednesday).rowOf(0), 0);
  });

  test('fills a column per week', () {
    final layout = layoutFrom(DateTime(2026, 10, 26), dayCount: 15);

    expect(layout.leadingDayCount, 0);
    expect(layout.columnOf(6), 0);
    expect(layout.columnOf(7), 1);
    expect(layout.columnOf(14), 2);
    expect(layout.weekCount, 3);
  });

  test('adds a partial first week as one more column', () {
    final layout = layoutFrom(DateTime(2026, 10, 28), dayCount: 6);

    expect(layout.leadingDayCount, 2);
    expect(layout.weekCount, 2);
    expect(layout.columnOf(4), 0);
    expect(layout.rowOf(4), 6);
    expect(layout.columnOf(5), 1);
    expect(layout.rowOf(5), 0);
  });

  test('computes dates across a month end', () {
    final layout = layoutFrom(DateTime(2026, 10, 30), dayCount: 5);

    expect(layout.dateOf(2), DateTime(2026, 11, 1));
  });

  test('labels Monday, Wednesday and Friday rows for any first weekday', () {
    final mondayStart = layoutFrom(DateTime(2026, 10, 26));
    final saturdayStart =
        layoutFrom(DateTime(2026, 10, 26), firstWeekday: DateTime.saturday);

    expect(mondayStart.labeledRows, [0, 2, 4]);
    expect(saturdayStart.labeledRows, [2, 4, 6]);
    expect([
      for (final row in saturdayStart.labeledRows)
        saturdayStart.weekdayOfRow(row)
    ], [
      DateTime.monday,
      DateTime.wednesday,
      DateTime.friday
    ]);
  });

  group('month labels', () {
    test('label the column holding the first of each Gregorian month', () {
      final layout = layoutFrom(DateTime(2026, 10, 14), dayCount: 60);

      final labels = layout.monthLabels(isJalali: false);

      expect(labels.map((label) => label.date), [
        DateTime(2026, 10, 14),
        DateTime(2026, 11, 1),
        DateTime(2026, 12, 1)
      ]);
      expect(labels.map((label) => label.column), [0, 2, 7]);
    });

    test('follow the Jalali months', () {
      final layout = layoutFrom(DateTime(2026, 3, 1), dayCount: 90);

      final labels = layout.monthLabels(isJalali: true);

      expect(labels.map((label) => label.date), [
        DateTime(2026, 3, 1),
        DateTime(2026, 3, 21),
        DateTime(2026, 4, 21),
        DateTime(2026, 5, 22),
      ]);
    });

    test('label a column once when two months start in it', () {
      final layout = layoutFrom(DateTime(2026, 2, 1),
          dayCount: 40, firstWeekday: DateTime.sunday);

      expect(layout.monthLabels(isJalali: false).map((label) => label.column),
          [0, 4]);
    });
  });

  group('padding to a minimum week count', () {
    test('adds leading weeks before the range', () {
      final layout = DayGridLayout(
        start: DateTime(2026, 10, 28),
        dayCount: 6,
        firstWeekday: DateTime.monday,
        minimumWeekCount: 5,
      );

      expect(layout.weekCount, 5);
      expect(layout.leadingDayCount, 2 + 3 * 7);
      expect(layout.columnOf(0), 3);
      expect(layout.rowOf(0), 2);
      expect(layout.dayIndexOf(3, 2), 0);
      expect(layout.dayIndexOf(0, 0), -23);
    });

    test('keeps the range week count when it is larger', () {
      final layout = layoutFrom(DateTime(2026, 10, 28), dayCount: 60);
      final padded = DayGridLayout(
        start: DateTime(2026, 10, 28),
        dayCount: 60,
        firstWeekday: DateTime.monday,
        minimumWeekCount: 3,
      );

      expect(padded.weekCount, layout.weekCount);
      expect(padded.leadingDayCount, layout.leadingDayCount);
    });

    test('marks cells outside the range', () {
      final layout = DayGridLayout(
        start: DateTime(2026, 10, 28),
        dayCount: 6,
        firstWeekday: DateTime.monday,
      );

      expect(layout.isInRange(layout.dayIndexOf(0, 1)), isFalse);
      expect(layout.isInRange(layout.dayIndexOf(0, 2)), isTrue);
      expect(layout.isInRange(layout.dayIndexOf(1, 0)), isTrue);
      expect(layout.isInRange(layout.dayIndexOf(1, 1)), isFalse);
    });
  });

  test('fits as many whole weeks as the width allows', () {
    expect(DayGridLayout.weekCountFor(DayGridLayout.cellSize * 10 + 5), 10);
    expect(DayGridLayout.weekCountFor(DayGridLayout.cellSize - 1), 0);
  });
}
