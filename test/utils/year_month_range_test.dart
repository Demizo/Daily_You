// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/utils/year_month_range.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shamsi_date/shamsi_date.dart';

YearMonthRange _gregorian() => YearMonthRange(
      isJalali: false,
      earliestDate: DateTime(1583, 3, 1),
      latestDate: DateTime(2026, 10, 26),
    );

YearMonthRange _jalali() => YearMonthRange(
      isJalali: true,
      earliestDate: DateTime(1583, 3, 1),
      latestDate: DateTime(2026, 10, 26),
    );

void main() {
  group('Gregorian', () {
    test('bounds are the year and month of the earliest and latest dates', () {
      final range = _gregorian();

      expect(range.earliest, (year: 1583, month: 3));
      expect(range.latest, (year: 2026, month: 10));
    });

    test('enables months only between the bounds', () {
      final range = _gregorian();

      expect(range.isMonthEnabled(1583, 2), isFalse);
      expect(range.isMonthEnabled(1583, 3), isTrue);
      expect(range.isMonthEnabled(1800, 1), isTrue);
      expect(range.isMonthEnabled(2026, 10), isTrue);
      expect(range.isMonthEnabled(2026, 11), isFalse);
      expect(range.isMonthEnabled(2027, 1), isFalse);
    });

    test('clamps the month to what the year allows', () {
      final range = _gregorian();

      expect(range.clampMonth(1583, 1), 3);
      expect(range.clampMonth(2026, 12), 10);
      expect(range.clampMonth(1999, 12), 12);
      expect(range.clampMonth(1999, 1), 1);
    });

    test('clamps a date into the range', () {
      final range = _gregorian();

      expect(range.clamp(DateTime(1400, 1, 1)), (year: 1583, month: 3));
      expect(range.clamp(DateTime(2030, 12, 5)), (year: 2026, month: 10));
      expect(range.clamp(DateTime(1990, 7, 20)), (year: 1990, month: 7));
    });

    test('resolves to the first day of the month', () {
      expect(_gregorian().toDate(1990, 5), DateTime(1990, 5, 1));
    });
  });

  group('Jalali', () {
    test('bounds are in Jalali years and months', () {
      final range = _jalali();
      final earliest = Jalali.fromDateTime(DateTime(1583, 3, 1));
      final latest = Jalali.fromDateTime(DateTime(2026, 10, 26));

      expect(range.earliest, (year: earliest.year, month: earliest.month));
      expect(range.latest, (year: latest.year, month: latest.month));
    });

    test('resolves to the Gregorian date of the first day of the month', () {
      expect(_jalali().toDate(1403, 1), Jalali(1403, 1, 1).toDateTime());
    });

    test('clamps a Gregorian date using its Jalali year and month', () {
      final range = _jalali();
      final date = DateTime(2024, 3, 25);
      final jalali = Jalali.fromDateTime(date);

      expect(range.clamp(date), (year: jalali.year, month: jalali.month));
    });

    test('disables months after the latest', () {
      final range = _jalali();

      expect(
          range.isMonthEnabled(range.latest.year, range.latest.month), isTrue);
      expect(range.isMonthEnabled(range.latest.year + 1, 1), isFalse);
    });
  });
}
