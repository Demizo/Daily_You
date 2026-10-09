// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:material_ui/material_ui.dart';
import 'package:shamsi_date/shamsi_date.dart';

/// Reports the Jalali year, month and day to the date picker while ordering
/// and arithmetic use the Gregorian date it wraps.
class JalaliDate implements DateTime {
  JalaliDate.fromGregorian(DateTime date)
      : gregorian = DateTime(date.year, date.month, date.day),
        jalali = Jalali.fromDateTime(date);

  JalaliDate.fromJalali(this.jalali) : gregorian = jalali.toDateTime();

  final DateTime gregorian;
  final Jalali jalali;

  static DateTime toGregorian(DateTime date) =>
      date is JalaliDate ? date.gregorian : date;

  @override
  int get year => jalali.year;

  @override
  int get month => jalali.month;

  @override
  int get day => jalali.day;

  @override
  int get weekday => gregorian.weekday;

  @override
  int get hour => 0;

  @override
  int get minute => 0;

  @override
  int get second => 0;

  @override
  int get millisecond => 0;

  @override
  int get microsecond => 0;

  @override
  bool get isUtc => false;

  @override
  int get millisecondsSinceEpoch => gregorian.millisecondsSinceEpoch;

  @override
  int get microsecondsSinceEpoch => gregorian.microsecondsSinceEpoch;

  @override
  String get timeZoneName => gregorian.timeZoneName;

  @override
  Duration get timeZoneOffset => gregorian.timeZoneOffset;

  @override
  bool isBefore(DateTime other) => gregorian.isBefore(toGregorian(other));

  @override
  bool isAfter(DateTime other) => gregorian.isAfter(toGregorian(other));

  @override
  bool isAtSameMomentAs(DateTime other) =>
      gregorian.isAtSameMomentAs(toGregorian(other));

  @override
  int compareTo(DateTime other) => gregorian.compareTo(toGregorian(other));

  @override
  Duration difference(DateTime other) =>
      gregorian.difference(toGregorian(other));

  @override
  DateTime add(Duration duration) =>
      JalaliDate.fromGregorian(gregorian.add(duration));

  @override
  DateTime subtract(Duration duration) =>
      JalaliDate.fromGregorian(gregorian.subtract(duration));

  @override
  DateTime toLocal() => this;

  @override
  DateTime toUtc() => gregorian.toUtc();

  @override
  String toIso8601String() => gregorian.toIso8601String();

  @override
  String toString() => gregorian.toString();

  @override
  bool operator ==(Object other) =>
      other is JalaliDate && gregorian == other.gregorian;

  @override
  int get hashCode => gregorian.hashCode;
}

class JalaliCalendarDelegate extends CalendarDelegate<DateTime> {
  const JalaliCalendarDelegate();

  static Jalali _jalali(DateTime date) =>
      date is JalaliDate ? date.jalali : Jalali.fromDateTime(date);

  @override
  DateTime now() => JalaliDate.fromGregorian(DateTime.now());

  @override
  DateTime dateOnly(DateTime date) =>
      JalaliDate.fromGregorian(JalaliDate.toGregorian(date));

  @override
  int monthDelta(DateTime startDate, DateTime endDate) =>
      (endDate.year - startDate.year) * 12 + endDate.month - startDate.month;

  @override
  DateTime addMonthsToMonthDate(DateTime monthDate, int monthsToAdd) {
    final monthIndex = monthDate.year * 12 + monthDate.month - 1 + monthsToAdd;
    return getMonth(monthIndex ~/ 12, monthIndex % 12 + 1);
  }

  @override
  DateTime addDaysToDate(DateTime date, int days) {
    final gregorian = JalaliDate.toGregorian(date);
    return JalaliDate.fromGregorian(
        DateTime(gregorian.year, gregorian.month, gregorian.day + days));
  }

  @override
  int firstDayOffset(int year, int month, MaterialLocalizations localizations) {
    final weekdayFromMonday = getDay(year, month, 1).weekday - 1;
    final firstDayOfWeekIndex = (localizations.firstDayOfWeekIndex - 1) % 7;
    return (weekdayFromMonday - firstDayOfWeekIndex + 7) % 7;
  }

  @override
  int getDaysInMonth(int year, int month) => Jalali(year, month).monthLength;

  @override
  DateTime getMonth(int year, int month) => getDay(year, month, 1);

  @override
  DateTime getDay(int year, int month, int day) =>
      JalaliDate.fromJalali(Jalali(year, month, day));

  @override
  String formatYear(int year, MaterialLocalizations localizations) =>
      _digits(year, localizations);

  @override
  String formatMonthYear(DateTime date, MaterialLocalizations localizations) =>
      '${_monthName(date)} ${_digits(date.year, localizations)}';

  @override
  String formatMediumDate(DateTime date, MaterialLocalizations localizations) =>
      '${_weekdayName(date)} ${formatShortMonthDay(date, localizations)}';

  @override
  String formatShortMonthDay(
          DateTime date, MaterialLocalizations localizations) =>
      '${_digits(date.day, localizations)} ${_monthName(date)}';

  @override
  String formatShortDate(DateTime date, MaterialLocalizations localizations) =>
      '${formatShortMonthDay(date, localizations)} ${_digits(date.year, localizations)}';

  @override
  String formatFullDate(DateTime date, MaterialLocalizations localizations) =>
      '${_weekdayName(date)}، ${formatShortDate(date, localizations)}';

  @override
  String formatCompactDate(DateTime date, MaterialLocalizations localizations) {
    String twoDigits(int value) =>
        _digits(value, localizations).padLeft(2, _digits(0, localizations));
    return '${_digits(date.year, localizations)}/${twoDigits(date.month)}/${twoDigits(date.day)}';
  }

  @override
  DateTime? parseCompactDate(
      String? inputString, MaterialLocalizations localizations) {
    final parts = inputString?.split('/').map(_parseNumber).toList();
    if (parts == null || parts.length != 3 || parts.contains(null)) {
      return null;
    }
    final [year!, month!, day!] = parts;
    if (month < 1 || month > 12 || day < 1) return null;
    if (day > getDaysInMonth(year, month)) return null;
    return getDay(year, month, day);
  }

  @override
  String dateHelpText(MaterialLocalizations localizations) => 'سال/ماه/روز';

  static String _digits(int number, MaterialLocalizations localizations) =>
      number
          .toString()
          .split('')
          .map((digit) => localizations.formatDecimal(int.parse(digit)))
          .join();

  static String _monthName(DateTime date) => _jalali(date).formatter.mN;

  static String _weekdayName(DateTime date) => _jalali(date).formatter.wN;

  static int? _parseNumber(String text) {
    const persianDigits = '۰۱۲۳۴۵۶۷۸۹';
    const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
    final latin = text.trim().split('').map((character) {
      final digit = persianDigits.indexOf(character);
      return digit >= 0
          ? '$digit'
          : arabicDigits.contains(character)
              ? '${arabicDigits.indexOf(character)}'
              : character;
    }).join();
    return int.tryParse(latin);
  }
}
