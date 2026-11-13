// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:shamsi_date/shamsi_date.dart';

typedef YearMonth = ({int year, int month});

class YearMonthRange {
  YearMonthRange({
    required this.isJalali,
    required DateTime earliestDate,
    required DateTime latestDate,
  })  : earliest = _yearMonthOf(earliestDate, isJalali),
        latest = _yearMonthOf(latestDate, isJalali);

  final bool isJalali;
  final YearMonth earliest;
  final YearMonth latest;

  bool isMonthEnabled(int year, int month) {
    final number = _monthNumber((year: year, month: month));
    return number >= _monthNumber(earliest) && number <= _monthNumber(latest);
  }

  int clampMonth(int year, int month) {
    final lowest = year == earliest.year ? earliest.month : 1;
    final highest = year == latest.year ? latest.month : 12;
    return month.clamp(lowest, highest);
  }

  YearMonth clamp(DateTime date) {
    final yearMonth = _yearMonthOf(date, isJalali);
    final year = yearMonth.year.clamp(earliest.year, latest.year);
    return (year: year, month: clampMonth(year, yearMonth.month));
  }

  DateTime toDate(int year, int month, [int day = 1]) => isJalali
      ? Jalali(year, month, day).toDateTime()
      : DateTime(year, month, day);

  int daysIn(int year, int month) => isJalali
      ? Jalali(year, month).monthLength
      : DateTime(year, month + 1, 0).day;

  int get monthCount => _monthNumber(latest) - _monthNumber(earliest) + 1;

  YearMonth monthAt(int index) {
    final number = _monthNumber(earliest) + index;
    return (year: (number - 1) ~/ 12, month: (number - 1) % 12 + 1);
  }

  int indexOf(DateTime date) =>
      (_monthNumber(_yearMonthOf(date, isJalali)) - _monthNumber(earliest))
          .clamp(0, monthCount - 1);
}

int _monthNumber(YearMonth yearMonth) => yearMonth.year * 12 + yearMonth.month;

YearMonth _yearMonthOf(DateTime date, bool isJalali) {
  if (!isJalali) return (year: date.year, month: date.month);
  final jalali = Jalali.fromDateTime(date);
  return (year: jalali.year, month: jalali.month);
}
