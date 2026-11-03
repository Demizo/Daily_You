// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:async';
import 'dart:io';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/device_info_service.dart';
import 'package:daily_you/flashback_manager.dart';
import 'package:daily_you/launch_intent.dart';
import 'package:daily_you/models/flashback.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/notification_manager.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/pages/share_page.dart';
import 'package:share_receiver/share_receiver.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/expressive_carousel.dart';
import 'package:daily_you/widgets/expressive_fab_menu.dart';
import 'package:daily_you/widgets/flashback_card.dart';
import 'package:daily_you/widgets/support_banner.dart';
import 'package:daily_you/widgets/vertical_calendar.dart';
import 'package:material_ui/material_ui.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/pages/entries_list_page.dart';
import 'package:daily_you/pages/entry_timeline_page.dart';
import 'package:daily_you/pages/edit_entry_page.dart';
import 'package:provider/provider.dart';

const _flashbackCardHeight = 140.0;
const _flashbackMinWidth = 140.0;
const _flashbackMaxWidth = 280.0;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  bool firstLoad = true;
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<SharePayload>? _shareSubscription;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _checkForLaunchIntent();
    _checkForNotificationLaunch();
    _listenForShares();
  }

  @override
  void dispose() {
    _shareSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openWithCamera(
      Entry? entry, List<EntryAttachment> attachments) async {
    await Navigator.of(context).push(MaterialPageRoute(
      allowSnapshotting: false,
      builder: (context) => AddEditEntryPage(
          entry: entry, openCamera: true, attachments: attachments),
    ));
  }

  Future<void> _addNewEntryForToday() async {
    await Navigator.of(context).push(MaterialPageRoute(
      allowSnapshotting: false,
      builder: (context) => AddEditEntryPage(
          entry: null, openCamera: false, attachments: const []),
    ));
  }

  Future<void> _editEntry(
      Entry entry, List<EntryAttachment> attachments) async {
    await Navigator.of(context).push(MaterialPageRoute(
      allowSnapshotting: false,
      builder: (context) => AddEditEntryPage(
          entry: entry, openCamera: false, attachments: attachments),
    ));
  }

  Future<void> _addEntryForPickedDay() async {
    final picked = await TimeManager.pickDate(
      context,
      initialDate: DateTime.now(),
      firstDate: TimeManager.minEntryDate,
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
        attachments: const [],
        overrideCreateDate: overrideDate,
      ),
    ));
  }

  Future _checkForLaunchIntent() async {
    final intent = DeviceInfoService().launchIntent;
    if (intent != null) {
      Entry? todayEntry = EntriesProvider.instance.getEntryForToday();
      List<EntryAttachment> todayAttachments = todayEntry != null
          ? EntryAttachmentsProvider.instance.getForEntry(todayEntry)
          : [];
      DeviceInfoService().launchIntent = null;
      if (intent is TakePhotoIntent) {
        await _openWithCamera(todayEntry, todayAttachments);
      } else if (todayEntry != null) {
        await _editEntry(todayEntry, todayAttachments);
      } else {
        await _addNewEntryForToday();
      }
    }
  }

  void _listenForShares() {
    if (!Platform.isAndroid) return;
    _shareSubscription = ShareReceiver.instance.shares.listen(_handleShare);
  }

  Future<void> _handleShare(SharePayload payload) async {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    await Navigator.of(context).push(MaterialPageRoute(
      allowSnapshotting: false,
      builder: (context) => SharePage(payload: payload),
    ));
  }

  Future<void> _openOnThisDayTimeline(DateTime referenceDate) async {
    final isJalali = TimeManager.isJalaliCalendar(context);
    final refYear = TimeManager.calendarYearOf(referenceDate, isJalali);

    final hasEntries = EntriesProvider.instance.entries.any((e) =>
        TimeManager.isOnThisDayMatch(e.timeCreate, referenceDate, isJalali));
    if (!hasEntries || !mounted) return;

    await Navigator.of(context).push(MaterialPageRoute(
      allowSnapshotting: false,
      builder: (context) => EntryTimelinePage(
        header: AppLocalizations.of(context)!.flashbackOnThisDay,
        getEntries: () => EntriesProvider.instance.entries
            .where((e) => TimeManager.isOnThisDayMatch(
                e.timeCreate, referenceDate, isJalali))
            .toList(),
        labelBuilder: (_, e) => AppLocalizations.of(context)!.flashbackYear(
            refYear - TimeManager.calendarYearOf(e.timeCreate, isJalali)),
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
          List<EntryAttachment> entryAttachments = entry != null
              ? EntryAttachmentsProvider.instance.getForEntry(entry)
              : [];

          if (!mounted) return;
          await Navigator.of(context).push(
            MaterialPageRoute(
                allowSnapshotting: false,
                builder: (context) => AddEditEntryPage(
                      entry: entry,
                      openCamera: false,
                      attachments: entryAttachments,
                      overrideCreateDate: TimeManager.isToday(targetDate)
                          ? DateTime.now()
                          : TimeManager.currentTimeOnDifferentDate(targetDate),
                    )),
          );
        }
      }
    }
  }

  Future<void> _openFlashback(Flashback flashback) async {
    if (flashback.isMultiEntry && flashback.isOnThisDay) {
      await NotificationManager.instance.dismissOnThisDayNotification();
      await _openOnThisDayTimeline(DateTime.now());
    } else if (flashback.isMultiEntry) {
      final flashbackEntryIds =
          flashback.entries.map((entry) => entry.id).toList();
      final title = flashback.title;
      if (!context.mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        allowSnapshotting: false,
        builder: (context) => EntryTimelinePage(
          header: title,
          getEntries: () => EntriesProvider.instance.entries
              .where((entry) => flashbackEntryIds.contains(entry.id))
              .toList(),
          labelBuilder: (context, entry) => TimeManager.localizedTimeFormat(
                  context, TimeManager.currentLocale(context))
              .format(entry.timeCreate),
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
  }

  Widget _buildFlashbacksRow(BuildContext context, List<Flashback> flashbacks) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: ExpressiveCarousel(
        heightForItemWidth: (_) => _flashbackCardHeight,
        itemMinWidth: _flashbackMinWidth,
        itemMaxWidth: _flashbackMaxWidth,
        itemCount: flashbacks.length,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        alignment: AlignmentDirectional.centerStart,
        onTap: (index) => _openFlashback(flashbacks[index]),
        itemBuilder: (context, index) => FlashbackCard(
            title: flashbacks[index].title, entries: flashbacks[index].entries),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final configProvider = Provider.of<ConfigProvider>(context);
    final entriesProvider = Provider.of<EntriesProvider>(context);
    final entryAttachmentsProvider =
        Provider.of<EntryAttachmentsProvider>(context);

    Entry? todayEntry = entriesProvider.getEntryForToday();
    List<EntryAttachment> todayAttachments = todayEntry != null
        ? entryAttachmentsProvider.getForEntry(todayEntry)
        : [];

    final List<Flashback> flashbacks =
        FlashbackManager.getFlashbacks(context, entriesProvider.entries);
    final bool showFlashbacks =
        configProvider.get(Settings.showFlashbacks) && flashbacks.isNotEmpty;
    final bool showBanner = SupportBanner.shouldShowBanner(
      entryCount: entriesProvider.entries.length,
      lastDismissedIso:
          configProvider.get(Settings.lastDismissedSupportBannerDate),
    );

    return Stack(alignment: Alignment.bottomCenter, children: [
      Column(
        children: [
          if (showBanner) SupportBanner(configProvider: configProvider),
          if (showFlashbacks) _buildFlashbacksRow(context, flashbacks),
          Expanded(
            child: VerticalCalendar(scrollController: _scrollController),
          ),
        ],
      ),
      Align(
        alignment: AlignmentDirectional.bottomEnd,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ExpressiveFabMenu(items: [
            ExpressiveFabMenuItem(
                icon: Icons.camera_alt_rounded,
                label: AppLocalizations.of(context)!.actionTakePhoto,
                onTap: () async =>
                    await _openWithCamera(todayEntry, todayAttachments)),
            ExpressiveFabMenuItem(
                icon: Icons.event_rounded,
                label: AppLocalizations.of(context)!.actionOtherDay,
                onTap: () async => await _addEntryForPickedDay()),
            ExpressiveFabMenuItem(
                icon: Icons.schedule_rounded,
                label: AppLocalizations.of(context)!.actionToday,
                onTap: () async => await _addNewEntryForToday(),
                secondaryIcon: todayEntry != null ? Icons.edit_rounded : null,
                secondaryOnTap: todayEntry != null
                    ? () async => await _editEntry(todayEntry, todayAttachments)
                    : null),
          ]),
        ),
      )
    ]);
  }
}
