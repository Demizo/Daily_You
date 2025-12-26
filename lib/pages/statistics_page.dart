import 'package:daily_you/models/entry.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/widgets/mood_by_day_chart.dart';
import 'package:daily_you/widgets/mood_by_month_chart.dart';
import 'package:daily_you/widgets/mood_totals_chart.dart';
import 'package:daily_you/widgets/stat_range_selector.dart';
import 'package:daily_you/widgets/streak_card.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage>
    with AutomaticKeepAliveClientMixin {
  StatsRange statsRange = StatsRange.month;
  List<Entry> entriesInRange = List.empty();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Center(
      child: SingleChildScrollView(
        child: buildEntries(context),
      ),
    );
  }

  Widget buildEntries(BuildContext context) {
    final entriesProvider = Provider.of<EntriesProvider>(context);
    entriesInRange = entriesProvider.getEntriesInRange(statsRange);
    int wordCount = entriesProvider.getWordCount();
    var (currentStreak, longestStreak, daysSinceBadDay) =
        entriesProvider.getStreaks();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MoodByMonthChart(),
        Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
          child: Wrap(
            children: [
              StreakCard(
                title:
                    AppLocalizations.of(context)!.streakCurrent(currentStreak),
                isVisible: currentStreak > 0,
                icon: Icons.bolt,
              ),
              StreakCard(
                  title: AppLocalizations.of(context)!
                      .streakLongest(longestStreak),
                  isVisible: longestStreak > currentStreak,
                  icon: Icons.history_rounded),
              StreakCard(
                  title: AppLocalizations.of(context)!
                      .streakSinceBadDay(daysSinceBadDay ?? 0),
                  isVisible: daysSinceBadDay != null && daysSinceBadDay > 3,
                  icon: Icons.timeline_rounded),
              StreakCard(
                title: AppLocalizations.of(context)!
                    .logCount(entriesProvider.entries.length),
                isVisible: entriesProvider.entries.isNotEmpty,
                icon: Icons.description_outlined,
              ),
              StreakCard(
                title: AppLocalizations.of(context)!.wordCount(wordCount),
                isVisible: wordCount > 100,
                icon: Icons.sort_rounded,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: StatsRangeSelector(
              statsRange: statsRange,
              onSelectionChanged: (newSelection) {
                setState(() {
                  statsRange = newSelection;
                });
              },
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
          moodCounts: getMoodTotals(entriesInRange),
        ),
        Center(
          child: Text(
            AppLocalizations.of(context)!
                .chartByDayTitle(AppLocalizations.of(context)!.tagMoodTitle),
            style: const TextStyle(fontSize: 18),
          ),
        ),
        MoodByDayChart(
          averageMood: getMoodsByDay(entriesInRange),
        ),
      ],
    );
  }

  Map<int, int> getMoodTotals(List<Entry> entriesInRange) {
    Map<int, int> moodTotals = {
      -2: 0,
      -1: 0,
      0: 0,
      1: 0,
      2: 0,
    };

    for (Entry entry in entriesInRange) {
      if (entry.mood == null) continue;
      moodTotals.update(
        entry.mood!,
        (value) => value + 1,
      );
    }

    return moodTotals;
  }

  Map<String, double> getMoodsByDay(List<Entry> entriesInRange) {
    Map<String, List<double>> moodsByDay = {};

    for (Entry entry in entriesInRange) {
      if (entry.mood == null) continue;
      String dayKey = DateFormat('EEE').format(entry.timeCreate);

      if (moodsByDay[dayKey] == null) {
        moodsByDay[dayKey] = List.empty(growable: true);
        moodsByDay[dayKey]!.add(entry.mood!.toDouble());
      } else {
        moodsByDay[dayKey]!.add(entry.mood!.toDouble());
      }
    }

    // Average the mood for each day
    for (var key in moodsByDay.keys) {
      moodsByDay[key]!.first =
          moodsByDay[key]!.reduce((a, b) => a + b) / moodsByDay[key]!.length;
    }

    Map<String, double> averageMoodsByDay = {
      'Mon': -2,
      'Tue': -2,
      'Wed': -2,
      'Thu': -2,
      'Fri': -2,
      'Sat': -2,
      'Sun': -2,
    };

    for (String key in moodsByDay.keys) {
      if (moodsByDay[key] == null) {
        averageMoodsByDay[key] = -2;
      } else {
        averageMoodsByDay[key] = moodsByDay[key]!.first;
      }
    }

    return averageMoodsByDay;
  }
}
