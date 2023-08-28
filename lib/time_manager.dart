import 'package:daily_you/config_manager.dart';
import 'package:flutter/material.dart';

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

  static String timeOfDayString(TimeOfDay timeOfDay) {
    return '${timeOfDay.hourOfPeriod}:${timeOfDay.minute.toString().padLeft(2, '0')} ${timeOfDay.period.name.toUpperCase()}';
  }
}
