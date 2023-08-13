import 'package:daily_you/notification_manager.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/entries_database.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/pages/entry_detail_page.dart';
import 'package:daily_you/pages/edit_entry_page.dart';

import '../widgets/entry_card_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<Entry> entries;
  late Entry? todayEntry;
  late Entry? lastEntry;
  late Entry? lastHappyEntry;
  late Entry? lastWeekEntry;
  late Entry? lastYearEntry;

  bool isLoading = false;
  String searchText = '';
  bool sortOrderAsc = true;

  @override
  void initState() {
    super.initState();

    refreshEntries();
  }

  @override
  void dispose() {
    EntriesDatabase.instance.close();

    super.dispose();
  }

  Future<void> logToday() async {
    var newEntry = await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const AddEditEntryPage(),
    ));

    if (newEntry != null) {
      await refreshEntries();
    }
  }

  Future refreshEntries() async {
    setState(() => isLoading = true);

    todayEntry = null;
    lastEntry = null;
    lastHappyEntry = null;
    lastWeekEntry = null;
    lastYearEntry = null;

    entries = await EntriesDatabase.instance.getAllEntries();

    for (var entry in entries) {
      if (entries.indexOf(entry) == 0 &&
          entry.timeCreate.day == DateTime.now().day) {
        todayEntry = entry;
      } else if (entry != todayEntry) {
        lastEntry ??= entry;
      }
      if (entry.mood == 2) {
        lastHappyEntry ??= entry;
      }
      DateTime currentDate = DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day);
      DateTime oneWeekAgoDate = currentDate.subtract(const Duration(days: 7));
      if (oneWeekAgoDate.isAtSameMomentAs(DateTime(entry.timeCreate.year,
          entry.timeCreate.month, entry.timeCreate.day))) {
        lastWeekEntry = entry;
      }
      //Close enough, I'm lazy
      DateTime oneYearAgoDate = currentDate.subtract(const Duration(days: 365));
      if (oneYearAgoDate.isAtSameMomentAs(DateTime(entry.timeCreate.year,
          entry.timeCreate.month, entry.timeCreate.day))) {
        lastYearEntry = entry;
      }
    }
    var launchDetails = await NotificationManager.instance.notifications
        .getNotificationAppLaunchDetails();
    if (NotificationManager.instance.justLaunched &&
        launchDetails?.notificationResponse?.id == 0) {
      NotificationManager.instance.justLaunched = false;
      await logToday();
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) => Center(
        child: isLoading
            ? const SizedBox()
            : Stack(alignment: Alignment.bottomCenter, children: [
                buildEntries(),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (todayEntry == null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton.icon(
                          icon: const Icon(
                            Icons.add_circle_rounded,
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
                            await logToday();
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(12),
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.background,
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ]),
      );

  Widget buildEntries() => entries.isEmpty
      ? const Center(
          child: Text(
            'No Logs...',
          ),
        )
      : ListView(children: [
          GridView.extent(
            maxCrossAxisExtent: 300,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            childAspectRatio: 1,
            children: [
              if (todayEntry != null)
                GestureDetector(
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) =>
                          EntryDetailPage(entryId: todayEntry!.id!),
                    ));

                    refreshEntries();
                  },
                  child: EntryCardWidget(
                    title: "Today",
                    entry: todayEntry!,
                  ),
                ),
              if (lastEntry != null)
                GestureDetector(
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) =>
                          EntryDetailPage(entryId: lastEntry!.id!),
                    ));

                    refreshEntries();
                  },
                  child: EntryCardWidget(
                    title: "Previous",
                    entry: lastEntry!,
                  ),
                ),
              if (lastHappyEntry != null)
                GestureDetector(
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) =>
                          EntryDetailPage(entryId: lastHappyEntry!.id!),
                    ));

                    refreshEntries();
                  },
                  child: EntryCardWidget(
                    title: "Previous Happy Day",
                    entry: lastHappyEntry!,
                  ),
                ),
              if (lastWeekEntry != null)
                GestureDetector(
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) =>
                          EntryDetailPage(entryId: lastWeekEntry!.id!),
                    ));

                    refreshEntries();
                  },
                  child: EntryCardWidget(
                    title: "One Week Ago",
                    entry: lastWeekEntry!,
                  ),
                ),
              if (lastYearEntry != null)
                GestureDetector(
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) =>
                          EntryDetailPage(entryId: lastYearEntry!.id!),
                    ));

                    refreshEntries();
                  },
                  child: EntryCardWidget(
                    title: "365 Days Ago",
                    entry: lastYearEntry!,
                  ),
                ),
            ],
          ),
          const SizedBox(
            height: 80,
          )
        ]);
}
