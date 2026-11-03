// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:shamsi_date/shamsi_date.dart';

// Rows count up from the bottom of the reversed list: last week first, header last
class MonthLayout {
  final int calendarYear;
  final int calendarMonth;
  final DateTime firstDate;
  final DateTime lastDate;
  final int firstRow;
  final int weekCount;

  const MonthLayout({
    required this.calendarYear,
    required this.calendarMonth,
    required this.firstDate,
    required this.lastDate,
    required this.firstRow,
    required this.weekCount,
  });
}

class CalendarMonthTable {
  CalendarMonthTable({
    required this.today,
    required this.isJalali,
    required this.firstWeekday,
  });

  final DateTime today;
  final bool isJalali;
  final int firstWeekday;

  final List<MonthLayout> months = [];
  int rowCount = 0;

  late final int todayRow = _weekIndexOfToday();

  bool reachedFloor(DateTime floorDate) =>
      months.isNotEmpty && !months.last.firstDate.isAfter(floorDate);

  void extend(DateTime floorDate, int monthCount) {
    for (int added = 0;
        added < monthCount && !reachedFloor(floorDate);
        added++) {
      final month = _monthsBeforeToday(months.length);
      final daysBeforeFirst = (month.firstDate.weekday - firstWeekday + 7) % 7;
      final weekCount = ((daysBeforeFirst + month.length) / 7).ceil();
      months.add(MonthLayout(
        calendarYear: month.year,
        calendarMonth: month.month,
        firstDate: month.firstDate,
        lastDate: month.lastDate,
        firstRow: rowCount,
        weekCount: weekCount,
      ));
      rowCount += weekCount + 1;
    }
  }

  int monthIndexForRow(int row) {
    int lowIndex = 0, highIndex = months.length - 1;
    while (lowIndex < highIndex) {
      final middleIndex = (lowIndex + highIndex + 1) >> 1;
      if (months[middleIndex].firstRow > row) {
        highIndex = middleIndex - 1;
      } else {
        lowIndex = middleIndex;
      }
    }
    return lowIndex;
  }

  int indexOfMonthContaining(DateTime date) {
    return months.indexWhere((layout) =>
        !date.isBefore(layout.firstDate) &&
        date.isBefore(DateTime(layout.lastDate.year, layout.lastDate.month,
            layout.lastDate.day + 1)));
  }

  List<DateTime?> weekDays(MonthLayout layout, int weekIndex,
      {required bool Function(DateTime day) isHidden}) {
    final start = _weekStart(layout, weekIndex);
    return List<DateTime?>.generate(7, (dayOffset) {
      final day = DateTime(start.year, start.month, start.day + dayOffset);
      return !isHidden(day) && _isInMonth(day, layout) ? day : null;
    });
  }

  DateTime _weekStart(MonthLayout layout, int weekIndex) {
    final daysFromWeekStart = (layout.lastDate.weekday - firstWeekday + 7) % 7;
    // Use the DateTime constructor to subtract days so the shift never
    // drifts across a daylight-saving transition.
    return DateTime(layout.lastDate.year, layout.lastDate.month,
        layout.lastDate.day - daysFromWeekStart - 7 * weekIndex);
  }

  int _weekIndexOfToday() {
    final layout = months.first;
    for (int week = 0; week < layout.weekCount; week++) {
      final start = _weekStart(layout, week);
      final end = DateTime(start.year, start.month, start.day + 7);
      if (!today.isBefore(start) && today.isBefore(end)) return week;
    }
    return 0;
  }

  bool _isInMonth(DateTime day, MonthLayout layout) {
    if (!isJalali) {
      return day.year == layout.calendarYear &&
          day.month == layout.calendarMonth;
    }
    final jalali = Jalali.fromDateTime(day);
    return jalali.year == layout.calendarYear &&
        jalali.month == layout.calendarMonth;
  }

  ({int year, int month, int length, DateTime firstDate, DateTime lastDate})
      _monthsBeforeToday(int monthCount) {
    if (isJalali) {
      final todayJalali = Jalali.fromDateTime(today);
      final jalali =
          Jalali(todayJalali.year, todayJalali.month, 1).addMonths(-monthCount);
      return (
        year: jalali.year,
        month: jalali.month,
        length: jalali.monthLength,
        firstDate: jalali.toDateTime(),
        lastDate:
            Jalali(jalali.year, jalali.month, jalali.monthLength).toDateTime(),
      );
    }
    final firstDate = DateTime(today.year, today.month - monthCount, 1);
    // Day 0 of the following month is the last day of this one.
    final lastDate = DateTime(firstDate.year, firstDate.month + 1, 0);
    return (
      year: firstDate.year,
      month: firstDate.month,
      length: lastDate.day,
      firstDate: firstDate,
      lastDate: lastDate,
    );
  }
}
