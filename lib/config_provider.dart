import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:daily_you/time_manager.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class ConfigKey {
  static const String configVersion = "configVersion";
  static const String theme = "theme";
  static const String useExternalDb = "useExternalDb";
  static const String externalDbUri = "externalDbUri";
  static const String useExternalImg = "useExternalImg";
  static const String externalImgUri = "externalImgUri";
  static const String startingDayOfWeek = "startingDayOfWeek";
  static const String useMarkdownToolbar = "useMarkdownToolbar";
  static const String homePageViewMode = "homePageViewMode";
  static const String calendarViewMode = "calendarViewMode";
  static const String galleryPageViewMode = "galleryPageViewMode";
  static const String veryHappyIcon = "veryHappyIcon";
  static const String happyIcon = "happyIcon";
  static const String neutralIcon = "neutralIcon";
  static const String sadIcon = "sadIcon";
  static const String verySadIcon = "verySadIcon";
  static const String noMoodIcon = "noMoodIcon";
  static const String followSystemColor = "followSystemColor";
  static const String accentColor = "accentColor";
  static const String dailyReminders = "dailyReminders";
  static const String setReminderTime = "setReminderTime";
  static const String scheduledReminderHour = "scheduledReminderHour";
  static const String scheduledReminderMinute = "scheduledReminderMinute";
  static const String reminderStartHour = "reminderStartHour";
  static const String reminderStartMinute = "reminderStartMinute";
  static const String reminderEndHour = "reminderEndHour";
  static const String reminderEndMinute = "reminderEndMinute";
  static const String defaultTemplate = "defaultTemplate";
  static const String imageQuality = "imageQuality";
}

class ConfigProvider with ChangeNotifier {
  static final ConfigProvider instance = ConfigProvider._init();

  ConfigProvider._init();

  String configFilePath = '';

  Map<String, dynamic> _config = {};
  final Map<String, dynamic> _defaultConfig = {
    ConfigKey.configVersion: '2',
    ConfigKey.theme: 'system',
    ConfigKey.useExternalDb: false,
    ConfigKey.externalDbUri: '',
    ConfigKey.useExternalImg: false,
    ConfigKey.externalImgUri: '',
    ConfigKey.startingDayOfWeek: 'system',
    ConfigKey.useMarkdownToolbar: true,
    ConfigKey.homePageViewMode: 'list',
    ConfigKey.calendarViewMode: 'image',
    ConfigKey.galleryPageViewMode: 'grid',
    ConfigKey.veryHappyIcon: '☺️',
    ConfigKey.happyIcon: '🙂',
    ConfigKey.neutralIcon: '😐',
    ConfigKey.sadIcon: '😕',
    ConfigKey.verySadIcon: '😔',
    ConfigKey.noMoodIcon: '?',
    ConfigKey.followSystemColor: true,
    ConfigKey.accentColor: 0xff01d3ef,
    ConfigKey.dailyReminders: false,
    ConfigKey.setReminderTime: false,
    ConfigKey.scheduledReminderHour: 12,
    ConfigKey.scheduledReminderMinute: 0,
    ConfigKey.reminderStartHour: 9,
    ConfigKey.reminderStartMinute: 0,
    ConfigKey.reminderEndHour: 21,
    ConfigKey.reminderEndMinute: 0,
    ConfigKey.defaultTemplate: -1,
    ConfigKey.imageQuality: 90,
  };

  static final moodValueFieldMapping = {
    2: ConfigKey.veryHappyIcon,
    1: ConfigKey.happyIcon,
    0: ConfigKey.neutralIcon,
    -1: ConfigKey.sadIcon,
    -2: ConfigKey.verySadIcon,
  };

  static final defaultMoodIconFieldMapping = {
    ConfigKey.veryHappyIcon: '☺️',
    ConfigKey.happyIcon: '🙂',
    ConfigKey.neutralIcon: '😐',
    ConfigKey.sadIcon: '😕',
    ConfigKey.verySadIcon: '😔',
    ConfigKey.noMoodIcon: '?',
  };

  dynamic get(String field) {
    return _config[field];
  }

  Future<void> set(String field, dynamic value) async {
    _config[field] = value;
    notifyListeners();
    await writeConfig();
  }

  Future<void> init() async {
    initializeDateFormatting();

    Directory dbPath;
    if (Platform.isAndroid) {
      dbPath = (await getExternalStorageDirectory())!;
    } else {
      dbPath = await getApplicationSupportDirectory();
    }
    configFilePath = join(dbPath.path, 'config.json');
    final configFile = File(configFilePath);
    if (!(await configFile.exists())) {
      await configFile.create();
      await configFile.writeAsString('{}');
    }
    await poplulateDefaults();
    await readConfig();
  }

  Future<void> poplulateDefaults() async {
    await readConfig();

    // Set default config data
    for (String key in _defaultConfig.keys) {
      if (!_config.containsKey(key)) {
        _config[key] = _defaultConfig[key];
      }
    }

    await writeConfig();
  }

  Future<void> readConfig() async {
    final configFile = File(configFilePath);
    if (await configFile.exists()) {
      final configFileContent = await configFile.readAsString();
      _config = json.decode(configFileContent);
    } else {
      _config = {};
    }
  }

  Future<void> writeConfig() async {
    final configFile = File(configFilePath);
    await configFile.writeAsString(json.encode(_config));
  }

  bool is24HourFormat() {
    String formattedTime =
        DateFormat.jm(PlatformDispatcher.instance.locale.toString())
            .format(DateTime.now());
    // If the output contains text, it's a 12-hour format
    return !formattedTime.contains(RegExp(r'[A-Za-z]'));
  }

  int getFirstDayOfWeekIndex() {
    final startingDay = get("startingDayOfWeek");
    if (startingDay == 'system') {
      return DateFormat.yMd(
              WidgetsBinding.instance.platformDispatcher.locale.toString())
          .dateSymbols
          .FIRSTDAYOFWEEK;
    } else {
      return TimeManager.dayOfWeekIndexMapping.keys.firstWhere(
          (k) => TimeManager.dayOfWeekIndexMapping[k] == startingDay);
    }
  }
}
