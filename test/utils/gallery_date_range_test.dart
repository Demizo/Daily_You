// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/gallery_filter.dart';
import 'package:daily_you/utils/gallery_date_range.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calendarYearsOf', () {
    final dates = [
      DateTime(2024, 5, 1),
      DateTime(2026, 1, 3),
      DateTime(2024, 12, 31),
      DateTime(2026, 3, 20),
      DateTime(2026, 3, 21),
    ];

    test('lists each Gregorian year once, newest first', () {
      expect(calendarYearsOf(dates, isJalali: false), [2026, 2024]);
    });

    test('lists each Jalali year once, newest first', () {
      expect(calendarYearsOf(dates, isJalali: true), [1405, 1404, 1403]);
    });
  });

  group('dayRangeOf', () {
    test('has no range without a date selection', () {
      expect(
        dayRangeOf(
          const NoDateSelection(),
          DateTime(2026, 11, 8),
        ),
        isNull,
      );
    });

    test('last months count back from today with inclusive boundaries', () {
      final today = DateTime(2026, 11, 8, 15, 30);
      DayRange last(int months) => dayRangeOf(
            LastMonthsSelection(months, isJalali: false),
            today,
          )!;

      expect(last(1).start, DateTime(2026, 10, 8));
      expect(last(3).start, DateTime(2026, 8, 8));
      expect(last(6).start, DateTime(2026, 5, 8));
      expect(last(1).endExclusive, DateTime(2026, 11, 9));
    });

    test('last months clamp to the end of a shorter month', () {
      final range = dayRangeOf(
        const LastMonthsSelection(1, isJalali: false),
        DateTime(2026, 3, 31),
      )!;
      expect(range.start, DateTime(2026, 2, 28));
    });

    test('last months count Jalali months in the Jalali calendar', () {
      final range = dayRangeOf(
        const LastMonthsSelection(1, isJalali: true),
        DateTime(2026, 11, 22),
      )!;
      expect(range.start, DateTime(2026, 10, 23));
    });

    test('a Gregorian year covers January first to December last', () {
      final range = dayRangeOf(
        const CalendarYearSelection(2026, isJalali: false),
        DateTime(2026, 11, 8),
      )!;
      expect(range.start, DateTime(2026, 1, 1));
      expect(range.endExclusive, DateTime(2027, 1, 1));
    });

    test('a Jalali year covers Farvardin first to Esfand last', () {
      final range = dayRangeOf(
        const CalendarYearSelection(1404, isJalali: true),
        DateTime(2026, 11, 8),
      )!;
      expect(range.start, DateTime(2025, 3, 21));
      expect(range.endExclusive, DateTime(2026, 3, 21));
    });

    test('a custom range includes both end days whatever the time', () {
      final range = dayRangeOf(
        CustomRangeSelection(
          DateTime(2026, 11, 5, 18),
          DateTime(2026, 11, 6, 6),
        ),
        DateTime(2026, 11, 8),
      )!;
      expect(range.start, DateTime(2026, 11, 5));
      expect(range.endExclusive, DateTime(2026, 11, 7));
    });

    test('ends the day after the last selected day', () {
      final range = dayRangeOf(
        CustomRangeSelection(DateTime(2026, 12, 30), DateTime(2026, 12, 31)),
        DateTime(2026, 11, 8),
      )!;
      expect(range.start, DateTime(2026, 12, 30));
      expect(range.endExclusive, DateTime(2027, 1, 1));
    });
  });
}
