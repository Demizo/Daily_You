import 'dart:io';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:daily_you/main.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

const int backupNotificationId = 2;
const String backupNotificationChannelId = 'daily_you_backup';
const String backupCancelActionId = 'cancel_auto_backup';
const String _backupCancelRequestedPrefsKey = 'autoBackupCancelRequested';

// May run on its own background isolate, separate from the backup's.
@pragma('vm:entry-point')
void backupCancelBackgroundHandler(NotificationResponse response) async {
  if (response.actionId != backupCancelActionId) return;
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationManager.instance.requestBackupCancel();
}

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

    await _notifications!.initialize(
        settings: const InitializationSettings(
            android: AndroidInitializationSettings('@drawable/ic_notification'),
            linux: LinuxInitializationSettings(defaultActionName: 'Log Today')),
        onDidReceiveNotificationResponse: backupCancelBackgroundHandler,
        onDidReceiveBackgroundNotificationResponse:
            backupCancelBackgroundHandler);
  }

  // SharedPreferencesAsync, not SharedPreferences.getInstance() which caches the whole map
  Future<void> requestBackupCancel() =>
      _asyncPrefs.setBool(_backupCancelRequestedPrefsKey, true);

  Future<bool> isBackupCancelRequested() async =>
      (await _asyncPrefs.getBool(_backupCancelRequestedPrefsKey)) ?? false;

  Future<void> clearBackupCancelRequest() =>
      _asyncPrefs.remove(_backupCancelRequestedPrefsKey);

  final SharedPreferencesAsync _asyncPrefs = SharedPreferencesAsync();

  Future<bool> hasNotificationPermission() async {
    if (Platform.isAndroid) {
      var hasPermissions = await _notifications!
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()!
          .requestNotificationsPermission();

      if (hasPermissions ?? false) {
        await requestExactAlarmPermission();
        return true;
      }
    }
    return false;
  }

  /// Prompt the user to grant exact alarm scheduling.
  /// It is not a requirement, reminders will fall back to inexact.
  Future<void> requestExactAlarmPermission() async {
    if (!await _supportsExactAlarmPermission()) {
      return;
    }

    var status = await Permission.scheduleExactAlarm.status;
    if (!status.isGranted) {
      await Permission.scheduleExactAlarm.request();
    }
  }

  Future<bool> canScheduleExactAlarms() async {
    if (!await _supportsExactAlarmPermission()) {
      return true;
    }
    return (await Permission.scheduleExactAlarm.status).isGranted;
  }

  Future<bool> _supportsExactAlarmPermission() async {
    if (!Platform.isAndroid) {
      return false;
    }
    var androidInfo = await DeviceInfoPlugin().androidInfo;
    return androidInfo.version.sdkInt > 30;
  }

  Future<void> dismissReminderNotification() async {
    var activeNotifications = await NotificationManager.instance.notifications
        .getActiveNotifications();
    for (var notif in activeNotifications) {
      if (notif.id == 0) {
        await NotificationManager.instance.notifications.cancel(id: 0);
      }
    }
  }

  Future<void> dismissOnThisDayNotification() async {
    var activeNotifications = await NotificationManager.instance.notifications
        .getActiveNotifications();
    for (var notif in activeNotifications) {
      if (notif.id == 1) {
        await NotificationManager.instance.notifications.cancel(id: 1);
      }
    }
  }

  Future<void> stopDailyReminders() async {
    await AndroidAlarmManager.cancel(0);
    await dismissReminderNotification();
  }

  Future<void> startScheduledDailyReminders() async {
    setAlarm(firstSet: true);
  }

  Future<void> stopOnThisDayNotifications() async {
    await AndroidAlarmManager.cancel(1);
    await dismissOnThisDayNotification();
  }

  Future<void> startOnThisDayNotifications() async {
    setOnThisDayAlarm(firstSet: true);
  }

  AndroidFlutterLocalNotificationsPlugin get _android =>
      _notifications!.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()!;

  Future<void> showBackupProgress(int percent, String title,
      {String? cancelLabel}) async {
    await _android.startForegroundService(
      id: backupNotificationId,
      title: title,
      notificationDetails: AndroidNotificationDetails(
        backupNotificationChannelId,
        title,
        icon: '@drawable/ic_notification',
        importance: Importance.low,
        priority: Priority.low,
        showProgress: true,
        maxProgress: 100,
        progress: percent,
        onlyAlertOnce: true,
        actions: cancelLabel == null
            ? null
            : [
                AndroidNotificationAction(
                  backupCancelActionId,
                  cancelLabel,
                  showsUserInterface: false,
                ),
              ],
      ),
      foregroundServiceTypes: const {
        AndroidServiceForegroundType.foregroundServiceTypeDataSync
      },
    );
  }

  Future<void> stopBackupProgress() => _android.stopForegroundService();

  Future<void> showBackupFailed(String title) async {
    await _android.stopForegroundService();
    await _notifications!.show(
        id: backupNotificationId,
        title: title,
        body: null,
        notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
          backupNotificationChannelId,
          title,
          icon: '@drawable/ic_notification',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        )),
        payload: DateTime.now().toIso8601String());
  }
}
