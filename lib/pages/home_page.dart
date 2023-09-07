import 'dart:io';

import 'package:daily_you/flashback_manager.dart';
import 'package:daily_you/models/flashback.dart';
import 'package:daily_you/notification_manager.dart';
import 'package:daily_you/time_manager.dart';
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
  late List<Flashback> flashbacks;
  late Entry? todayEntry;

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

    entries = await EntriesDatabase.instance.getAllEntries();

    if (entries.isNotEmpty && TimeManager.isToday(entries.first.timeCreate)) {
      todayEntry = entries.first;
    }

    flashbacks = await FlashbackManager.getFlashbacks();

    var launchDetails = await NotificationManager.instance.notifications
        .getNotificationAppLaunchDetails();
    if (NotificationManager.instance.justLaunched &&
        launchDetails?.notificationResponse?.id == 0 &&
        await EntriesDatabase.instance.getEntryForDate(DateTime.now()) ==
            null) {
      NotificationManager.instance.justLaunched = false;
      await logToday();
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) => Center(
        child: isLoading
            ? const SizedBox()
            : Stack(alignment: Alignment.topCenter, children: [
                buildEntries(),
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
                                var newEntry = await Navigator.of(context)
                                    .push(MaterialPageRoute(
                                  builder: (context) =>
                                      const AddEditEntryPage(),
                                ));

                                if (newEntry != null) {
                                  await refreshEntries();
                                }
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
                          if (Platform.isAndroid)
                            IconButton(
                              icon: const Icon(
                                Icons.camera_alt_rounded,
                                size: 30,
                              ),
                              onPressed: () async {
                                var newEntry = await Navigator.of(context)
                                    .push(MaterialPageRoute(
                                  builder: (context) => const AddEditEntryPage(
                                    openCamera: true,
                                  ),
                                ));

                                if (newEntry != null) {
                                  await refreshEntries();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(8),
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.background,
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

  Widget buildEntries() => entries.isEmpty
      ? const Center(
          child: Text(
            'No Logs...',
          ),
        )
      : GridView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          physics: const ScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 300,
            crossAxisSpacing: 1.0, // Spacing between columns
            mainAxisSpacing: 1.0, // Spacing between rows
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

                refreshEntries();
              },
              child: EntryCardWidget(
                title: flashback.title,
                entry: flashback.entry,
              ),
            );
          },
        );
}
