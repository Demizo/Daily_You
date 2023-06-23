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

  final List<Widget> pages = [
    const HomePage(),
    const CalendarPage(),
    const EntriesPage(),
  ];
  final List<String> appBarsTitles = ["Daily You", "Calendar", "Gallery"];
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(appBarsTitles[currentIndex]), actions: [
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          onPressed: () async {
            await Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const SettingsPage(),
            ));
          },
        )
      ]),
      backgroundColor: theme.canvasColor,
      body: pages[currentIndex],
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
