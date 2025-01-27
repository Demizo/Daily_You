import 'dart:io';

import 'package:daily_you/config_manager.dart';
import 'package:daily_you/flashback_manager.dart';
import 'package:daily_you/models/flashback.dart';
import 'package:daily_you/notification_manager.dart';
import 'package:daily_you/stats_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/entry_calendar.dart';
import 'package:daily_you/widgets/large_entry_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/entries_database.dart';
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

class _HomePageState extends State<HomePage> {
  bool listView = true;

  bool isLoading = false;
  String searchText = '';
  bool sortOrderAsc = true;
  bool firstLoad = true;

  @override
  void initState() {
    super.initState();
    String viewMode = ConfigManager.instance.getField('homePageViewMode');
    listView = viewMode == 'list';
    refreshEntries();
  }

  Future<void> logToday() async {
    var newEntry = await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const AddEditEntryPage(),
    ));

    if (newEntry != null) {
      await refreshEntries();
    }
  }

  Future<void> setViewMode() async {
    var viewMode = listView ? 'list' : 'grid';
    await ConfigManager.instance.setField('homePageViewMode', viewMode);
  }

  Future<void> uriErrorPopup(String folderType) async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: const Text("Error:"),
              content: Text(
                  "Can't access the $folderType folder! Go to settings, backup your logs and images, then reset the your external folder locations!"));
        });
  }

  Future refreshEntries() async {
    if (firstLoad) setState(() => isLoading = true);
    if (await ConfigManager.instance.getField("useExternalDb") &&
        !await EntriesDatabase.instance.hasDbUriPermission()) {
      uriErrorPopup("Log");
    }

    if (await ConfigManager.instance.getField("useExternalImg") &&
        !await EntriesDatabase.instance.hasImgUriPermission()) {
      uriErrorPopup("Image");
    }

    await StatsProvider.instance.updateStats();
    firstLoad = false;

    if (Platform.isAndroid) {
      var launchDetails = await NotificationManager.instance.notifications
          .getNotificationAppLaunchDetails();
      if (NotificationManager.instance.justLaunched &&
          launchDetails?.notificationResponse?.id == 0 &&
          await EntriesDatabase.instance.getEntryForDate(DateTime.now()) ==
              null) {
        NotificationManager.instance.justLaunched = false;
        await logToday();
      }
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final statsProvider = Provider.of<StatsProvider>(context);
    Entry? todayEntry;

    List<Flashback> flashbacks =
        FlashbackManager.getFlashbacks(StatsProvider.instance.entries);

    var entries = statsProvider.entries;
    if (entries.isNotEmpty && TimeManager.isToday(entries.first.timeCreate)) {
      todayEntry = entries.first;
    }

    return Center(
      child: isLoading
          ? const SizedBox()
          : Stack(alignment: Alignment.topCenter, children: [
              buildEntries(flashbacks),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (todayEntry == null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton.icon(
                            icon: Icon(
                              Icons.add_circle_rounded,
                              color: Theme.of(context).colorScheme.surface,
                              size: 30,
                            ),
                            label: const Padding(
                              padding: EdgeInsets.all(2.0),
                              child: Text(
                                "Log Today...",
                                style: TextStyle(fontSize: 24),
                              ),
                            ),
                            onPressed: () async {
                              await Navigator.of(context)
                                  .push(MaterialPageRoute(
                                builder: (context) => const AddEditEntryPage(),
                              ));
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(12),
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.surface,
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                            ),
                          ),
                        ),
                        if (Platform.isAndroid)
                          IconButton(
                            icon: const Icon(
                              Icons.camera_alt_rounded,
                              size: 30,
                            ),
                            onPressed: () async {
                              await Navigator.of(context)
                                  .push(MaterialPageRoute(
                                builder: (context) => const AddEditEntryPage(
                                  openCamera: true,
                                ),
                              ));
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(8),
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.surface,
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(80.0),
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ]),
    );
  }

  Widget buildEntries(List<Flashback> flashbacks) => ListView(children: [
        const Center(
            child: SizedBox(height: 430, width: 400, child: EntryCalendar())),
        Card(
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "Flashbacks",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal),
              ),
            ),
            IconButton(
                onPressed: () async {
                  listView = !listView;
                  await setViewMode();
                  setState(() {});
                },
                icon: listView
                    ? const Icon(Icons.grid_view_rounded)
                    : const Icon(Icons.view_list_rounded)),
          ]),
        ),
        flashbacks.isEmpty
            ? Center(
                child: Text(
                  "No flashbacks yet...",
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
                          builder: (context) =>
                              EntryDetailPage(entryId: flashback.entry.id!),
                        ));
                      },
                      child: listView
                          ? LargeEntryCardWidget(
                              title: flashback.title,
                              entry: flashback.entry,
                              images: StatsProvider.instance.images
                                  .where((img) =>
                                      img.entryId == flashback.entry.id!)
                                  .toList())
                          : EntryCardWidget(
                              title: flashback.title,
                              entry: flashback.entry,
                              images: StatsProvider.instance.images
                                  .where((img) =>
                                      img.entryId == flashback.entry.id!)
                                  .toList(),
                            ));
                },
              ),
      ]);
}
