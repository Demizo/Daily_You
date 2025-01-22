import 'package:daily_you/config_manager.dart';
import 'package:flutter/material.dart';
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
        hour: ConfigManager.instance.getField('scheduledReminderHour'),
        minute: ConfigManager.instance.getField('scheduledReminderMinute'));
  }

  static TimeRange getReminderTimeRange() {
    TimeOfDay startTime = TimeOfDay(
        hour: ConfigManager.instance.getField('reminderStartHour'),
        minute: ConfigManager.instance.getField('reminderStartMinute'));
    TimeOfDay endTime = TimeOfDay(
        hour: ConfigManager.instance.getField('reminderEndHour'),
        minute: ConfigManager.instance.getField('reminderEndMinute'));

    return TimeRange(startTime: startTime, endTime: endTime);
  }

  static Future<void> setReminderTimeRange(TimeRange range) async {
    await ConfigManager.instance.setField('reminderStartHour', range.startTime.hour);
    await ConfigManager.instance.setField('reminderStartMinute', range.startTime.minute);
    await ConfigManager.instance.setField('reminderEndHour', range.endTime.hour);
    await ConfigManager.instance.setField('reminderEndMinute', range.endTime.minute);
  }

  static String timeRangeString(TimeRange timeRange) {
    return '${timeOfDayString(timeRange.startTime)} to ${timeOfDayString(timeRange.endTime)}';
  }

  static String timeOfDayString(TimeOfDay timeOfDay) {
    return '${timeOfDay.hourOfPeriod}:${timeOfDay.minute.toString().padLeft(2, '0')} ${timeOfDay.period.name.toUpperCase()}';
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
