import 'dart:io';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:daily_you/config_provider.dart';
import 'package:daily_you/entries_database.dart';
import 'package:daily_you/notification_manager.dart';
import 'package:daily_you/stats_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/layouts/mobile_scaffold.dart';
import 'package:daily_you/layouts/responsive_layout.dart';
import 'package:daily_you/theme_mode_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'config_manager.dart';
import 'package:provider/provider.dart';

@pragma('vm:entry-point')
void callbackDispatcher() async {
  await ConfigManager.instance.init();
  await EntriesDatabase.instance.initDB();
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

    await flutterLocalNotificationsPlugin.show(
        0, 'Log Today!', 'Take your daily log...', platformChannelSpecifics);
  }
  EntriesDatabase.instance.close();
  Duration timeUntilReminder;
  DateTime dayToRemind = TimeManager.startOfNextDay();
  DateTime reminderDateTime = TimeManager.addTimeOfDay(
      dayToRemind, TimeManager.scheduledReminderTime());
  timeUntilReminder = reminderDateTime.difference(DateTime.now());
  await AndroidAlarmManager.oneShot(timeUntilReminder, 0, callbackDispatcher,
      allowWhileIdle: true, exact: true);
}

void main() async {
  if (Platform.isLinux || Platform.isWindows) {
    // Initialize FFI
    sqfliteFfiInit();
  }
  databaseFactory = databaseFactoryFfi;
  WidgetsFlutterBinding.ensureInitialized();

  // Create the config file if it doesn't exist
  await ConfigManager.instance.init();
  await ConfigProvider.instance.updateConfig();

  final themeProvider = ThemeModeProvider();
  await themeProvider.initializeThemeFromConfig();

  //TODO: Notification only supported on android
  if (Platform.isAndroid) {
    await NotificationManager.instance.init();

    await AndroidAlarmManager.initialize();

    if (ConfigManager.instance.getField('dailyReminders')) {
      await NotificationManager.instance.stopDailyReminders();
      await NotificationManager.instance.startScheduledDailyReminders();
    }
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

Future<void> setAlarm() async {
  Duration timeUntilReminder;
  DateTime dayToRemind;
  if (TimeOfDay.now().hour < TimeManager.scheduledReminderTime().hour) {
    dayToRemind = TimeManager.startOfDay(DateTime.now());
  } else if (TimeOfDay.now().hour == TimeManager.scheduledReminderTime().hour &&
      TimeOfDay.now().minute < TimeManager.scheduledReminderTime().minute) {
    dayToRemind = TimeManager.startOfDay(DateTime.now());
  } else {
    dayToRemind = TimeManager.startOfNextDay();
  }
  DateTime reminderDateTime = TimeManager.addTimeOfDay(
      dayToRemind, TimeManager.scheduledReminderTime());
  timeUntilReminder = reminderDateTime.difference(DateTime.now());
  await AndroidAlarmManager.oneShot(timeUntilReminder, 0, callbackDispatcher,
      allowWhileIdle: true, exact: true, rescheduleOnReboot: true);
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  bool canReachDatabase = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkDatabaseConnection();
  }

  Future<void> uriErrorPopup(String folderType) async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: const Text("Error:"),
              content: Text(
                  "Can't access the $folderType folder! Go to settings, backup your logs and images, then reset the your external folder locations!"));
        });
  }

  _checkDatabaseConnection() async {
    //Initialize Database
    canReachDatabase = await EntriesDatabase.instance.initDB();

    setState(() {
      isLoading = false;
    });
  }

  _forceLocalDatabase() async {
    canReachDatabase =
        await EntriesDatabase.instance.initDB(forceWithoutSync: true);
    setState(() {
      canReachDatabase;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeModeProvider = Provider.of<ThemeModeProvider>(context);

    return GestureDetector(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: MaterialApp(
            title: 'Daily You',
            themeMode: themeModeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                  seedColor: themeModeProvider.accentColor,
                  brightness: Brightness.light),
            ),
            darkTheme: (ConfigManager.instance.getField('theme') == 'amoled')
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
            home: isLoading
                ? const SizedBox()
                : canReachDatabase
                    ? const ResponsiveLayout(
                        mobileScaffold: MobileScaffold(),
                        tabletScaffold: MobileScaffold(),
                        desktopScaffold: MobileScaffold(),
                      )
                    : Scaffold(
                        extendBody: true,
                        backgroundColor: themeModeProvider.accentColor,
                        body: Center(
                          child: Card(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Error",
                                  style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: themeModeProvider.accentColor),
                                ),
                                const Text(
                                  "Can't access your external storage location!",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const Padding(
                                  padding: EdgeInsets.all(
                                    32.0,
                                  ),
                                  child: Text(
                                    """
If you are using network storage make sure the service is online and you have network access.

Otherwise, the app may have lost permissions for the external folder. Go to settings, and reselect the external folder to grant access.
          
Warning, changes will not be synced until restore access to the external storage location!""",
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                                TextButton(
                                    onPressed: _forceLocalDatabase,
                                    child: const Text(
                                        "Continue With Local Database")),
                              ],
                            ),
                          ),
                        ))));
  }
}
