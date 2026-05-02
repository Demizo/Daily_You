import 'dart:io';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/device_info_service.dart';
import 'package:daily_you/flashback_manager.dart';
import 'package:daily_you/launch_intent.dart';
import 'package:daily_you/models/flashback.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/notification_manager.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/flashback_card.dart';
import 'package:daily_you/widgets/support_banner.dart';
import 'package:daily_you/widgets/vertical_calendar.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/pages/entries_list_page.dart';
import 'package:daily_you/pages/entry_timeline_page.dart';
import 'package:daily_you/pages/edit_entry_page.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  bool firstLoad = true;
  final ScrollController _scrollController = ScrollController();
  final _fabKey = GlobalKey<ExpandableFabState>();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _checkForLaunchIntent();
    _checkForNotificationLaunch();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _closeFab() {
    final fabState = _fabKey.currentState;
    if (fabState != null && fabState.isOpen) {
      fabState.toggle();
    }
  }

  Future<void> _openWithCamera(Entry? entry, List<EntryImage> images) async {
    _closeFab();
    await Navigator.of(context).push(MaterialPageRoute(
      allowSnapshotting: false,
      builder: (context) =>
          AddEditEntryPage(entry: entry, openCamera: true, images: images),
    ));
  }

  Future<void> _addNewEntryForToday() async {
    _closeFab();
    await Navigator.of(context).push(MaterialPageRoute(
      allowSnapshotting: false,
      builder: (context) =>
          AddEditEntryPage(entry: null, openCamera: false, images: const []),
    ));
  }

  Future<void> _editEntry(Entry entry, List<EntryImage> images) async {
    _closeFab();
    await Navigator.of(context).push(MaterialPageRoute(
      allowSnapshotting: false,
      builder: (context) =>
          AddEditEntryPage(entry: entry, openCamera: false, images: images),
    ));
  }

  Future<void> _addEntryForPickedDay() async {
    _closeFab();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked == null || !mounted) return;
    final overrideDate = TimeManager.isToday(picked)
        ? DateTime.now()
        : TimeManager.currentTimeOnDifferentDate(picked);
    await Navigator.of(context).push(MaterialPageRoute(
      allowSnapshotting: false,
      builder: (context) => AddEditEntryPage(
        entry: null,
        openCamera: false,
        images: const [],
        overrideCreateDate: overrideDate,
      ),
    ));
  }

  Future _checkForLaunchIntent() async {
    final intent = DeviceInfoService().launchIntent;
    if (intent != null) {
      Entry? todayEntry = EntriesProvider.instance.getEntryForToday();
      List<EntryImage> todayImages = todayEntry != null
          ? EntryImagesProvider.instance.getForEntry(todayEntry)
          : [];
      DeviceInfoService().launchIntent = null;
      if (intent is TakePhotoIntent) {
        await _openWithCamera(todayEntry, todayImages);
      } else if (todayEntry != null) {
        await _editEntry(todayEntry, todayImages);
      } else {
        await _addNewEntryForToday();
      }
    }
  }

  Future<void> _openOnThisDayTimeline(DateTime referenceDate) async {
    final hasEntries = EntriesProvider.instance.entries.any((e) =>
        e.timeCreate.day == referenceDate.day &&
        e.timeCreate.month == referenceDate.month &&
        e.timeCreate.year != referenceDate.year);
    if (!hasEntries || !mounted) return;

    await Navigator.of(context).push(MaterialPageRoute(
      allowSnapshotting: false,
      builder: (context) => EntryTimelinePage(
        header: AppLocalizations.of(context)!.flashbackOnThisDay,
        getEntries: () => EntriesProvider.instance.entries
            .where((e) =>
                e.timeCreate.day == referenceDate.day &&
                e.timeCreate.month == referenceDate.month &&
                e.timeCreate.year != referenceDate.year)
            .toList(),
        labelBuilder: (e) => AppLocalizations.of(context)!
            .flashbackYear(referenceDate.year - e.timeCreate.year),
      ),
    ));
  }

  Future _checkForNotificationLaunch() async {
    if (firstLoad) {
      firstLoad = false;
      if (Platform.isAndroid) {
        var launchDetails = await NotificationManager.instance.notifications
            .getNotificationAppLaunchDetails();

        if (!NotificationManager.instance.justLaunched) return;
        NotificationManager.instance.justLaunched = false;

        final notifId = launchDetails?.notificationResponse?.id;
        final payload = launchDetails?.notificationResponse?.payload ?? '';

        if (notifId == 1) {
          DateTime referenceDate = DateTime.tryParse(payload) ?? DateTime.now();
          await NotificationManager.instance.dismissOnThisDayNotification();
          await _openOnThisDayTimeline(referenceDate);
        } else if (notifId == 0) {
          DateTime targetDate = DateTime.tryParse(payload) ?? DateTime.now();
          Entry? entry = EntriesProvider.instance.getEntryForDate(targetDate);
          List<EntryImage> entryImages = entry != null
              ? EntryImagesProvider.instance.getForEntry(entry)
              : [];

          await Navigator.of(context).push(
            MaterialPageRoute(
                allowSnapshotting: false,
                builder: (context) => AddEditEntryPage(
                      entry: entry,
                      openCamera: false,
                      images: entryImages,
                      overrideCreateDate: TimeManager.isToday(targetDate)
                          ? DateTime.now()
                          : TimeManager.currentTimeOnDifferentDate(targetDate),
                    )),
          );
        }
      }
    }
  }

  Widget _buildFlashbacksRow(BuildContext context, List<Flashback> flashbacks) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: SizedBox(
        height: 130,
        child: ShaderMask(
          shaderCallback: (Rect bounds) => const LinearGradient(
            stops: [0, 0.02, 0.98, 1],
            colors: [
              Colors.transparent,
              Colors.white,
              Colors.white,
              Colors.transparent
            ],
          ).createShader(bounds),
          blendMode: BlendMode.dstIn,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: flashbacks.length,
            itemBuilder: (context, index) {
              final flashback = flashbacks[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: GestureDetector(
                  onTap: () async {
                    if (flashback.isMultiEntry && flashback.isOnThisDay) {
                      await NotificationManager.instance
                          .dismissOnThisDayNotification();
                      await _openOnThisDayTimeline(DateTime.now());
                    } else if (flashback.isMultiEntry) {
                      final flashbackEntryIds =
                          flashback.entries.map((e) => e.id).toList();
                      final title = flashback.title;
                      final locale = TimeManager.currentLocale(context);
                      if (!context.mounted) return;
                      await Navigator.of(context).push(MaterialPageRoute(
                        allowSnapshotting: false,
                        builder: (context) => EntryTimelinePage(
                          header: title,
                          getEntries: () => EntriesProvider.instance.entries
                              .where((e) => flashbackEntryIds.contains(e.id))
                              .toList()
                              .reversed
                              .toList(),
                          labelBuilder: (e) =>
                              DateFormat.jm(locale).format(e.timeCreate),
                        ),
                      ));
                    } else {
                      await Navigator.of(context).push(MaterialPageRoute(
                        allowSnapshotting: false,
                        builder: (context) => EntriesListPage(
                            index: EntriesProvider.instance
                                .getIndexOfEntry(flashback.firstEntry.id!),
                            getEntries: () => EntriesProvider.instance.entries),
                      ));
                    }
                  },
                  child: FlashbackCard(
                      title: flashback.title, entries: flashback.entries),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final configProvider = Provider.of<ConfigProvider>(context);
    final entriesProvider = Provider.of<EntriesProvider>(context);
    final entryImagesProvider = Provider.of<EntryImagesProvider>(context);

    Entry? todayEntry = entriesProvider.getEntryForToday();
    List<EntryImage> todayImages =
        todayEntry != null ? entryImagesProvider.getForEntry(todayEntry) : [];

    final List<Flashback> flashbacks =
        FlashbackManager.getFlashbacks(context, entriesProvider.entries);
    final bool showFlashbacks =
        configProvider.get(ConfigKey.showFlashbacks) && flashbacks.isNotEmpty;
    final bool showBanner = SupportBanner.shouldShowBanner(
      entryCount: entriesProvider.entries.length,
      lastDismissedIso: configProvider
          .get(ConfigKey.lastDismissedSupportBannerDate) as String?,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          if (showBanner) SupportBanner(configProvider: configProvider),
          if (showFlashbacks) _buildFlashbacksRow(context, flashbacks),
          Expanded(
            child: VerticalCalendar(scrollController: _scrollController),
          ),
        ],
      ),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
        key: _fabKey,
        distance: 80,
        type: ExpandableFabType.fan,
        fanAngle: 85,
        openCloseStackAlignment: Alignment.centerRight,
        openButtonBuilder: RotateFloatingActionButtonBuilder(
          elevation: 1,
          child: const Icon(Icons.add_rounded),
          fabSize: ExpandableFabSize.regular,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
        closeButtonBuilder: DefaultFloatingActionButtonBuilder(
          elevation: 1,
          child: const Icon(Icons.close_rounded),
          fabSize: ExpandableFabSize.regular,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
        children: [
          if (Platform.isAndroid)
            FloatingActionButton.small(
              heroTag: null,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.primaryContainer,
              elevation: 1,
              shape: const CircleBorder(),
              onPressed: () async =>
                  await _openWithCamera(todayEntry, todayImages),
              child: const Icon(Icons.camera_alt_rounded),
            ),
          FloatingActionButton.small(
            heroTag: null,
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.primaryContainer,
            elevation: 1,
            shape: const CircleBorder(),
            onPressed: () async => await _addEntryForPickedDay(),
            child: const Icon(Icons.event_rounded),
          ),
          FloatingActionButton.small(
            heroTag: null,
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.primaryContainer,
            elevation: 1,
            shape: const CircleBorder(),
            onPressed: () async => await _addNewEntryForToday(),
            child: const Icon(Icons.schedule_rounded),
          ),
        ],
      ),
    );
  }
}
