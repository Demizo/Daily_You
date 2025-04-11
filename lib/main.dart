import 'dart:io';
import 'dart:math';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:daily_you/config_provider.dart';
import 'package:daily_you/entries_database.dart';
import 'package:daily_you/notification_manager.dart';
import 'package:daily_you/pages/launch_page.dart';
import 'package:daily_you/stats_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:daily_you/layouts/mobile_scaffold.dart';
import 'package:daily_you/layouts/responsive_layout.dart';
import 'package:daily_you/theme_mode_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:time_range_picker/time_range_picker.dart';
import 'package:provider/provider.dart';

@pragma('vm:entry-point')
void callbackDispatcher() async {
  await ConfigProvider.instance.init();
  // Skip syncing for the alarm background task
  await EntriesDatabase.instance.initDB(forceWithoutSync: true);
  if (await EntriesDatabase.instance.getEntryForDate(DateTime.now()) == null) {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin.initialize(
        const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_reminder_icon'),
            linux:
                LinuxInitializationSettings(defaultActionName: 'Log Today')));

    var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
      'daily_you_reminder',
      'Log Reminder',
      icon: '@mipmap/ic_reminder_icon',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    // Localized notification text is stored in SharedPreferences upon startup
    var prefs = await SharedPreferences.getInstance();
    var title = prefs.getString('dailyReminderTitle');
    var description = prefs.getString('dailyReminderDescription');

    if (title != null && description != null) {
      await flutterLocalNotificationsPlugin.show(
          0, title, description, platformChannelSpecifics);
    }
  }
  EntriesDatabase.instance.close();
  setAlarm(firstSet: false);
}

void main() async {
  if (Platform.isLinux || Platform.isWindows) {
    // Initialize FFI
    sqfliteFfiInit();
  }
  databaseFactory = databaseFactoryFfi;
  WidgetsFlutterBinding.ensureInitialized();

  // Create the config file if it doesn't exist
  await ConfigProvider.instance.init();

  final themeProvider = ThemeModeProvider();
  await themeProvider.initializeThemeFromConfig();

  // Notification only supported on android
  if (Platform.isAndroid) {
    await NotificationManager.instance.init();

    await AndroidAlarmManager.initialize();
  }

  runApp(MultiProvider(providers: [
    ChangeNotifierProvider<ThemeModeProvider>(
      create: (_) => themeProvider,
    ),
    ChangeNotifierProvider<StatsProvider>(
      create: (_) => StatsProvider.instance,
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
  if (ConfigProvider.instance.get(ConfigKey.setReminderTime)) {
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

  await AndroidAlarmManager.oneShotAt(reminderDateTime, 0, callbackDispatcher,
      allowWhileIdle: true, exact: true, rescheduleOnReboot: true);
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final themeModeProvider = Provider.of<ThemeModeProvider>(context);

    return GestureDetector(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: MaterialApp(
            onGenerateTitle: (context) =>
                AppLocalizations.of(context)!.appTitle,
            title: 'Daily You',
            themeMode: themeModeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: [
              Locale("en"),
              ...AppLocalizations.supportedLocales
                  .where((locale) => locale.languageCode != "en")
            ],
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                  seedColor: themeModeProvider.accentColor,
                  brightness: Brightness.light),
            ),
            darkTheme:
                (ConfigProvider.instance.get(ConfigKey.theme) == 'amoled')
                    ? ThemeData(
                        useMaterial3: true,
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
                        scaffoldBackgroundColor: Colors.black)
                    : ThemeData(
                        useMaterial3: true,
                        colorScheme: ColorScheme.fromSeed(
                            seedColor: themeModeProvider.accentColor,
                            brightness: Brightness.dark),
                      ),
            home: LaunchPage(
                nextPage: ResponsiveLayout(
              mobileScaffold: MobileScaffold(),
              tabletScaffold: MobileScaffold(),
              desktopScaffold: MobileScaffold(),
            ))));
  }
}
