import 'dart:io';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/flashback_manager.dart';
import 'package:daily_you/models/flashback.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/notification_manager.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/entry_calendar.dart';
import 'package:daily_you/widgets/hiding_widget.dart';
import 'package:daily_you/widgets/large_entry_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/pages/entry_detail_page.dart';
import 'package:daily_you/pages/edit_entry_page.dart';
import 'package:provider/provider.dart';
import '../widgets/entry_card_widget.dart';

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

  Future _checkForNotificationLaunch() async {
    if (firstLoad) {
      firstLoad = false;
      if (Platform.isAndroid) {
        var launchDetails = await NotificationManager.instance.notifications
            .getNotificationAppLaunchDetails();

        if (NotificationManager.instance.justLaunched &&
            launchDetails?.notificationResponse?.id == 0) {
          NotificationManager.instance.justLaunched = false;

          DateTime targetDate = DateTime.tryParse(
                  launchDetails?.notificationResponse?.payload ?? "") ??
              DateTime.now();
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

    String viewMode = ConfigProvider.instance.get(ConfigKey.homePageViewMode);
    bool listView = viewMode == 'list';

    return Center(
      child: Stack(alignment: Alignment.bottomCenter, children: [
        buildEntries(context, configProvider, flashbacks, listView),
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
                  IconButton(
                    icon: const Icon(
                      Icons.camera_alt_rounded,
                      size: 24,
                    ),
                    onPressed: () async {
                      await addOrEditTodayEntry(todayEntry, todayImages, true);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.surface,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(80.0),
                      ),
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    todayEntry == null ? Icons.add_rounded : Icons.edit_rounded,
                    color: Theme.of(context).colorScheme.surface,
                    size: 28,
                  ),
                  onPressed: () async {
                    await addOrEditTodayEntry(todayEntry, todayImages, false);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.surface,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(80.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget buildEntries(BuildContext context, ConfigProvider configProvider,
          List<Flashback> flashbacks, bool listView) =>
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
                    maxCrossAxisExtent: listView ? 500 : 300,
                    crossAxisSpacing: 1.0, // Spacing between columns
                    mainAxisSpacing: 1.0, // Spacing between rows
                    childAspectRatio: listView ? 2.0 : 1.0,
                  ),
                  itemCount: flashbacks.length,
                  itemBuilder: (context, index) {
                    final flashback = flashbacks[index];
                    return GestureDetector(
                        onTap: () async {
                          await Navigator.of(context).push(MaterialPageRoute(
                            allowSnapshotting: false,
                            builder: (context) => EntryDetailPage(
                                filtered: false,
                                index: EntriesProvider.instance
                                    .getIndexOfEntry(flashback.entry.id!)),
                          ));
                        },
                        child: listView
                            ? LargeEntryCardWidget(
                                title: flashback.title,
                                entry: flashback.entry,
                                images: EntryImagesProvider.instance
                                    .getForEntry(flashback.entry))
                            : EntryCardWidget(
                                title: flashback.title,
                                entry: flashback.entry,
                                images: EntryImagesProvider.instance
                                    .getForEntry(flashback.entry)));
                  },
                ),
      ]);
}
