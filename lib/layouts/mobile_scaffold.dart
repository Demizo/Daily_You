import 'dart:io';

import 'package:daily_you/config_manager.dart';
import 'package:daily_you/notification_manager.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/pages/calendar_page.dart';
import 'package:daily_you/pages/entries_page.dart';
import 'package:daily_you/pages/home_page.dart';

import '../pages/settings_page.dart';

class MobileScaffold extends StatefulWidget {
  const MobileScaffold({super.key});

  @override
  State<MobileScaffold> createState() => _MobileScaffoldState();
}

class _MobileScaffoldState extends State<MobileScaffold> {
  int currentIndex = 0;
  bool isLoading = false;

  final List<Widget> pages = [
    const HomePage(),
    const CalendarPage(),
    const EntriesPage(),
  ];

  final List<String> appBarsTitles = ["Home", "Calendar", "Gallery"];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: Text(appBarsTitles[currentIndex]), actions: [
        if (Platform.isAndroid)
          IconButton(
            icon: ConfigManager.instance.getField('dailyReminders')
                ? const Icon(Icons.notifications)
                : const Icon(Icons.notifications_off_rounded),
            onPressed: () async {
              if (await NotificationManager.instance
                  .hasNotificationPermission()) {
                var value = !ConfigManager.instance.getField('dailyReminders');
                if (value) {
                  NotificationManager.instance.startScheduledDailyReminders();
                } else {
                  NotificationManager.instance.stopDailyReminders();
                }
                await ConfigManager.instance.setField('dailyReminders', value);
                setState(() {});
              }
            },
          ),
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          onPressed: () async {
            setState(() {
              isLoading = true;
            });
            await Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const SettingsPage(),
            ));
            setState(() {
              isLoading = false;
            });
          },
        )
      ]),
      body: isLoading ? const Center(child: SizedBox()) : pages[currentIndex],
      bottomNavigationBar: NavigationBar(
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_rounded),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_rounded),
            label: 'Gallery',
          ),
        ],
      ),
    );
  }
}
