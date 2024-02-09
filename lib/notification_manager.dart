import 'dart:io';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:daily_you/main.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

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
        android: AndroidInitializationSettings('@mipmap/ic_reminder_icon'),
        linux: LinuxInitializationSettings(defaultActionName: 'Log Today')));
  }

  Future<bool> hasNotificationPermission() async {
    if (Platform.isAndroid) {
      var hasPermissions = await _notifications!
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()!
          .requestNotificationsPermission();

      if (hasPermissions != null && hasPermissions) {
        return await requestAlarmPermission();
      }
    }
    return false;
  }

  Future<bool> requestAlarmPermission() async {
    DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;

    if (androidInfo.version.sdkInt > 30) {
      //Request alarm permission
      var status = await Permission.scheduleExactAlarm.status;
      if (!status.isGranted) {
        status = await Permission.scheduleExactAlarm.request();
      }
      if (status.isGranted) {
        return true;
      }
      return false;
    }

    return true;
  }

  Future<void> stopDailyReminders() async {
    await AndroidAlarmManager.cancel(0);
    await NotificationManager.instance.notifications.cancel(0);
  }

  Future<void> startScheduledDailyReminders() async {
    setAlarm();
  }
}
