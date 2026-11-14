// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/layouts/fast_page_view_scroll_physics.dart';
import 'package:daily_you/layouts/window_size_class.dart';
import 'package:daily_you/pages/settings/notification_settings.dart';
import 'package:daily_you/widgets/settings_dialog.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';
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
  static const int _galleryPageIndex = 1;

  int currentIndex = 0;
  final _swipePagesKey = GlobalKey<_SwipePagesState>();
  final List<bool> _isScrolled = [false, false, false];
  int _prebuildViewports = 0;

  late final List<ScrollController> _scrollControllers;

  final List<Widget> pages = [
    const HomePage(),
    const GalleryPage(),
    const StatsPage(),
  ];

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) => _startPrebuild());
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
    for (final c in _scrollControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _startPrebuild() {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    final animation = route?.animation;
    if (animation == null || (animation.isCompleted && !route!.offstage)) {
      _prebuildNextPage();
      return;
    }
    void onStatus(AnimationStatus status) {
      if (status != AnimationStatus.completed) return;
      animation.removeStatusListener(onStatus);
      SchedulerBinding.instance
          .addPostFrameCallback((_) => _prebuildNextPage());
    }

    animation.addStatusListener(onStatus);
  }

  void _prebuildNextPage() {
    if (!mounted) return;
    setState(
        () => _prebuildViewports = (_prebuildViewports + 1) % pages.length);
    if (_prebuildViewports > 0) {
      SchedulerBinding.instance
          .addPostFrameCallback((_) => _prebuildNextPage());
    }
  }

  void _updateScrolledFromController(int pageIndex) {
    final c = _scrollControllers[pageIndex];
    if (!c.hasClients || c.positions.length != 1) return;
    _updateScrolled(pageIndex, c.position.pixels > 0);
  }

  void _updateScrolled(int pageIndex, bool scrolled) {
    if (pageIndex == _galleryPageIndex) return;
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
    final scrollController = _scrollControllers[newIndex];
    if (newIndex != _galleryPageIndex &&
        scrollController.hasClients &&
        scrollController.positions.length == 1) {
      _isScrolled[newIndex] = scrollController.position.pixels > 0;
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
    showSettingsDialog(
      context: context,
      title: AppLocalizations.of(context)!.settingsNotificationsTitle,
      actions: (context) => [
        TextButton(
          onPressed: () async {
            await ConfigProvider.instance
                .set(Settings.dismissedNotificationOnboarding, true);
            if (context.mounted) Navigator.of(context).pop();
          },
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.settingsDailyReminderOnboarding),
                const SizedBox(height: 8),
                Text(l10n.settingsNotificationsPermissionsPrompt),
              ],
            ),
          ),
          const Divider(),
          ...NotificationSettings.buildCoreReminderSettings(context),
          const Divider(),
          ...NotificationSettings.buildOnThisDaySettings(context),
        ];
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
        !configProvider.get(Settings.dailyReminders) &&
        !configProvider.get(Settings.onThisDayNotifications) &&
        !configProvider.get(Settings.dismissedNotificationOnboarding);
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
          scrolledUnderElevation: currentIndex == _galleryPageIndex ? 0 : 1,
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
        body: _SwipePages(
          key: _swipePagesKey,
          initialIndex: currentIndex,
          currentIndex: currentIndex,
          prebuildViewports: _prebuildViewports,
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
            _swipePagesKey.currentState?.animateTo(index);
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

    return switch (WindowSizeClass.of(context)) {
      WindowSizeClass.expanded =>
        _buildDesktopLayout(context, configProvider, pageTitles, l10n),
      WindowSizeClass.medium =>
        _buildTabletLayout(context, configProvider, pageTitles, l10n),
      WindowSizeClass.compact =>
        _buildMobileLayout(context, configProvider, pageTitles, l10n),
    };
  }
}

class _SwipePages extends StatefulWidget {
  final int initialIndex;
  final int currentIndex;
  final int prebuildViewports;
  final ValueChanged<int> onPageChanged;
  final List<Widget> children;

  const _SwipePages({
    super.key,
    required this.initialIndex,
    required this.currentIndex,
    required this.prebuildViewports,
    required this.onPageChanged,
    required this.children,
  });

  @override
  State<_SwipePages> createState() => _SwipePagesState();
}

class _SwipePagesState extends State<_SwipePages> {
  late final PageController _pageController =
      PageController(initialPage: widget.initialIndex);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void animateTo(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      physics: const FastPageViewScrollPhysics(),
      allowImplicitScrolling: widget.prebuildViewports > 0,
      scrollCacheExtent:
          ScrollCacheExtent.viewport(widget.prebuildViewports.toDouble()),
      onPageChanged: widget.onPageChanged,
      children: [
        for (final (index, child) in widget.children.indexed)
          TickerMode(enabled: index == widget.currentIndex, child: child),
      ],
    );
  }
}
