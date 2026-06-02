import 'dart:ui' show PlatformDispatcher;

import 'package:daily_you/config_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:time_range_picker/time_range_picker.dart';

class TimeManager {
  static bool isToday(DateTime date) {
    return isSameDay(DateTime.now(), date);
  }

  static bool isSameDay(DateTime dayOne, DateTime dayTwo) {
    if (dayOne.year == dayTwo.year &&
        dayOne.month == dayTwo.month &&
        dayOne.day == dayTwo.day) {
      return true;
    }
    return false;
  }

  static bool isSameMonth(DateTime dayOne, DateTime dayTwo) {
    if (dayOne.year == dayTwo.year && dayOne.month == dayTwo.month) {
      return true;
    }
    return false;
  }

  static DateTime startOfDay(DateTime dateTime) {
    return dateTime.copyWith(
        hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
  }

  static DateTime startOfNextDay() {
    return startOfDay(DateTime.now().add(const Duration(days: 1)));
  }

  static DateTime addTimeOfDay(DateTime dateTime, TimeOfDay timeOfDay) {
    return dateTime
        .add(Duration(hours: timeOfDay.hour, minutes: timeOfDay.minute));
  }

  static DateTime currentTimeOnDifferentDate(DateTime targetDate) {
    return addTimeOfDay(startOfDay(targetDate), TimeOfDay.now());
  }

  static TimeOfDay scheduledReminderTime() {
    return TimeOfDay(
        hour: ConfigProvider.instance.get(ConfigKey.scheduledReminderHour),
        minute: ConfigProvider.instance.get(ConfigKey.scheduledReminderMinute));
  }

  static TimeRange getReminderTimeRange() {
    TimeOfDay startTime = TimeOfDay(
        hour: ConfigProvider.instance.get(ConfigKey.reminderStartHour),
        minute: ConfigProvider.instance.get(ConfigKey.reminderStartMinute));
    TimeOfDay endTime = TimeOfDay(
        hour: ConfigProvider.instance.get(ConfigKey.reminderEndHour),
        minute: ConfigProvider.instance.get(ConfigKey.reminderEndMinute));

    return TimeRange(startTime: startTime, endTime: endTime);
  }

  static Future<void> setReminderTimeRange(TimeRange range) async {
    await ConfigProvider.instance
        .set(ConfigKey.reminderStartHour, range.startTime.hour);
    await ConfigProvider.instance
        .set(ConfigKey.reminderStartMinute, range.startTime.minute);
    await ConfigProvider.instance
        .set(ConfigKey.reminderEndHour, range.endTime.hour);
    await ConfigProvider.instance
        .set(ConfigKey.reminderEndMinute, range.endTime.minute);
  }

  static String timeRangeString(BuildContext context, TimeRange timeRange) {
    return '${timeOfDayString(context, timeRange.startTime)} - ${timeOfDayString(context, timeRange.endTime)}';
  }

  static String timeOfDayString(BuildContext context, TimeOfDay timeOfDay) {
    return localizedTimeFormat(TimeManager.currentLocale(context))
        .format(addTimeOfDay(startOfDay(DateTime.now()), timeOfDay));
  }

  static DateFormat localizedTimeFormat(String locale) {
    if (PlatformDispatcher.instance.alwaysUse24HourFormat) {
      return DateFormat.Hm(locale);
    }
    return DateFormat.jm(locale);
  }

  static final Map<int, String> dayOfWeekIndexMapping = {
    0: 'monday',
    1: 'tuesday',
    2: 'wednesday',
    3: 'thursday',
    4: 'friday',
    5: 'saturday',
    6: 'sunday',
  };

  static List<String> daysOfWeekLabels(BuildContext context) {
    final now = DateTime.now();
    final formatter = DateFormat.E(TimeManager.currentLocale(context));

    List<String> days = List.generate(7, (index) {
      final day = now
          .subtract(Duration(days: now.weekday - 1))
          .add(Duration(days: index));
      return formatter.format(day); // Gets localized short name
    });

    return days;
  }

  static int datesExactMonthDiff(DateTime date1, DateTime date2) {
    if (date1.day != date2.day) return -1;
    // Check if the year and month components are the same
    if (date1.year == date2.year && date1.month == date2.month) {
      return -1;
    }

    // Calculate the difference in months between the two dates
    int monthDiff = (date2.year - date1.year) * 12 + date2.month - date1.month;

    // If the absolute difference is 1, they are a month apart
    return monthDiff.abs();
  }

  static String currentLocale(BuildContext context) {
    final platformLocale = Localizations.localeOf(context);
    if (platformLocale.languageCode == "oc") {
      return Locale("fr").toString();
    }
    return platformLocale.toString();
  }

  static bool isJalaliCalendar(BuildContext context) {
    final setting =
        ConfigProvider.instance.get(ConfigKey.calendarSystem) ?? 'system';
    if (setting == 'jalali') return true;
    if (setting == 'gregorian') return false;
    return Localizations.localeOf(context).languageCode == 'fa';
  }

  // Returns the Jalali month name. Uses Persian script for fa locale,
  // Finglish (Latin) otherwise.
  static String jalaliMonthName(int month, String locale) {
    final f = Jalali(1400, month, 1).formatter;
    return locale.startsWith('fa') ? f.mN : f.mNFn;
  }

  static int jalaliDayNumber(DateTime date) => Jalali.fromDateTime(date).day;

  static String formatDate(DateTime date, BuildContext context) =>
      _formatDate(date, currentLocale(context),
          isJalali: isJalaliCalendar(context));

  static String formatDateWithWeekday(DateTime date, BuildContext context) =>
      _formatDateWithWeekday(date, currentLocale(context),
          isJalali: isJalaliCalendar(context));

  static String formatMonthDay(DateTime date, BuildContext context) =>
      _formatMonthDay(date, currentLocale(context),
          isJalali: isJalaliCalendar(context));

  static String formatYear(DateTime date, BuildContext context) =>
      _formatYear(date, currentLocale(context),
          isJalali: isJalaliCalendar(context));

  static String formatMonthYear(DateTime date, BuildContext context) =>
      _formatMonthYear(date, currentLocale(context),
          isJalali: isJalaliCalendar(context));

  static String _formatDate(DateTime date, String locale,
      {bool isJalali = false}) {
    if (!isJalali) return DateFormat.yMMMd(locale).format(date);
    final j = Jalali.fromDateTime(date);
    return '${j.formatter.d} ${jalaliMonthName(j.month, locale)} ${j.formatter.yyyy}';
  }

  static String _formatDateWithWeekday(DateTime date, String locale,
      {bool isJalali = false}) {
    if (!isJalali) return DateFormat.yMMMEd(locale).format(date);
    final j = Jalali.fromDateTime(date);
    final weekday = DateFormat.E(locale).format(date);
    return '$weekday ${j.formatter.d} ${jalaliMonthName(j.month, locale)} ${j.formatter.yyyy}';
  }

  static String _formatMonthDay(DateTime date, String locale,
      {bool isJalali = false}) {
    if (!isJalali) return DateFormat.MMMd(locale).format(date);
    final j = Jalali.fromDateTime(date);
    return '${j.formatter.d} ${jalaliMonthName(j.month, locale)}';
  }

  static String _formatYear(DateTime date, String locale,
      {bool isJalali = false}) {
    if (!isJalali) return DateFormat.y(locale).format(date);
    return Jalali.fromDateTime(date).formatter.yyyy;
  }

  static String _formatMonthYear(DateTime date, String locale,
      {bool isJalali = false}) {
    if (!isJalali) return DateFormat('MMMM y', locale).format(date);
    final j = Jalali.fromDateTime(date);
    return '${jalaliMonthName(j.month, locale)} ${j.formatter.yyyy}';
  }
}
