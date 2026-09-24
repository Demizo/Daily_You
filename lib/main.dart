import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:daily_you/config_provider.dart';
import 'package:daily_you/custom_locale_delegates.dart';
import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/device_info_service.dart';
import 'package:daily_you/flashback_manager.dart';
import 'package:daily_you/notification_manager.dart';
import 'package:daily_you/pages/launch_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/providers/templates_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/utils/auto_backup_schedule.dart';
import 'package:daily_you/utils/backup_restore_utils.dart';
import 'package:daily_you/utils/logging.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/layouts/mobile_scaffold.dart';
import 'package:daily_you/layouts/responsive_layout.dart';
import 'package:daily_you/theme_mode_provider.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:statsfl/statsfl.dart';
import 'package:time_range_picker/time_range_picker.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';

const String _autoBackupPeriodicWorkName = 'auto_backup_periodic';
const String _autoBackupCatchupWorkName = 'auto_backup_catchup';
const String _autoBackupPeriodicTaskName = 'autoBackupPeriodic';
const String _autoBackupCatchupTaskName = 'autoBackupCatchup';
const String _autoBackupRetryAttemptPrefsKey = 'autoBackupRetryAttempt';

// Max backup retry attempts
const int _autoBackupMaxAttempts = 3;

// Lets onTaskStopped wait for the running task's cleanup to actually finish
Completer<void>? _autoBackupCleanupComplete;

@pragma('vm:entry-point')
void autoBackupCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    configureLogging();
    await ConfigProvider.instance.init();

    _autoBackupCleanupComplete = Completer<void>();
    try {
      if (!ConfigProvider.instance.get(Settings.autoBackupEnabled)) {
        return true;
      }
      await NotificationManager.instance.init();
      return await _runAutoBackupWithBoundedRetry();
    } finally {
      if (!_autoBackupCleanupComplete!.isCompleted) {
        _autoBackupCleanupComplete!.complete();
      }
    }
  }, onTaskStopped: (taskName, stopReason) async {
    // Any system-initiated stop, not just a notification tap.
    await NotificationManager.instance.requestBackupCancel();
    await _autoBackupCleanupComplete?.future
        .timeout(const Duration(seconds: 10), onTimeout: () {});
  });
}

Future<bool> _runAutoBackupWithBoundedRetry() async {
  final prefs = await SharedPreferences.getInstance();
  final outcome = await BackupRestoreUtils.runAutoBackupAndNotify();

  if (outcome != AutoBackupOutcome.failed) {
    await prefs.remove(_autoBackupRetryAttemptPrefsKey);
    return true;
  }

  final attempt = (prefs.getInt(_autoBackupRetryAttemptPrefsKey) ?? 0) + 1;
  if (attempt >= _autoBackupMaxAttempts) {
    await prefs.remove(_autoBackupRetryAttemptPrefsKey);
    return true;
  }
  await prefs.setInt(_autoBackupRetryAttemptPrefsKey, attempt);
  return false;
}

@pragma('vm:entry-point')
void onThisDayCallbackDispatcher() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureLogging();
  await ConfigProvider.instance.init();
  // Skip syncing and migration for the alarm background task
  final ready = await AppDatabase.instance
      .init(forceWithoutSync: true, allowMigration: false);

  if (ready) {
    final now = DateTime.now();
    final isJalali = TimeManager.isJalaliCalendarFromPlatform();
    final hasOnThisDayEntries = EntriesProvider.instance.entries.any((e) =>
        TimeManager.isSameCalendarDayOfYear(e.timeCreate, now, isJalali) &&
        TimeManager.calendarYearOf(e.timeCreate, isJalali) !=
            TimeManager.calendarYearOf(now, isJalali));

    if (hasOnThisDayEntries) {
      FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();
      await flutterLocalNotificationsPlugin.initialize(
          settings: const InitializationSettings(
              android:
                  AndroidInitializationSettings('@drawable/ic_notification'),
              linux: LinuxInitializationSettings(
                  defaultActionName: 'On This Day')));

      // Localized notification text is stored in SharedPreferences upon startup
      var prefs = await SharedPreferences.getInstance();
      var title = prefs.getString('onThisDayNotificationTitle');
      var description = prefs.getString('onThisDayNotificationDescription');

      var androidDetails = AndroidNotificationDetails(
        'daily_you_on_this_day',
        title ?? 'On This Day',
        icon: '@drawable/ic_notification',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );

      if (title != null && description != null) {
        await flutterLocalNotificationsPlugin.show(
            id: 1,
            title: title,
            body: description,
            notificationDetails: NotificationDetails(android: androidDetails),
            payload: DateTime.now().toIso8601String());
      }
    }

    AppDatabase.instance.close();
  }

  setOnThisDayAlarm(firstSet: false);
}

@pragma('vm:entry-point')
void callbackDispatcher() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureLogging();
  await ConfigProvider.instance.init();
  // Skip syncing and migration for the alarm background task
  final ready = await AppDatabase.instance
      .init(forceWithoutSync: true, allowMigration: false);

  if (ready) {
    if (EntriesProvider.instance.getEntryForDate(DateTime.now()) == null ||
        ConfigProvider.instance.get(Settings.alwaysRemind)) {
      FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      await flutterLocalNotificationsPlugin.initialize(
          settings: const InitializationSettings(
              android:
                  AndroidInitializationSettings('@drawable/ic_notification'),
              linux:
                  LinuxInitializationSettings(defaultActionName: 'Log Today')));

      // Localized notification text is stored in SharedPreferences upon startup
      var prefs = await SharedPreferences.getInstance();
      var title = prefs.getString('dailyReminderTitle');
      var description = prefs.getString('dailyReminderDescription');

      var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'daily_you_reminder',
        title ?? "Log Today!",
        icon: '@drawable/ic_notification',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );

      var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      if (title != null && description != null) {
        await flutterLocalNotificationsPlugin.show(
            id: 0,
            title: title,
            body: description,
            notificationDetails: platformChannelSpecifics,
            payload: DateTime.now().toIso8601String());
      }
    }
    AppDatabase.instance.close();
  }

  setAlarm(firstSet: false);
}

void main() async {
  if (Platform.isLinux || Platform.isWindows) {
    // Initialize FFI
    sqfliteFfiInit();
  }
  databaseFactory = databaseFactoryFfi;
  WidgetsFlutterBinding.ensureInitialized();

  configureLogging();

  // Create the config file if it doesn't exist
  await ConfigProvider.instance.init();

  // Load any cached flashbacks
  await FlashbackManager.init();

  final themeProvider = ThemeModeProvider();
  await themeProvider.initializeThemeFromConfig();

  // Get current device info
  await DeviceInfoService().init();

  // Notification only supported on android
  if (Platform.isAndroid) {
    await FlutterDisplayMode.setHighRefreshRate();
    await NotificationManager.instance.init();

    await AndroidAlarmManager.initialize();
    await Workmanager().initialize(autoBackupCallbackDispatcher);
    await armAutoBackupWork();
  }

  runApp(MultiProvider(providers: [
    ChangeNotifierProvider<ThemeModeProvider>(
      create: (_) => themeProvider,
    ),
    ChangeNotifierProvider<EntriesProvider>(
      create: (_) => EntriesProvider.instance,
    ),
    ChangeNotifierProvider<EntryImagesProvider>(
      create: (_) => EntryImagesProvider.instance,
    ),
    ChangeNotifierProvider<TemplatesProvider>(
      create: (_) => TemplatesProvider.instance,
    ),
    ChangeNotifierProvider<TagsProvider>(
      create: (_) => TagsProvider.instance,
    ),
    ChangeNotifierProvider<ConfigProvider>(
      create: (_) => ConfigProvider.instance,
    )
  ], builder: (context, child) => const MainApp()));
}

Future<void> setAlarm({bool firstSet = false}) async {
  DateTime referenceTime = TimeManager.startOfDay(DateTime.now());
  Duration currentTime = DateTime.now().difference(referenceTime);

  Duration reminderTime;
  if (ConfigProvider.instance.get(Settings.setReminderTime)) {
    reminderTime = TimeManager.addTimeOfDay(
            referenceTime, TimeManager.scheduledReminderTime())
        .difference(referenceTime);
    if (!firstSet || reminderTime <= currentTime) {
      reminderTime += Duration(days: 1);
    }
  } else {
    final random = Random();
    TimeRange timeRange = TimeManager.getReminderTimeRange();

    Duration startTime =
        TimeManager.addTimeOfDay(referenceTime, timeRange.startTime)
            .difference(referenceTime);
    Duration endTime =
        TimeManager.addTimeOfDay(referenceTime, timeRange.endTime)
            .difference(referenceTime);

    if (endTime < startTime) {
      // Extend end time to next day
      endTime += Duration(days: 1);
    }

    // Make alarm today if possible
    if (firstSet && (startTime < currentTime) && (endTime > currentTime)) {
      startTime = currentTime;
    }

    int randomTimeInMinutes =
        random.nextInt(endTime.inMinutes - startTime.inMinutes + 1);
    reminderTime = startTime + Duration(minutes: randomTimeInMinutes);

    if (!firstSet || (reminderTime <= currentTime)) {
      reminderTime += Duration(days: 1);
    }
  }

  DateTime reminderDateTime = DateTime.now().add(reminderTime - currentTime);

  bool exact = await NotificationManager.instance.canScheduleExactAlarms();
  await AndroidAlarmManager.oneShotAt(reminderDateTime, 0, callbackDispatcher,
      allowWhileIdle: true, exact: exact, rescheduleOnReboot: true);
}

Future<void> setOnThisDayAlarm({bool firstSet = false}) async {
  DateTime referenceTime = TimeManager.startOfDay(DateTime.now());
  Duration currentTime = DateTime.now().difference(referenceTime);

  int hour = ConfigProvider.instance.get(Settings.onThisDayNotificationHour);
  int minute =
      ConfigProvider.instance.get(Settings.onThisDayNotificationMinute);
  Duration reminderTime = TimeManager.addTimeOfDay(
          referenceTime, TimeOfDay(hour: hour, minute: minute))
      .difference(referenceTime);

  if (!firstSet || reminderTime <= currentTime) {
    reminderTime += const Duration(days: 1);
  }

  DateTime reminderDateTime = DateTime.now().add(reminderTime - currentTime);
  bool exact = await NotificationManager.instance.canScheduleExactAlarms();
  await AndroidAlarmManager.oneShotAt(
      reminderDateTime, 1, onThisDayCallbackDispatcher,
      allowWhileIdle: true, exact: exact, rescheduleOnReboot: true);
}

// Safe to call repeatedly: ExistingPeriodicWorkPolicy.update updates a
// pending request in place rather than resetting it.
Future<void> armAutoBackupWork() async {
  if (!ConfigProvider.instance.get(Settings.autoBackupEnabled)) {
    await Workmanager().cancelByUniqueName(_autoBackupPeriodicWorkName);
    return;
  }

  final interval = AutoBackupInterval.fromKey(
      ConfigProvider.instance.get(Settings.autoBackupInterval));
  final requireCharging =
      ConfigProvider.instance.get(Settings.autoBackupRequireCharging);

  await Workmanager().registerPeriodicTask(
    _autoBackupPeriodicWorkName,
    _autoBackupPeriodicTaskName,
    frequency: interval.duration,
    existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    constraints: Constraints(
      requiresDeviceIdle: true,
      requiresCharging: requireCharging,
    ),
    foregroundServiceConfig: await _autoBackupForegroundServiceConfig(),
  );
}

// Kept under its own unique name with ExistingWorkPolicy.keep, so reopening
// the app while a catch-up is already queued doesn't register a duplicate.
// Skips entirely if the periodic work is already running.
Future<void> enqueueAutoBackupCatchup() async {
  if (await isAutoBackupPeriodicRunning()) return;

  await Workmanager().registerOneOffTask(
    _autoBackupCatchupWorkName,
    _autoBackupCatchupTaskName,
    existingWorkPolicy: ExistingWorkPolicy.keep,
    foregroundServiceConfig: await _autoBackupForegroundServiceConfig(),
  );
}

Future<bool> isAutoBackupPeriodicRunning() async {
  final workInfo = await Workmanager().getWorkInfo(_autoBackupPeriodicWorkName);
  return workInfo?.state == WorkState.running;
}

Future<ForegroundServiceConfig> _autoBackupForegroundServiceConfig() async {
  final prefs = await SharedPreferences.getInstance();
  return ForegroundServiceConfig(
    notificationId: backupNotificationId,
    notificationChannelId: backupNotificationChannelId,
    notificationChannelName: backupNotificationChannelId,
    notificationTitle: prefs
        .getString('creatingBackupStatusTemplate')
        ?.replaceFirst('{percent}', '0'),
    foregroundServiceType: ForegroundServiceType.dataSync,
  );
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  Widget build(BuildContext context) {
    final themeModeProvider = Provider.of<ThemeModeProvider>(context);
    final configProvider = Provider.of<ConfigProvider>(context);
    return DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
      ThemeData lightTheme;
      ThemeData darkTheme;

      if (themeModeProvider.usingSystemColor && lightDynamic != null) {
        // FIX: Surface colors are not correct with the dynamic theme, see https://github.com/material-foundation/flutter-packages/issues/574
        // Use dynamic theme for seed color but do not inject chroma
        bool noChroma = (lightDynamic.primary.r == lightDynamic.primary.b) &&
            (lightDynamic.primary.b == lightDynamic.primary.g);
        lightTheme = ThemeData(
            useMaterial3: true,
            materialTapTargetSize: MaterialTapTargetSize.padded,
            colorScheme: ColorScheme.fromSeed(
                seedColor: lightDynamic.primary,
                primaryContainer: lightDynamic.primaryContainer,
                dynamicSchemeVariant: noChroma
                    ? DynamicSchemeVariant.fidelity
                    : DynamicSchemeVariant.tonalSpot,
                brightness: Brightness.light));
      } else {
        lightTheme = ThemeData(
            useMaterial3: true,
            materialTapTargetSize: MaterialTapTargetSize.padded,
            colorScheme: ColorScheme.fromSeed(
                seedColor: themeModeProvider.accentColor,
                brightness: Brightness.light));
      }

      if (themeModeProvider.usingSystemColor && darkDynamic != null) {
        // FIX: Surface colors are not correct with the dynamic theme, see https://github.com/material-foundation/flutter-packages/issues/574
        // Use dynamic theme for seed color but do not inject chroma
        bool noChroma = (darkDynamic.primary.r == darkDynamic.primary.b) &&
            (darkDynamic.primary.b == darkDynamic.primary.g);
        darkTheme = ThemeData(
            useMaterial3: true,
            materialTapTargetSize: MaterialTapTargetSize.padded,
            colorScheme: ColorScheme.fromSeed(
                seedColor: darkDynamic.primary,
                primaryContainer: darkDynamic.primaryContainer,
                dynamicSchemeVariant: noChroma
                    ? DynamicSchemeVariant.fidelity
                    : DynamicSchemeVariant.tonalSpot,
                brightness: Brightness.dark));
      } else {
        darkTheme = ThemeData(
          useMaterial3: true,
          materialTapTargetSize: MaterialTapTargetSize.padded,
          colorScheme: ColorScheme.fromSeed(
              seedColor: themeModeProvider.accentColor,
              brightness: Brightness.dark),
        );
      }

      // amoled override
      if (ConfigProvider.instance.get(Settings.theme) == 'amoled') {
        darkTheme = ThemeData(
            useMaterial3: true,
            materialTapTargetSize: MaterialTapTargetSize.padded,
            colorScheme: ColorScheme.fromSeed(
              seedColor: themeModeProvider.accentColor,
              brightness: Brightness.dark,
              surfaceContainerLowest: Colors.black,
              surfaceContainerLow: Colors.black,
              surfaceContainerHighest: Colors.black,
              surfaceContainerHigh: Colors.black,
              surfaceBright: Colors.black,
              surfaceDim: Colors.black,
              surface: Colors.black,
              surfaceContainer: Colors.black,
              onSurface: Colors.white,
              surfaceTint: Colors.black,
              primaryContainer: Colors.black,
              secondaryContainer: Colors.black,
              tertiaryContainer: Colors.black,
              inverseSurface: Colors.black,
              inversePrimary: Colors.black,
              scrim: Colors.black,
            ),
            scaffoldBackgroundColor: Colors.black);
      }

      return StatsFl(
        isEnabled: false,
        child: GestureDetector(
            onTap: Platform.isAndroid
                ? () => FocusManager.instance.primaryFocus
                    ?.unfocus(disposition: UnfocusDisposition.scope)
                : null,
            child: MaterialApp(
                onGenerateTitle: (context) =>
                    AppLocalizations.of(context)!.appTitle,
                title: 'Daily You',
                themeMode: themeModeProvider.themeMode,
                debugShowCheckedModeBanner: false,
                localizationsDelegates: <LocalizationsDelegate<dynamic>>[
                  AppLocalizations.delegate,
                  CustomMaterialLocalizationsDelegate(),
                  CustomCupertinoLocalizationsDelegate(),
                  CustomWidgetsLocalizationsDelegate(),
                ],
                locale: configProvider.getOverrideLanguage(),
                supportedLocales: [
                  Locale("en"),
                  ...AppLocalizations.supportedLocales
                      .where((locale) => locale.languageCode != "en")
                ],
                localeResolutionCallback: (locale, supportedLocales) {
                  final override = configProvider.getOverrideLanguage();
                  if (override != null) return override;

                  if (locale != null) {
                    for (final supported in supportedLocales) {
                      if (supported.languageCode == locale.languageCode) {
                        return supported;
                      }
                    }
                  }

                  return const Locale('en');
                },
                theme: lightTheme,
                darkTheme: darkTheme,
                home: LaunchPage(
                    nextPage: ResponsiveLayout(
                  mobileScaffold: MobileScaffold(),
                  tabletScaffold: MobileScaffold(),
                  desktopScaffold: MobileScaffold(),
                )))),
      );
    });
  }
}
