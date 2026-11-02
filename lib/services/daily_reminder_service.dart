// Copyright (C) 2026 Daily You TH3 Learning English
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Dịch vụ quản lý thông báo nhắc nhở học tiếng Anh hằng ngày (Checklist 6 - TV3).
class DailyReminderService {
  static const int reminderNotificationId = 1001;
  static const int testNotificationId = 1002;

  static const String channelId = 'daily_english_learning_reminder';
  static const String channelName = 'Nhắc nhở học tiếng Anh';
  static const String channelDescription =
      'Thông báo nhắc nhở luyện tập phát âm và duy trì streak tiếng Anh mỗi ngày';

  static const String prefReminderEnabled = 'english_reminder_enabled';
  static const String prefReminderHour = 'english_reminder_hour';
  static const String prefReminderMinute = 'english_reminder_minute';
  static const String prefDailyGoalMinutes = 'english_daily_goal_minutes';
  static const String prefOnlyIfPending = 'english_reminder_only_if_pending';

  static final DailyReminderService _instance =
      DailyReminderService._internal();
  factory DailyReminderService() => _instance;
  DailyReminderService._internal();

  FlutterLocalNotificationsPlugin? _notificationsPlugin;
  bool _isInitialized = false;

  /// Khởi tạo service thông báo cục bộ.
  Future<void> init({FlutterLocalNotificationsPlugin? plugin}) async {
    if (_isInitialized) return;

    _notificationsPlugin = plugin ?? FlutterLocalNotificationsPlugin();

    // Khởi tạo múi giờ
    try {
      tz.initializeTimeZones();
    } catch (_) {
      // Bỏ qua nếu đã được khởi tạo
    }

    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Luyện tập ngay',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      linux: linuxSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notificationsPlugin!.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        // Callback khi người dùng ấn vào thông báo
      },
    );

    _isInitialized = true;
  }

  /// Yêu cầu quyền gửi thông báo trên Android 13+ (POST_NOTIFICATIONS) và iOS.
  Future<bool> requestNotificationPermissions() async {
    if (_notificationsPlugin == null) await init();

    if (Platform.isAndroid) {
      final androidPlugin = _notificationsPlugin!
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }
    } else if (Platform.isIOS) {
      final iosPlugin = _notificationsPlugin!
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    }
    return true;
  }

  /// Lập lịch thông báo định kỳ hằng ngày vào mốc giờ [time].
  Future<void> scheduleDailyReminder({
    required TimeOfDay time,
    String? title,
    String? body,
  }) async {
    if (_notificationsPlugin == null) await init();

    // Hủy lịch cũ trước khi lập lịch mới
    await cancelDailyReminder();

    final scheduledDate = _nextInstanceOfTime(time);

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
      category: AndroidNotificationCategory.reminder,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final notificationTitle =
        title ?? '🔥 Giữ vững chuỗi streak tiếng Anh của bạn!';
    final notificationBody = body ??
        'Đã đến giờ luyện tập phát âm hằng ngày. Dành 15 phút để hoàn thành mục tiêu hôm nay nhé!';

    try {
      await _notificationsPlugin!.zonedSchedule(
        id: reminderNotificationId,
        title: notificationTitle,
        body: notificationBody,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      // Fallback nếu exact alarm bị giới hạn trên một số thiết bị Android cũ
      await _notificationsPlugin!.zonedSchedule(
        id: reminderNotificationId,
        title: notificationTitle,
        body: notificationBody,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }

    // Lưu vào preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefReminderEnabled, true);
    await prefs.setInt(prefReminderHour, time.hour);
    await prefs.setInt(prefReminderMinute, time.minute);
  }

  /// Hủy lịch nhắc nhở hằng ngày.
  Future<void> cancelDailyReminder() async {
    if (_notificationsPlugin == null) await init();
    await _notificationsPlugin!.cancel(id: reminderNotificationId);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefReminderEnabled, false);
  }

  /// Bắn thông báo kiểm thử ngay lập tức (Test Notification).
  Future<void> sendTestNotification({
    String? title,
    String? body,
  }) async {
    if (_notificationsPlugin == null) await init();

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin!.show(
      id: testNotificationId,
      title: title ?? '🎯 Kiểm tra nhắc nhở: Daily You Learning English',
      body: body ??
          'Thông báo đang hoạt động hoàn hảo! Đừng quên luyện phát âm hôm nay để duy trì streak nhé!',
      notificationDetails: details,
    );
  }

  /// Tính toán thời điểm tiếp theo cho mốc giờ nhắc nhở.
  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  // --- CÁC HÀM GETTER / SETTER CẤU HÌNH ---

  Future<bool> isReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefReminderEnabled) ?? false;
  }

  Future<TimeOfDay> getReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(prefReminderHour) ?? 20; // Mặc định 20:00
    final minute = prefs.getInt(prefReminderMinute) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<int> getDailyGoalMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(prefDailyGoalMinutes) ?? 20; // Mặc định 20 phút/ngày
  }

  Future<void> setDailyGoalMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(prefDailyGoalMinutes, minutes);
  }

  Future<bool> isOnlyIfPending() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefOnlyIfPending) ?? true;
  }

  Future<void> setOnlyIfPending(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefOnlyIfPending, value);
  }
}
