import 'dart:io';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/notification_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:daily_you/pages/statistics_page.dart';
import 'package:daily_you/pages/gallery_page.dart';
import 'package:daily_you/pages/home_page.dart';
import 'package:provider/provider.dart';

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
    const GalleryPage(),
    const StatsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final configProvider = Provider.of<ConfigProvider>(context);
    final List<String> appBarsTitles = [
      AppLocalizations.of(context)!.pageHomeTitle,
      AppLocalizations.of(context)!.pageGalleryTitle,
      AppLocalizations.of(context)!.pageStatisticsTitle
    ];
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: Text(appBarsTitles[currentIndex]), actions: [
        if (Platform.isAndroid)
          IconButton(
            icon: configProvider.get(ConfigKey.dailyReminders)
                ? const Icon(Icons.notifications)
                : const Icon(Icons.notifications_off_rounded),
            onPressed: () async {
              if (await NotificationManager.instance
                  .hasNotificationPermission()) {
                var value = !configProvider.get(ConfigKey.dailyReminders);
                if (value) {
                  NotificationManager.instance.startScheduledDailyReminders();
                } else {
                  NotificationManager.instance.stopDailyReminders();
                }
                await configProvider.set(ConfigKey.dailyReminders, value);
              }
            },
          ),
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          onPressed: () async {
            await Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const SettingsPage(),
            ));
          },
        )
      ]),
      body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          switchInCurve: Curves.easeIn,
          switchOutCurve: Curves.easeOut,
          child: pages[currentIndex]),
      bottomNavigationBar: NavigationBar(
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_rounded),
            label: AppLocalizations.of(context)!.pageHomeTitle,
          ),
          NavigationDestination(
            icon: const Icon(Icons.photo_library_rounded),
            label: AppLocalizations.of(context)!.pageGalleryTitle,
          ),
          NavigationDestination(
            icon: const Icon(Icons.auto_graph_rounded),
            label: AppLocalizations.of(context)!.pageStatisticsTitle,
          ),
        ],
      ),
    );
  }
}
