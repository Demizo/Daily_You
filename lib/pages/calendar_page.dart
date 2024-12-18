import 'package:daily_you/stats_provider.dart';
import 'package:daily_you/widgets/mood_by_day_chart.dart';
import 'package:daily_you/widgets/mood_by_month_chart.dart';
import 'package:daily_you/widgets/mood_totals_chart.dart';
import 'package:daily_you/widgets/stat_range_selector.dart';
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
  StatsRange statsRange = StatsRange.month;
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
        Center(
          child: StatsRangeSelector(
            onSelectionChanged: (newSelection) {
              statsRange = newSelection.first;
            },
          ),
        ),
        const Center(
          child: Text(
            "Mood Summary",
            style: TextStyle(fontSize: 18),
          ),
        ),
        MoodTotalsChart(
          moodCounts: statsProvider.moodTotals,
        ),
        const Center(
          child: Text(
            "Mood By Day",
            style: TextStyle(fontSize: 18),
          ),
        ),
        MoodByDayChart(),
        if (statsProvider.statsRange != StatsRange.month)
          const Center(
            child: Text(
              "Mood History",
              style: TextStyle(fontSize: 18),
            ),
          ),
        if (statsProvider.statsRange != StatsRange.month) MoodByMonthChart()
      ],
    );
  }
}
