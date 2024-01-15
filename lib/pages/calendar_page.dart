import 'package:daily_you/stats_provider.dart';
import 'package:daily_you/widgets/streak_card.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/entries_database.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/widgets/entry_calendar.dart';
import 'package:provider/provider.dart';

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

  @override
  void initState() {
    super.initState();
    todaysEntry = null;

    getToday();
  }

  @override
  void dispose() {
    EntriesDatabase.instance.close();

    super.dispose();
  }

  Future getToday() async {
    setState(() => isLoading = true);
    await StatsProvider.instance.updateStats();
    todaysEntry =
        await EntriesDatabase.instance.getEntryForDate(DateTime.now());
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          child: isLoading ? const SizedBox() : buildEntries(context),
        ),
      );

  Widget buildEntries(BuildContext context) {
    final statsProvider = Provider.of<StatsProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          children: [
            StreakCard(
              title: "Current Streak ",
              number: statsProvider.currentStreak,
              isVisible: true,
              icon: Icons.bolt,
            ),
            StreakCard(
                title: "Longest Streak ",
                number: statsProvider.longestStreak,
                isVisible:
                    statsProvider.longestStreak > statsProvider.currentStreak,
                icon: Icons.history_rounded),
            StreakCard(
                title: "Days since a Bad Day ",
                number: statsProvider.daysSinceBadDay ?? -1,
                isVisible: statsProvider.daysSinceBadDay != null &&
                    statsProvider.daysSinceBadDay! > 3,
                icon: Icons.timeline_rounded),
          ],
        ),
        const Center(
            child: SizedBox(height: 400, width: 400, child: EntryCalendar())),
      ],
    );
  }
}
