import 'package:daily_you/stats_provider.dart';
import 'package:daily_you/widgets/mood_totals_chart.dart';
import 'package:daily_you/widgets/streak_card.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/widgets/entry_calendar.dart';
import 'package:provider/provider.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  bool allTime = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    updateStats();
  }

  Future updateStats() async {
    setState(() => isLoading = true);
    await StatsProvider.instance.updateStats();
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
            child: SizedBox(height: 430, width: 400, child: EntryCalendar())),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: ElevatedButton(
            onPressed: (() => setState(() {
                  allTime = !allTime;
                })),
            style: ButtonStyle(
                padding: WidgetStateProperty.all(const EdgeInsets.all(8)),
                elevation: WidgetStateProperty.all(0.0)),
            child: Text(
              allTime ? "All Time" : "This Month",
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        MoodTotalsChart(
          moodCounts: allTime
              ? StatsProvider.instance.moodCountsAllTime
              : StatsProvider.instance.moodCountsThisMonth,
        ),
      ],
    );
  }
}
