import 'package:daily_you/time_manager.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/entries_database.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/widgets/entry_calendar.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late Entry? todaysEntry;
  bool isLoading = false;
  String searchText = '';
  bool sortOrderAsc = true;
  int currentStreak = 0;
  int longestStreak = 0;
  int? daysSinceBadDay = null;

  @override
  void initState() {
    super.initState();
    todaysEntry = null;
    currentStreak = 0;
    longestStreak = 0;
    daysSinceBadDay = null;
    getToday();
  }

  @override
  void dispose() {
    EntriesDatabase.instance.close();

    super.dispose();
  }

  Future getToday() async {
    setState(() => isLoading = true);

    // Get streaks
    await getStreaks();

    todaysEntry =
        await EntriesDatabase.instance.getEntryForDate(DateTime.now());
    setState(() => isLoading = false);
  }

  Future getStreaks() async {
    var entries = await EntriesDatabase.instance.getAllEntries();

    var isFirstStreak = true;
    var activeStreak = 0;

    var prevEntry = null;

    bool mostRecentBadDay = true;
    for (Entry entry in entries) {
      // Check for bad day
      if (entry.mood != null && mostRecentBadDay) {
        if (entry.mood! < 0) {
          mostRecentBadDay = false;
          daysSinceBadDay = TimeManager.startOfDay(DateTime.now())
              .difference(TimeManager.startOfDay(entry.timeCreate))
              .inDays;
        }
      }

      // Increment current streak
      if (prevEntry != null &&
          TimeManager.startOfDay(prevEntry.timeCreate)
                  .difference(TimeManager.startOfDay(entry.timeCreate))
                  .inDays >
              1) {
        if (isFirstStreak &&
            TimeManager.startOfDay(DateTime.now())
                    .difference(
                        TimeManager.startOfDay(entries.first.timeCreate))
                    .inDays <=
                1) currentStreak = activeStreak;
        isFirstStreak = false;
        activeStreak = 1;
      } else {
        activeStreak += 1;
        if (activeStreak > longestStreak) {
          longestStreak = activeStreak;
        }
      }

      // Set the current streak if we have reached the end and are still on the first streak
      if (isFirstStreak && entry == entries.last) {
        currentStreak = activeStreak;
      }

      prevEntry = entry;
    }
  }

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          child: isLoading ? const SizedBox() : buildEntries(context),
        ),
      );

  Widget buildEntries(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text("Current streak: $currentStreak",
                style: const TextStyle(fontSize: 18)),
          ),
          if (longestStreak > 0)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text("Longest streak: $longestStreak",
                  style: const TextStyle(fontSize: 18)),
            ),
          if (daysSinceBadDay != null && daysSinceBadDay! > 0)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text("Days since a bad day: $daysSinceBadDay",
                  style: const TextStyle(fontSize: 18)),
            ),
          const Center(
              child: SizedBox(height: 400, width: 400, child: EntryCalendar())),
        ],
      );
}
