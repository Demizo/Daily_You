import 'package:daily_you/stats_provider.dart';
import 'package:daily_you/widgets/mood_by_day_chart.dart';
import 'package:daily_you/widgets/mood_by_month_chart.dart';
import 'package:daily_you/widgets/mood_totals_chart.dart';
import 'package:daily_you/widgets/stat_range_selector.dart';
import 'package:daily_you/widgets/streak_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          child: buildEntries(context),
        ),
      );

  Widget buildEntries(BuildContext context) {
    final statsProvider = Provider.of<StatsProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MoodByMonthChart(),
        Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
          child: Wrap(
            children: [
              StreakCard(
                title: AppLocalizations.of(context)!
                    .streakCurrent(statsProvider.currentStreak),
                isVisible: true,
                icon: Icons.bolt,
              ),
              StreakCard(
                  title: AppLocalizations.of(context)!
                      .streakLongest(statsProvider.longestStreak),
                  isVisible:
                      statsProvider.longestStreak > statsProvider.currentStreak,
                  icon: Icons.history_rounded),
              StreakCard(
                  title: AppLocalizations.of(context)!
                      .streakSinceBadDay(statsProvider.daysSinceBadDay ?? 0),
                  isVisible: statsProvider.daysSinceBadDay != null &&
                      statsProvider.daysSinceBadDay! > 3,
                  icon: Icons.timeline_rounded),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: StatsRangeSelector(
              onSelectionChanged: (newSelection) {},
            ),
          ),
        ),
        Center(
          child: Text(
            AppLocalizations.of(context)!
                .chartSummaryTitle(AppLocalizations.of(context)!.tagMoodTitle),
            style: const TextStyle(fontSize: 18),
          ),
        ),
        MoodTotalsChart(
          moodCounts: statsProvider.moodTotals,
        ),
        Center(
          child: Text(
            AppLocalizations.of(context)!
                .chartByDayTitle(AppLocalizations.of(context)!.tagMoodTitle),
            style: const TextStyle(fontSize: 18),
          ),
        ),
        MoodByDayChart(
          averageMood: statsProvider.getMoodsByDay(),
        ),
      ],
    );
  }
}
