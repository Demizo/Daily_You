import 'dart:io';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/layouts/fast_page_view_scroll_physics.dart';
import 'package:daily_you/pages/settings/notification_settings.dart';
import 'package:easy_debounce/easy_debounce.dart';
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
  late final PageController _pageController;
  final List<bool> _isScrolled = [false, false, false];

  late final List<ScrollController> _scrollControllers;

  final List<Widget> pages = [
    const HomePage(),
    const GalleryPage(),
    const StatsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: currentIndex);
    _scrollControllers = List.generate(pages.length, (_) => ScrollController());
    for (int i = 0; i < _scrollControllers.length; i++) {
      final pageIndex = i;
      _scrollControllers[i].addListener(() {
        _updateScrolledFromController(pageIndex);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _scrollControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _updateScrolledFromController(int pageIndex) {
    final c = _scrollControllers[pageIndex];
    if (!c.hasClients || c.positions.length != 1) return;
    _updateScrolled(pageIndex, c.position.pixels > 0);
  }

  void _updateScrolled(int pageIndex, bool scrolled) {
    if (_isScrolled[pageIndex] == scrolled) return;
    if (pageIndex == currentIndex) {
      setState(() {
        _isScrolled[pageIndex] = scrolled;
      });
    } else {
      _isScrolled[pageIndex] = scrolled;
    }
  }

  void _switchPage(int newIndex) {
    final c = _scrollControllers[newIndex];
    if (c.hasClients && c.positions.length == 1) {
      _isScrolled[newIndex] = c.position.pixels > 0;
    }
    setState(() {
      currentIndex = newIndex;
    });
  }

  Widget _buildPageStack() {
    return IndexedStack(
      index: currentIndex,
      children: List.generate(pages.length, (i) {
        return PrimaryScrollController(
          controller: _scrollControllers[i],
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.axis != Axis.vertical) {
                return false; // Don't interfere with horizontal scrollables.
              }
              // Home page (index 0) has an internal calendar scroll that should
              // not drive AppBar elevation.
              if (notification.depth == 0 && i != 0) {
                _updateScrolled(i, notification.metrics.pixels > 0);
              }
              return true; // Consume: prevent Scaffold observer interference.
            },
            child: pages[i],
          ),
        );
      }),
    );
  }

  bool _handleMobileScrollNotification(ScrollNotification notification) {
    // Ignore the home page
    if (currentIndex == 0) return false;

    if (notification.metrics.axis != Axis.vertical || notification.depth == 0) {
      return false;
    }
    _updateScrolled(currentIndex, notification.metrics.pixels > 0);
    return false;
  }

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
                if (context.mounted) Navigator.of(context).pop();
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
            const SizedBox(height: 12),
            Text(AppLocalizations.of(context)!.settingsDailyReminderOnboarding),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!
                .settingsNotificationsPermissionsPrompt),
            const Divider(),
            ...NotificationSettings.buildCoreReminderSettings(context),
            const Divider(),
            ...NotificationSettings.buildOnThisDaySettings(context),
          ]),
        );
      },
    );
  }

  Future<void> _navigateToSettings() async {
    await Navigator.of(context).push(MaterialPageRoute(
      allowSnapshotting: false,
      builder: (context) => const SettingsPage(),
    ));
  }

  bool _shouldShowNotificationButton(ConfigProvider configProvider) {
    return Platform.isAndroid &&
        !configProvider.get(ConfigKey.dailyReminders) &&
        !configProvider.get(ConfigKey.onThisDayNotifications) &&
        !configProvider.get(ConfigKey.dismissedNotificationOnboarding);
  }

  Widget _buildNavItem(
    BuildContext context,
    ThemeData theme,
    int index,
    IconData icon,
    String label, {
    VoidCallback? onTap,
  }) {
    final isSelected = currentIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
      child: Material(
        color: isSelected
            ? theme.colorScheme.secondaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap ?? () => _switchPage(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? theme.colorScheme.onSecondaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.onSecondaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n, {
    bool closeDrawer = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () {
            if (closeDrawer) Navigator.of(context).pop();
            _navigateToSettings();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.settings_rounded,
                    color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Text(
                  l10n.pageSettingsTitle,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarContent(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n, {
    bool closeDrawer = false,
  }) {
    return SafeArea(
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
          child: Text(l10n.appTitle, style: theme.textTheme.headlineSmall),
        ),
        _buildNavItem(
          context,
          theme,
          0,
          Icons.home_rounded,
          l10n.pageHomeTitle,
          onTap: closeDrawer
              ? () {
                  Navigator.of(context).pop();
                  _switchPage(0);
                }
              : null,
        ),
        _buildNavItem(
          context,
          theme,
          1,
          Icons.photo_library_rounded,
          l10n.pageGalleryTitle,
          onTap: closeDrawer
              ? () {
                  Navigator.of(context).pop();
                  _switchPage(1);
                }
              : null,
        ),
        _buildNavItem(
          context,
          theme,
          2,
          Icons.auto_graph_rounded,
          l10n.pageStatisticsTitle,
          onTap: closeDrawer
              ? () {
                  Navigator.of(context).pop();
                  _switchPage(2);
                }
              : null,
        ),
        const Spacer(),
        const Divider(indent: 16, endIndent: 16),
        _buildSettingsItem(context, theme, l10n, closeDrawer: closeDrawer),
        const SizedBox(height: 8),
      ],
    ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    ConfigProvider configProvider,
    List<String> pageTitles,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    return NotificationListener<ScrollNotification>(
      onNotification: _handleMobileScrollNotification,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(pageTitles[currentIndex]),
          elevation: _isScrolled[currentIndex] ? 1 : 0,
          scrolledUnderElevation: 1,
          actions: [
            if (_shouldShowNotificationButton(configProvider))
              IconButton(
                icon: const Icon(Icons.notifications_off_rounded),
                onPressed: _showNotificationOnboardingPopup,
              ),
            IconButton(
              icon: const Icon(Icons.settings_rounded),
              onPressed: _navigateToSettings,
            ),
          ],
        ),
        body: PageView(
          controller: _pageController,
          physics: const FastPageViewScrollPhysics(),
          onPageChanged: (index) {
            FocusManager.instance.primaryFocus?.unfocus();
            EasyDebounce.debounce(
                "page-change",
                const Duration(milliseconds: 150),
                () => setState(() {
                      currentIndex = index;
                    }));
          },
          children: pages,
        ),
        bottomNavigationBar: NavigationBar(
          height: 65,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          elevation: 1,
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            EasyDebounce.cancel("page-change");
            setState(() {
              currentIndex = index;
            });
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_rounded),
              label: l10n.pageHomeTitle,
            ),
            NavigationDestination(
              icon: const Icon(Icons.photo_library_rounded),
              label: l10n.pageGalleryTitle,
            ),
            NavigationDestination(
              icon: const Icon(Icons.auto_graph_rounded),
              label: l10n.pageStatisticsTitle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout(
    BuildContext context,
    ConfigProvider configProvider,
    List<String> pageTitles,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(pageTitles[currentIndex]),
        backgroundColor: _isScrolled[currentIndex]
            ? theme.colorScheme.surfaceContainer
            : theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (_shouldShowNotificationButton(configProvider))
            IconButton(
              icon: const Icon(Icons.notifications_off_rounded),
              onPressed: _showNotificationOnboardingPopup,
            ),
        ],
      ),
      drawer: Drawer(
        child: _buildSidebarContent(context, theme, l10n, closeDrawer: true),
      ),
      body: _buildPageStack(),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    ConfigProvider configProvider,
    List<String> pageTitles,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        children: [
          SizedBox(
            width: 304,
            child: Material(
              color: theme.colorScheme.surfaceContainerLow,
              child: _buildSidebarContent(context, theme, l10n),
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            // Consume vertical scroll notifications before they reach the
            // Scaffold's ScrollNotificationObserver. Without this, the AppBar
            // (placed in the body for the desktop layout) would activate its
            // _scrolledUnder state and change the background to surfaceContainer
            // independently of our manual _isScrolled elevation control.
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) => n.metrics.axis == Axis.vertical,
              child: Column(
                children: [
                  AppBar(
                    title: Text(pageTitles[currentIndex]),
                    automaticallyImplyLeading: false,
                    backgroundColor: _isScrolled[currentIndex]
                        ? theme.colorScheme.surfaceContainer
                        : theme.colorScheme.surface,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    actions: [
                      if (_shouldShowNotificationButton(configProvider))
                        IconButton(
                          icon: const Icon(Icons.notifications_off_rounded),
                          onPressed: _showNotificationOnboardingPopup,
                        ),
                    ],
                  ),
                  Expanded(child: _buildPageStack()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<ConfigProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final List<String> pageTitles = [
      l10n.pageHomeTitle,
      l10n.pageGalleryTitle,
      l10n.pageStatisticsTitle,
    ];

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth >= 1100) {
        return _buildDesktopLayout(context, configProvider, pageTitles, l10n);
      } else if (constraints.maxWidth >= 600) {
        return _buildTabletLayout(context, configProvider, pageTitles, l10n);
      } else {
        return _buildMobileLayout(context, configProvider, pageTitles, l10n);
      }
    });
  }
}
