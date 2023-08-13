import 'dart:io';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:daily_you/main.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationManager {
  static final NotificationManager instance = NotificationManager._init();

  static FlutterLocalNotificationsPlugin? _notifications;

  bool justLaunched = true;

  FlutterLocalNotificationsPlugin get notifications {
    return _notifications!;
  }

  NotificationManager._init();

  static final NotificationManager _instance = NotificationManager._internal();

  factory NotificationManager() {
    return _instance;
  }

  NotificationManager._internal();

  Future<void> init() async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    _notifications = flutterLocalNotificationsPlugin;

    await _notifications!.initialize(const InitializationSettings(
        android:
            AndroidInitializationSettings('@mipmap/ic_launcher_monochrome'),
        linux: LinuxInitializationSettings(defaultActionName: 'Log Today')));
  }

  Future<bool> hasNotificationPermission() async {
    if (Platform.isAndroid) {
      var hasPermissions = await _notifications!
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()!
          .requestPermission();
      if (hasPermissions != null && hasPermissions) {
        return true;
      }
    }
    return false;
  }

  Future<void> stopDailyReminders() async {
    await AndroidAlarmManager.cancel(0);
  }

  Future<void> startScheduledDailyReminders() async {
    setAlarm();
  }
}
