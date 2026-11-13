// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math';

import 'package:daily_you/models/gallery_filter.dart';
import 'package:daily_you/time_manager.dart';
import 'package:shamsi_date/shamsi_date.dart';

typedef DayRange = ({DateTime start, DateTime endExclusive});

DateTime _dayOf(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime _nextDayOf(DateTime date) =>
    DateTime(date.year, date.month, date.day + 1);

DateTime _monthsBefore(DateTime day, int months, {required bool isJalali}) {
  if (isJalali) return _jalaliMonthsBefore(day, months);
  final firstOfMonth = DateTime(day.year, day.month - months, 1);
  final lastDay = DateTime(firstOfMonth.year, firstOfMonth.month + 1, 0).day;
  return DateTime(
    firstOfMonth.year,
    firstOfMonth.month,
    min(day.day, lastDay),
  );
}

DateTime _jalaliMonthsBefore(DateTime day, int months) {
  final jalali = Jalali.fromDateTime(day);
  final monthIndex = jalali.year * 12 + jalali.month - 1 - months;
  final year = monthIndex ~/ 12;
  final month = monthIndex % 12 + 1;
  final lastDay = Jalali(year, month, 1).monthLength;
  return Jalali(year, month, min(jalali.day, lastDay)).toDateTime();
}

DateTime firstDayOfYear(int year, {required bool isJalali}) =>
    isJalali ? Jalali(year, 1, 1).toDateTime() : DateTime(year, 1, 1);

DayRange? dayRangeOf(DateSelection selection, DateTime today) =>
    switch (selection) {
      NoDateSelection() => null,
      LastMonthsSelection(:final months, :final isJalali) => (
          start: _monthsBefore(_dayOf(today), months, isJalali: isJalali),
          endExclusive: _nextDayOf(today),
        ),
      CalendarYearSelection(:final year, :final isJalali) => (
          start: firstDayOfYear(year, isJalali: isJalali),
          endExclusive: firstDayOfYear(year + 1, isJalali: isJalali),
        ),
      CustomRangeSelection(:final start, :final end) => (
          start: _dayOf(start),
          endExclusive: _nextDayOf(end),
        ),
    };

List<int> calendarYearsOf(
  Iterable<DateTime> dates, {
  required bool isJalali,
}) =>
    ({for (final date in dates) TimeManager.calendarYearOf(date, isJalali)}
        .toList()
      ..sort((a, b) => b.compareTo(a)));
