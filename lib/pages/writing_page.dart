// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/stats/stats_analysis.dart';
import 'package:daily_you/stats/stats_range.dart';
import 'package:daily_you/stats/streaks.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/utils/count_format.dart';
import 'package:daily_you/widgets/content_width_limit.dart';
import 'package:daily_you/widgets/day_calendar.dart';
import 'package:daily_you/widgets/frequency_bars.dart';
import 'package:daily_you/widgets/sparkline.dart';
import 'package:daily_you/widgets/stat_progress_bar.dart';
import 'package:daily_you/widgets/stat_range_selector.dart';
import 'package:daily_you/widgets/stat_tile.dart';
import 'package:daily_you/widgets/streak_hero_card.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class WritingPage extends StatefulWidget {
  const WritingPage({super.key});

  @override
  State<WritingPage> createState() => _WritingPageState();
}

class _WritingPageState extends State<WritingPage> {
  List<Entry>? _summarizedEntries;
  StatsRange? _summarizedRange;
  late WritingSummary _summary;

  WritingSummary _summaryOf(List<Entry> entries, StatsRange range) {
    if (!identical(entries, _summarizedEntries) || range != _summarizedRange) {
      _summarizedEntries = entries;
      _summarizedRange = range;
      _summary = writingSummary(entries, range);
    }
    return _summary;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entries = context.watch<EntriesProvider>().entries;
    final statsRange = context
        .select<ConfigProvider, StatsRange>((config) => config.statsRange);
    final summary = _summaryOf(entries, statsRange);
    final streaks = calculateStreaks(entries);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.statsWritingTitle),
      ),
      body: SingleChildScrollView(
        child: ContentWidthLimit(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 32),
            child: Column(children: [
              StreakHeroCard(
                currentStreak: streaks.current,
                longestStreak: streaks.longest,
                recentDaysWritten: recentDaysWritten(entries),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: StatsRangeSelector(
                  statsRange: statsRange,
                  onSelectionChanged: ConfigProvider.instance.setStatsRange,
                ),
              ),
              _DaysWrittenCard(summary: summary),
              _WritingTiles(summary: summary),
            ]),
          ),
        ),
      ),
    );
  }
}

class _DaysWrittenCard extends StatelessWidget {
  const _DaysWrittenCard({required this.summary});

  final WritingSummary summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Card.filled(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                l10n.statsDaysOfRange(
                    summary.daysWritten, summary.window.dayCount),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            DayCalendar(
              window: summary.window,
              filledDays: summary.writtenDays,
              hasData: summary.logCount > 0,
            ),
          ],
        ),
      ),
    );
  }
}

class _WritingTiles extends StatelessWidget {
  const _WritingTiles({required this.summary});

  final WritingSummary summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final locale = l10n.localeName;
    final primary = colorScheme.primary;
    final longestLog = summary.longestLog;
    final averageWords = summary.averageWordsPerLog.round();

    return StatTileGrid(children: [
      StatTile(
        leading: const StatTileIcon(Icons.sort_rounded),
        title: l10n.statsWordsLabel(summary.wordCount),
        value: formatCount(summary.wordCount, locale),
        bottom:
            Sparkline(values: summary.wordSeries, color: primary, minimum: 0),
      ),
      StatTile(
        leading: const StatTileIcon(Icons.description_outlined),
        title: l10n.statsLogsLabel(summary.logCount),
        value: formatCount(summary.logCount, locale),
        bottom: FrequencyBars(values: summary.logSeries, color: primary),
      ),
      StatTile(
        leading: const StatTileIcon(Icons.notes_rounded),
        title: l10n.statsWordsPerLogTitle,
        value: formatCount(averageWords, locale),
        bottom: Sparkline(
            values: summary.wordsPerLogSeries, color: primary, minimum: 0),
      ),
      StatTile(
        leading: const StatTileIcon(Icons.today_rounded),
        title: l10n.statsDaysLoggedTitle,
        value: formatPercent(
            summary.daysWritten / summary.window.dayCount, locale),
        bottom: StatProgressBar(
          fraction: summary.daysWritten / summary.window.dayCount,
          color: primary,
        ),
      ),
      StatTile(
        leading: const StatTileIcon(Icons.emoji_events_outlined),
        title: l10n.statsLongestLogTitle,
        value: formatCount(longestLog?.wordCount ?? 0, locale),
        unit: l10n.statsWordsLabel(longestLog?.wordCount ?? 0),
        bottom: longestLog == null
            ? null
            : Text(
                TimeManager.formatDate(longestLog.date, context),
                style: TextStyle(
                    fontSize: 13, color: colorScheme.onSurfaceVariant),
              ),
      ),
      if (summary.busiestWeekdayIndexes.isNotEmpty)
        _MostActiveTile(summary: summary),
    ]);
  }
}

class _MostActiveTile extends StatelessWidget {
  const _MostActiveTile({required this.summary});

  final WritingSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final weekdayNames = TimeManager.daysOfWeekLabels(context);
    final firstDayIndex = context.select<ConfigProvider, int>(
        (config) => config.getFirstDayOfWeekIndex(context));
    final displayOrder = weekdayDisplayOrder(firstDayIndex);

    return StatTile(
      leading: const StatTileIcon(Icons.calendar_view_week_rounded),
      title: l10n.statsMostActiveTitle(summary.busiestWeekdayIndexes.length),
      value: summary.busiestWeekdayIndexes
          .map((index) => weekdayNames[index])
          .join(' '),
      bottom: FrequencyBars(
        values: [
          for (final index in displayOrder)
            summary.logsByWeekday[index].toDouble(),
        ],
        color: Theme.of(context).colorScheme.primary,
        highlightedIndexes: [
          for (final (position, index) in displayOrder.indexed)
            if (summary.busiestWeekdayIndexes.contains(index)) position,
        ],
      ),
    );
  }
}
