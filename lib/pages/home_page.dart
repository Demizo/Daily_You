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
import 'package:daily_you/widgets/entry_calendar.dart';
import 'package:daily_you/widgets/flashback_card.dart';
import 'package:daily_you/widgets/hiding_widget.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/pages/entries_list_page.dart';
import 'package:daily_you/pages/entry_timeline_page.dart';
import 'package:daily_you/pages/edit_entry_page.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  String searchText = '';
  bool sortOrderAsc = true;
  bool firstLoad = true;
  final ScrollController _scrollController = ScrollController();

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
    super.dispose();
    _scrollController.dispose();
  }

  Future<void> addOrEditTodayEntry(
      Entry? todayEntry, List<EntryImage> todayImages, bool openCamera) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
          allowSnapshotting: false,
          builder: (context) => AddEditEntryPage(
              entry: todayEntry, openCamera: openCamera, images: todayImages)),
    );
  }

  Future _checkForLaunchIntent() async {
    final intent = DeviceInfoService().launchIntent;
    if (intent != null) {
      Entry? todayEntry = EntriesProvider.instance.getEntryForToday();
      List<EntryImage> todayImages = todayEntry != null
          ? EntryImagesProvider.instance.getForEntry(todayEntry)
          : [];
      bool openCamera = (intent is TakePhotoIntent) ? true : false;
      DeviceInfoService().launchIntent = null;
      await addOrEditTodayEntry(todayEntry, todayImages, openCamera);
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final configProvider = Provider.of<ConfigProvider>(context);
    final entriesProvider = Provider.of<EntriesProvider>(context);
    final entryImagesProvider = Provider.of<EntryImagesProvider>(context);

    Entry? todayEntry = entriesProvider.getEntryForToday();
    List<EntryImage> todayImages =
        todayEntry != null ? entryImagesProvider.getForEntry(todayEntry) : [];

    List<Flashback> flashbacks =
        FlashbackManager.getFlashbacks(context, entriesProvider.entries);

    return Center(
      child: Stack(alignment: Alignment.bottomCenter, children: [
        buildEntries(context, configProvider, flashbacks),
        HidingWidget(
          duration: Duration(milliseconds: 200),
          hideDirection: HideDirection.down,
          scrollController: _scrollController,
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (Platform.isAndroid)
                  FloatingActionButton.small(
                    heroTag: "home-camera-button",
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    elevation: 1,
                    shape: CircleBorder(),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: Theme.of(context).colorScheme.primaryContainer,
                      size: 24,
                    ),
                    onPressed: () async {
                      await addOrEditTodayEntry(todayEntry, todayImages, true);
                    },
                  ),
                FloatingActionButton(
                  heroTag: "home-entry-button",
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  elevation: 1,
                  child: Icon(
                    todayEntry == null ? Icons.add_rounded : Icons.edit_rounded,
                    color: Theme.of(context).colorScheme.primaryContainer,
                    size: 28,
                  ),
                  onPressed: () async {
                    await addOrEditTodayEntry(todayEntry, todayImages, false);
                  },
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget buildEntries(BuildContext context, ConfigProvider configProvider,
          List<Flashback> flashbacks) =>
      ListView(controller: _scrollController, children: [
        const Center(
            child: SizedBox(height: 430, width: 400, child: EntryCalendar())),
        if (configProvider.get(ConfigKey.showFlashbacks))
          Padding(
            padding:
                EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 8.0),
            child: Text(
              AppLocalizations.of(context)!.flashbacksTitle,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.normal),
            ),
          ),
        if (configProvider.get(ConfigKey.showFlashbacks))
          flashbacks.isEmpty
              ? Center(
                  child: Text(
                    AppLocalizations.of(context)!.flaskbacksEmpty,
                    style: TextStyle(
                        fontSize: 18, color: Theme.of(context).disabledColor),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  physics: const ScrollPhysics(),
                  shrinkWrap: true,
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 300,
                    crossAxisSpacing: 1.0, // Spacing between columns
                    mainAxisSpacing: 1.0, // Spacing between rows
                    childAspectRatio: 1.0,
                  ),
                  itemCount: flashbacks.length,
                  itemBuilder: (context, index) {
                    final flashback = flashbacks[index];
                    return GestureDetector(
                        onTap: () async {
                          if (flashback.isMultiEntry) {
                            // TODO: Currently, only On This Day can have multiple entries. Revisit this approach when allowing multiple entries per day.
                            await NotificationManager.instance
                                .dismissOnThisDayNotification();
                            await _openOnThisDayTimeline(DateTime.now());
                          } else {
                            await Navigator.of(context).push(MaterialPageRoute(
                              allowSnapshotting: false,
                              builder: (context) => EntriesListPage(
                                  index: EntriesProvider.instance
                                      .getIndexOfEntry(
                                          flashback.firstEntry.id!),
                                  getEntries: () =>
                                      EntriesProvider.instance.entries),
                            ));
                          }
                        },
                        child: FlashbackCard(
                            title: flashback.title,
                            entries: flashback.entries));
                  },
                ),
      ]);
}
