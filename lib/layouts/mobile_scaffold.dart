import 'dart:io';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/pages/settings/notification_settings.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
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

  void _showNotificationOnboardingPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final configProvider = Provider.of<ConfigProvider>(context);
        return AlertDialog(
          actions: [
            TextButton(
              onPressed: () async {
                await configProvider.set(
                    ConfigKey.dismissedNotificationOnboarding, true);
                Navigator.of(context).pop();
              },
              child: Text(MaterialLocalizations.of(context).closeButtonLabel),
            ),
          ],
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Center(
                child: Icon(
              Icons.notifications_on_rounded,
              color: Theme.of(context).colorScheme.onSurface,
              size: 40,
            )),
            SizedBox(
              height: 12,
            ),
            Text(AppLocalizations.of(context)!.settingsDailyReminderOnboarding),
            SizedBox(
              height: 8,
            ),
            Text(AppLocalizations.of(context)!
                .settingsNotificationsPermissionsPrompt),
            Divider(),
            ...NotificationSettings.buildCoreReminderSettings(context),
          ]),
        );
      },
    );
  }

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
        if (Platform.isAndroid &&
            !configProvider.get(ConfigKey.dailyReminders) &&
            !configProvider.get(ConfigKey.dismissedNotificationOnboarding))
          IconButton(
            icon: const Icon(Icons.notifications_off_rounded),
            onPressed: () async {
              _showNotificationOnboardingPopup();
            },
          ),
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          onPressed: () async {
            await Navigator.of(context).push(MaterialPageRoute(
              allowSnapshotting: false,
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
