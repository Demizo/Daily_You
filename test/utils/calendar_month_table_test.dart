// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/utils/calendar_month_table.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shamsi_date/shamsi_date.dart';

final _today = DateTime(2026, 10, 26);
final _floor = DateTime(1583, 1, 1);

CalendarMonthTable _table({
  bool isJalali = false,
  int firstWeekday = DateTime.monday,
  DateTime? floorDate,
}) {
  return CalendarMonthTable(
    today: _today,
    isJalali: isJalali,
    firstWeekday: firstWeekday,
  )..extend(floorDate ?? _floor, 100000);
}

List<DateTime> _daysOfWeeks(CalendarMonthTable table, MonthLayout layout) {
  return [
    for (int week = layout.weekCount - 1; week >= 0; week--)
      ...table
          .weekDays(layout, week, isHidden: (_) => false)
          .whereType<DateTime>(),
  ];
}

void main() {
  for (final isJalali in [false, true]) {
    group(isJalali ? 'Jalali' : 'Gregorian', () {
      test('starts with the current month at the bottom row', () {
        final table = _table(isJalali: isJalali);

        final first = table.months.first;
        expect(first.firstRow, 0);
        expect(first.firstDate.isAfter(_today), isFalse);
        expect(first.lastDate.isBefore(_today), isFalse);
      });

      test('stacks months with one header row each and no gaps', () {
        final table = _table(isJalali: isJalali);

        var expectedRow = 0;
        for (final layout in table.months) {
          expect(layout.firstRow, expectedRow);
          expectedRow += layout.weekCount + 1;
        }
        expect(table.rowCount, expectedRow);
      });

      test('lists every day of a month exactly once across its weeks', () {
        for (final firstWeekday in [
          DateTime.monday,
          DateTime.saturday,
          DateTime.sunday
        ]) {
          final table = _table(
              isJalali: isJalali,
              firstWeekday: firstWeekday,
              floorDate: DateTime(2020, 1, 1));

          for (final layout in table.months) {
            final days = _daysOfWeeks(table, layout);
            final dayCount =
                (layout.lastDate.difference(layout.firstDate).inHours / 24)
                        .round() +
                    1;
            expect(days.length, dayCount,
                reason: '${layout.firstDate} with week starting $firstWeekday');
            expect(days.first, layout.firstDate);
            expect(days.last, layout.lastDate);
          }
        }
      });

      test('keeps each week row starting on the first weekday', () {
        final table = _table(
            isJalali: isJalali,
            firstWeekday: DateTime.saturday,
            floorDate: DateTime(2020, 1, 1));

        for (final layout in table.months) {
          final firstWeek = table.weekDays(layout, layout.weekCount - 1,
              isHidden: (_) => false);
          final firstDay = firstWeek.firstWhere((day) => day != null)!;
          expect(firstDay, layout.firstDate);
          final lastWeek = table.weekDays(layout, 0, isHidden: (_) => false);
          expect(lastWeek.lastWhere((day) => day != null), layout.lastDate);
        }
      });

      test('finds the month for every row, header included', () {
        final table = _table(isJalali: isJalali);

        for (int row = 0; row < table.rowCount; row += 7) {
          final layout = table.months[table.monthIndexForRow(row)];
          expect(row, greaterThanOrEqualTo(layout.firstRow));
          expect(row, lessThanOrEqualTo(layout.firstRow + layout.weekCount));
        }
        final lastRow = table.rowCount - 1;
        expect(table.monthIndexForRow(lastRow), table.months.length - 1);
      });

      test('finds the month containing a date', () {
        final table = _table(isJalali: isJalali);
        final date = DateTime(1900, 3, 15);

        final layout = table.months[table.indexOfMonthContaining(date)];

        expect(layout.firstDate.isAfter(date), isFalse);
        expect(layout.lastDate.isBefore(DateTime(1900, 3, 15)), isFalse);
        expect(table.indexOfMonthContaining(DateTime(1500, 1, 1)), -1);
      });

      test('places today in the week row it reports', () {
        final table =
            _table(isJalali: isJalali, floorDate: DateTime(2026, 1, 1));

        final week = table.weekDays(table.months.first, table.todayRow,
            isHidden: (_) => false);

        expect(week, contains(_today));
      });

      test('stops at the month holding the floor and then does nothing', () {
        final table = _table(isJalali: isJalali);
        final last = table.months.last;

        expect(table.reachedFloor(_floor), isTrue);
        expect(last.firstDate.isAfter(_floor), isFalse);
        expect(last.lastDate.isBefore(_floor), isFalse);

        final rows = table.rowCount;
        table.extend(_floor, 120);
        expect(table.rowCount, rows);
      });

      test('keeps extending when the floor moves earlier', () {
        final table = _table(isJalali: isJalali);
        final rows = table.rowCount;
        final olderFloor = DateTime(1500, 6, 15);

        expect(table.reachedFloor(olderFloor), isFalse);
        table.extend(olderFloor, 100000);

        expect(table.rowCount, greaterThan(rows));
        expect(table.reachedFloor(olderFloor), isTrue);
        expect(table.indexOfMonthContaining(olderFloor), isNonNegative);
      });

      test('extends in batches without reaching a far floor early', () {
        final table = CalendarMonthTable(
          today: _today,
          isJalali: isJalali,
          firstWeekday: DateTime.monday,
        )..extend(_floor, 240);

        expect(table.months.length, 240);
        expect(table.reachedFloor(_floor), isFalse);
      });

      test('hides the days the caller marks hidden', () {
        final table =
            _table(isJalali: isJalali, floorDate: DateTime(2026, 1, 1));
        final layout = table.months.first;

        final days = table
            .weekDays(layout, 0, isHidden: (day) => day == layout.lastDate)
            .whereType<DateTime>();

        expect(days, isNot(contains(layout.lastDate)));
      });
    });
  }

  test('Jalali months follow Jalali boundaries', () {
    final table = _table(isJalali: true, floorDate: DateTime(2026, 1, 1));
    final jalali = Jalali.fromDateTime(table.months.first.firstDate);

    expect(jalali.day, 1);
    expect(table.months.first.calendarYear, jalali.year);
    expect(table.months.first.calendarMonth, jalali.month);
    expect(table.months[1].lastDate.add(const Duration(days: 1)).day,
        table.months.first.firstDate.day);
  });
}
