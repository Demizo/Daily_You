import 'package:daily_you/config_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  static String timeRangeString(TimeRange timeRange) {
    return '${timeOfDayString(timeRange.startTime)} - ${timeOfDayString(timeRange.endTime)}';
  }

  static String timeOfDayString(TimeOfDay timeOfDay) {
    return DateFormat.jm(
            WidgetsBinding.instance.platformDispatcher.locale.toString())
        .format(addTimeOfDay(startOfDay(DateTime.now()), timeOfDay));
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

  static List<String> daysOfWeekLabels() {
    final now = DateTime.now();
    final formatter = DateFormat.E(
        WidgetsBinding.instance.platformDispatcher.locale.toString());

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
}
