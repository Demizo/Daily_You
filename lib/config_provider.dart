import 'dart:async';
import 'package:daily_you/config_manager.dart';
import 'package:daily_you/widgets/stat_range_selector.dart';
import 'package:flutter/material.dart';

class ConfigProvider with ChangeNotifier {
  static final ConfigProvider instance = ConfigProvider._init();

  ConfigProvider._init();

  String calendarViewMode = "mood";

  StatsRange statsRange = StatsRange.month;

  bool dailyReminders = ConfigManager.instance.getField('dailyReminders');

  Future<void> updateConfig() async {
    dailyReminders = ConfigManager.instance.getField('dailyReminders');
    calendarViewMode = ConfigManager.instance.getField('calendarViewMode');
    notifyListeners();
  }
}
