import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:daily_you/language_option.dart';
import 'package:daily_you/storage/secret_store.dart';
import 'package:daily_you/time_manager.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Setting<T> {
  const Setting(this.key, this.defaultValue,
      {this.secure = false, this.secretStore = false});

  final String key;
  final T defaultValue;
  final bool secure;
  final bool secretStore;
}

class Settings {
  static const configVersion = Setting<String>("configVersion", "2");
  static const theme = Setting<String>("theme", "system");
  static const useExternalDb = Setting<bool>("useExternalDb", false);
  static const externalDbUri = Setting<String>("externalDbUri", "");
  static const useExternalImg = Setting<bool>("useExternalImg", false);
  static const externalImgUri = Setting<String>("externalImgUri", "");
  static const startingDayOfWeek =
      Setting<String>("startingDayOfWeek", "system");
  static const galleryPageViewMode =
      Setting<String>("galleryPageViewMode", "grid");
  static const veryHappyIcon = Setting<String>("veryHappyIcon", "☺️");
  static const happyIcon = Setting<String>("happyIcon", "🙂");
  static const neutralIcon = Setting<String>("neutralIcon", "😐");
  static const sadIcon = Setting<String>("sadIcon", "😕");
  static const verySadIcon = Setting<String>("verySadIcon", "😔");
  static const followSystemColor = Setting<bool>("followSystemColor", true);
  static const accentColor = Setting<int>("accentColor", 0xff62A0EA);
  static const dailyReminders = Setting<bool>("dailyReminders", false);
  static const setReminderTime = Setting<bool>("setReminderTime", false);
  static const scheduledReminderHour =
      Setting<int>("scheduledReminderHour", 12);
  static const scheduledReminderMinute =
      Setting<int>("scheduledReminderMinute", 0);
  static const reminderStartHour = Setting<int>("reminderStartHour", 9);
  static const reminderStartMinute = Setting<int>("reminderStartMinute", 0);
  static const reminderEndHour = Setting<int>("reminderEndHour", 21);
  static const reminderEndMinute = Setting<int>("reminderEndMinute", 0);
  static const alwaysRemind = Setting<bool>("alwaysRemind", false);
  static const onThisDayNotifications =
      Setting<bool>("onThisDayNotifications", false);
  static const onThisDayNotificationHour =
      Setting<int>("onThisDayNotificationHour", 12);
  static const onThisDayNotificationMinute =
      Setting<int>("onThisDayNotificationMinute", 0);
  static const dismissedNotificationOnboarding =
      Setting<bool>("dismissedNotificationOnboarding", false);
  static const defaultTemplate = Setting<int>("defaultTemplate", -1);
  static const imageQualityLevel =
      Setting<String>("imageQualityLevel", ImageQuality.medium);
  static const overrideLanguage =
      Setting<Map<String, dynamic>?>("overrideLanguage", null);
  static const showFlashbacks = Setting<bool>("showFlashbacks", true);
  static const excludeBadDaysFromFlashbacks =
      Setting<bool>("excludeBadDaysFromFlashbacks", false);
  static const showflashbackYearsAgo =
      Setting<bool>("showflashbackYearsAgo", true);
  static const showflashback6MonthsAgo =
      Setting<bool>("showflashback6MonthsAgo", true);
  static const showflashback1MonthAgo =
      Setting<bool>("showflashback1MonthAgo", true);
  static const showflashback1WeekAgo =
      Setting<bool>("showflashback1WeekAgo", true);
  static const showflashbackGoodDay =
      Setting<bool>("showflashbackGoodDay", true);
  static const showflashbackRandomDay =
      Setting<bool>("showflashbackRandomDay", true);
  static const hideImagesInGallery =
      Setting<bool>("hideImagesInGallery", false);
  static const hideImagesInCalendar =
      Setting<bool>("hideImagesInCalendar", false);
  static const hideImagesInFlashbacks =
      Setting<bool>("hideImagesInFlashbacks", false);
  static const lastDismissedSupportBannerDate =
      Setting<String?>("lastDismissedSupportBannerDate", null);
  static const calendarShowMood = Setting<bool>("calendarShowMood", true);
  static const calendarTagOverlay = Setting<int?>("calendarTagOverlay", null);
  static const calendarSystem = Setting<String>("calendarSystem", "system");
  static const moodOverTimeGrouping =
      Setting<String?>("moodOverTimeGrouping", null);
  static const moodOverTimeSmoothing =
      Setting<bool>("moodOverTimeSmoothing", true);
  static const statsRange = Setting<String>("statsRange", "allTime");
  static const statsSubject = Setting<String>("statsSubject", "mood");
  static const tagPickerSortMode =
      Setting<String>("tagPickerSortMode", "manual");
  static const requirePassword =
      Setting<bool>("requirePassword", false, secure: true);
  static const biometricUnlock =
      Setting<bool>("biometricUnlock", false, secure: true);
  static const passwordHash =
      Setting<String>("passwordHash", "", secure: true, secretStore: true);
  static const passwordIsPin =
      Setting<bool>("passwordIsPin", false, secure: true);
  static const backupPasswordEnabled =
      Setting<bool>("backupPasswordEnabled", false, secure: true);
  static const backupPassword =
      Setting<String>("backupPassword", "", secure: true, secretStore: true);
  static const autoBackupEnabled = Setting<bool>("autoBackupEnabled", false);
  static const autoBackupLocationUri =
      Setting<String>("autoBackupLocationUri", "");
  static const autoBackupInterval =
      Setting<String>("autoBackupInterval", "daily");
  static const autoBackupHour = Setting<int>("autoBackupHour", 2);
  static const autoBackupMinute = Setting<int>("autoBackupMinute", 0);
  static const autoBackupMaxCount = Setting<int>("autoBackupMaxCount", 5);
  static const lastBackup = Setting<String>("lastBackup", "", secure: true);
  static const lastAutoBackup =
      Setting<String>("lastAutoBackup", "", secure: true);

  static const List<Setting<Object?>> all = [
    configVersion,
    theme,
    useExternalDb,
    externalDbUri,
    useExternalImg,
    externalImgUri,
    startingDayOfWeek,
    galleryPageViewMode,
    veryHappyIcon,
    happyIcon,
    neutralIcon,
    sadIcon,
    verySadIcon,
    followSystemColor,
    accentColor,
    dailyReminders,
    setReminderTime,
    scheduledReminderHour,
    scheduledReminderMinute,
    reminderStartHour,
    reminderStartMinute,
    reminderEndHour,
    reminderEndMinute,
    alwaysRemind,
    onThisDayNotifications,
    onThisDayNotificationHour,
    onThisDayNotificationMinute,
    dismissedNotificationOnboarding,
    defaultTemplate,
    imageQualityLevel,
    overrideLanguage,
    showFlashbacks,
    excludeBadDaysFromFlashbacks,
    showflashbackYearsAgo,
    showflashback6MonthsAgo,
    showflashback1MonthAgo,
    showflashback1WeekAgo,
    showflashbackGoodDay,
    showflashbackRandomDay,
    hideImagesInGallery,
    hideImagesInCalendar,
    hideImagesInFlashbacks,
    lastDismissedSupportBannerDate,
    calendarShowMood,
    calendarTagOverlay,
    calendarSystem,
    moodOverTimeGrouping,
    moodOverTimeSmoothing,
    statsRange,
    statsSubject,
    tagPickerSortMode,
    requirePassword,
    biometricUnlock,
    passwordHash,
    passwordIsPin,
    backupPasswordEnabled,
    backupPassword,
    autoBackupEnabled,
    autoBackupLocationUri,
    autoBackupInterval,
    autoBackupHour,
    autoBackupMinute,
    autoBackupMaxCount,
    lastBackup,
    lastAutoBackup,
  ];

  static const moodIcons = <int, Setting<String>>{
    2: veryHappyIcon,
    1: happyIcon,
    0: neutralIcon,
    -1: sadIcon,
    -2: verySadIcon,
  };
}

class ImageQuality {
  static const String noCompression = "noCompression";
  static const String high = "high";
  static const String medium = "medium";
  static const String low = "low";
}

class ConfigProvider with ChangeNotifier {
  static final ConfigProvider instance = ConfigProvider._init();

  ConfigProvider._init();

  final Logger _logger = Logger('ConfigProvider');

  String configFilePath = '';

  Map<String, dynamic> _config = {};

  static final Set<String> _secureKeys = {
    for (final setting in Settings.all)
      if (setting.secure) setting.key,
  };

  static final imageQualityCompressionMapping = {
    ImageQuality.noCompression: 100,
    ImageQuality.high: 90,
    ImageQuality.medium: 80,
    ImageQuality.low: 75,
  };

  static final imageQualityMaxSizeMapping = {
    ImageQuality.noCompression: null,
    ImageQuality.high: 2100.0,
    ImageQuality.medium: 1600.0,
    ImageQuality.low: 1024.0,
  };

  T get<T>(Setting<T> setting) {
    final value = _config[setting.key];
    return value is T ? value : setting.defaultValue;
  }

  Future<void> set<T>(Setting<T> setting, T value) async {
    _config[setting.key] = value;
    notifyListeners();

    if (setting.secretStore) {
      await SecretStore.instance.write(setting.key, json.encode(value));
    } else if (setting.secure) {
      final prefs = await SharedPreferences.getInstance();
      // Store as JSON for type safety
      await prefs.setString(setting.key, json.encode(value));
    } else {
      await writeConfig();
    }
  }

  Future<void> init() async {
    initializeDateFormatting();

    final dbPath = await getApplicationSupportDirectory();
    if (!dbPath.existsSync()) dbPath.createSync(recursive: true);
    configFilePath = join(dbPath.path, 'config.json');

    if (Platform.isAndroid) {
      await _migrateConfigFromExternalStorage(dbPath);
    }

    await readConfig();
    await loadSecureConfig();
    await migrateSecretToSecretStore(Settings.passwordHash);
    await loadSecretStoreConfig();
    await _pruneUnknownKeys();
  }

  Future<void> _migrateConfigFromExternalStorage(Directory newDir) async {
    final newFile = File(join(newDir.path, 'config.json'));
    if (newFile.existsSync()) return;

    final oldDir = await getExternalStorageDirectory();
    if (oldDir == null) return;
    final oldFile = File(join(oldDir.path, 'config.json'));
    if (!oldFile.existsSync()) return;

    // Never let a migration failure abort startup; settings fall back to
    // defaults via readConfig() if the config can't be moved.
    try {
      _logger
          .info('Config migration started: ${oldFile.path} -> ${newFile.path}');
      await oldFile.copy(newFile.path);
      if (newFile.existsSync() && newFile.lengthSync() > 0) {
        await oldFile.delete();
        _logger.info('Config migration finished successfully');
      } else {
        _logger.severe(
            'Config migration failed: copied file missing or empty, kept original');
      }
    } catch (error, stackTrace) {
      _logger.severe('Config migration failed', error, stackTrace);
    }
  }

  Future<void> _pruneUnknownKeys() async {
    final declaredKeys = {for (final setting in Settings.all) setting.key};
    final unknownKeys =
        _config.keys.where((key) => !declaredKeys.contains(key)).toList();
    if (unknownKeys.isEmpty) return;

    _config.removeWhere((key, _) => unknownKeys.contains(key));
    await writeConfig();
  }

  Future<void> loadSecureConfig() async {
    final prefs = await SharedPreferences.getInstance();
    for (final setting in Settings.all
        .where((setting) => setting.secure && !setting.secretStore)) {
      final stored = prefs.getString(setting.key);
      if (stored == null) {
        _config[setting.key] = setting.defaultValue;
        // Store as JSON for type safety
        await prefs.setString(setting.key, json.encode(setting.defaultValue));
        continue;
      }
      _decodeInto(setting, stored);
    }
  }

  Future<void> loadSecretStoreConfig() async {
    final prefs = await SharedPreferences.getInstance();
    for (final setting
        in Settings.all.where((setting) => setting.secretStore)) {
      final stored =
          await _readSecret(setting.key) ?? prefs.getString(setting.key);
      if (stored == null) {
        _config[setting.key] = setting.defaultValue;
        continue;
      }
      _decodeInto(setting, stored);
    }
  }

  Future<String?> _readSecret(String key) async {
    try {
      return await SecretStore.instance.read(key);
    } catch (error, stackTrace) {
      _logger.warning(
          'Could not read $key from secret storage', error, stackTrace);
      return null;
    }
  }

  void _decodeInto(Setting<Object?> setting, String stored) {
    try {
      _config[setting.key] = json.decode(stored);
    } catch (error, stackTrace) {
      _logger.warning('${setting.key} is not valid JSON, reading it raw', error,
          stackTrace);
      _config[setting.key] = stored;
    }
  }

  Future<void> migrateSecretToSecretStore(Setting<Object?> setting) async {
    final prefs = await SharedPreferences.getInstance();
    if (await _readSecret(setting.key) != null) return;

    final legacyValue = prefs.getString(setting.key);
    if (legacyValue == null) return;

    try {
      await SecretStore.instance.write(setting.key, legacyValue);
      if (await SecretStore.instance.read(setting.key) == legacyValue) {
        await prefs.remove(setting.key);
      } else {
        _logger
            .severe('Secret migration verification failed for ${setting.key}');
      }
    } catch (error, stackTrace) {
      _logger.severe(
          'Secret migration failed for ${setting.key}', error, stackTrace);
    }
  }

  Future<void> readConfig() async {
    final configFile = File(configFilePath);

    if (!await configFile.exists()) {
      _config = {};
      return;
    }

    try {
      final content = await configFile.readAsString();
      final decoded = json.decode(content);

      if (decoded is Map<String, dynamic>) {
        _config = decoded;
      } else {
        throw const FormatException('Config is not a map');
      }
    } catch (error, stackTrace) {
      // Corrupted config: reset to defaults
      _logger.severe('Config could not be read, falling back to defaults',
          error, stackTrace);
      _config = {};
    }
  }

  Future<void> writeConfig() async {
    EasyDebounce.debounce("save-config", Duration(seconds: 1), () async {
      final filteredConfig = Map<String, dynamic>.from(_config)
        ..removeWhere((key, _) => _secureKeys.contains(key));

      final tempFile = File('$configFilePath.tmp');

      final jsonString = json.encode(filteredConfig);

      await tempFile.writeAsString(jsonString, flush: true);
      await tempFile.rename(configFilePath);
    });
  }

  bool is24HourFormat() {
    if (PlatformDispatcher.instance.alwaysUse24HourFormat) return true;
    String formattedTime =
        DateFormat.jm(PlatformDispatcher.instance.locale.toString())
            .format(DateTime.now());
    // If the output contains text, it's a 12-hour format
    return !formattedTime.contains(RegExp(r'[A-Za-z]'));
  }

  int getFirstDayOfWeekIndex(BuildContext context) {
    final startingDay = get(Settings.startingDayOfWeek);
    if (startingDay == 'system') {
      return DateFormat.yMd(TimeManager.currentLocale(context))
          .dateSymbols
          .FIRSTDAYOFWEEK;
    } else {
      return TimeManager.dayOfWeekIndexMapping.keys.firstWhere(
          (k) => TimeManager.dayOfWeekIndexMapping[k] == startingDay);
    }
  }

  Locale? getOverrideLanguage() {
    LanguageOption? currentOverride =
        LanguageOption.fromJsonOrNull(get(Settings.overrideLanguage));
    if (currentOverride != null) {
      return currentOverride.toLocale();
    }
    return null;
  }
}
