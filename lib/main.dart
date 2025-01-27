import 'dart:io';
import 'dart:math';

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
import 'package:time_range_picker/time_range_picker.dart';
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
  await ConfigManager.instance.init();
  await ConfigProvider.instance.updateConfig();

  final themeProvider = ThemeModeProvider();
  await themeProvider.initializeThemeFromConfig();

  //TODO: Notification only supported on android
  if (Platform.isAndroid) {
    await NotificationManager.instance.init();

    await AndroidAlarmManager.initialize();
    await NotificationManager.instance.dismissReminderNotification();
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
  DateTime dayToRemind = TimeManager.startOfNextDay();
  if (firstSet) {
    if (ConfigManager.instance.getField('setReminderTime')) {
      if (TimeOfDay.now().hour < TimeManager.scheduledReminderTime().hour) {
        dayToRemind = TimeManager.startOfDay(DateTime.now());
      } else if (TimeOfDay.now().hour ==
              TimeManager.scheduledReminderTime().hour &&
          TimeOfDay.now().minute < TimeManager.scheduledReminderTime().minute) {
        dayToRemind = TimeManager.startOfDay(DateTime.now());
      } else {
        dayToRemind = TimeManager.startOfNextDay();
      }
    } else {
      TimeOfDay endTime = TimeManager.getReminderTimeRange().endTime;
      if ((TimeOfDay.now().hour < endTime.hour) ||
          ((TimeOfDay.now().hour == endTime.hour) &&
              (TimeOfDay.now().minute < endTime.minute))) {
        dayToRemind = TimeManager.startOfDay(DateTime.now());
      }
    }
  }

  DateTime reminderDateTime;
  if (ConfigManager.instance.getField('setReminderTime')) {
    reminderDateTime = TimeManager.addTimeOfDay(
        dayToRemind, TimeManager.scheduledReminderTime());
  } else {
    final random = Random();
    TimeRange timeRange = TimeManager.getReminderTimeRange();
    if (TimeManager.isSameDay(dayToRemind, DateTime.now())) {
      timeRange.startTime = TimeOfDay.now();
    }

    int randomHour =
        (random.nextInt(timeRange.endTime.hour - timeRange.startTime.hour + 1) +
            timeRange.startTime.hour);
    int randomMinute = timeRange.endTime.hour > timeRange.startTime.hour
        ? (random.nextInt(60))
        : (random.nextInt(
                timeRange.endTime.minute - timeRange.startTime.minute + 1) +
            timeRange.startTime.minute);
    TimeOfDay randomTime = TimeOfDay(hour: randomHour, minute: randomMinute);

    reminderDateTime = TimeManager.addTimeOfDay(dayToRemind, randomTime);
  }

  await AndroidAlarmManager.oneShotAt(reminderDateTime, 0, callbackDispatcher,
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
                ? const Scaffold(body: SizedBox())
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
