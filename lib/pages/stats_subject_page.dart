// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/layouts/window_size_class.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/models/tag_icon_type.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/stats/entry_stats.dart';
import 'package:daily_you/stats/stats_analysis.dart';
import 'package:daily_you/stats/stats_range.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/content_width_limit.dart';
import 'package:daily_you/widgets/distribution_chart.dart';
import 'package:daily_you/widgets/label_calendar_card.dart';
import 'package:daily_you/widgets/mood_by_day_chart.dart';
import 'package:daily_you/widgets/mood_summary_chart.dart';
import 'package:daily_you/widgets/mood_tier_mark.dart';
import 'package:daily_you/widgets/stat_headline_card.dart';
import 'package:daily_you/widgets/sliver_stats_range_header.dart';
import 'package:daily_you/widgets/tag_icon_glyph.dart';
import 'package:daily_you/widgets/tag_picker_dialog.dart';
import 'package:daily_you/widgets/trend_chip.dart';
import 'package:daily_you/utils/bucket_combiner.dart';
import 'package:daily_you/utils/chart_y_range.dart';
import 'package:daily_you/utils/count_format.dart';
import 'package:daily_you/utils/tag_visuals.dart';
import 'package:daily_you/widgets/value_by_day_chart.dart';
import 'package:daily_you/widgets/value_over_time_chart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class StatsSubjectPage extends StatefulWidget {
  const StatsSubjectPage({super.key, this.tag});

  final Tag? tag;

  @override
  State<StatsSubjectPage> createState() => _StatsSubjectPageState();
}

class _StatsSubjectPageState extends State<StatsSubjectPage> {
  late int? _tagId = widget.tag?.id;

  @override
  Widget build(BuildContext context) {
    final entriesProvider = Provider.of<EntriesProvider>(context);
    final tagsProvider = Provider.of<TagsProvider>(context);
    final statsRange = context
        .select<ConfigProvider, StatsRange>((config) => config.statsRange);
    final tag = tagsProvider.tags
        .where((candidate) => candidate.id == _tagId)
        .firstOrNull;
    final inputs = (
      allEntries: entriesProvider.entries,
      rangedEntries: entriesInRange(entriesProvider.entries, statsRange),
      range: statsRange,
      tagsProvider: tagsProvider,
    );
    final content = tag == null
        ? _buildMoodContent(context, inputs)
        : tag.tagType == TagType.label
            ? _buildLabelContent(context, inputs, tag)
            : _buildTrackerContent(context, inputs, tag);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: _SubjectTitle(
          tag: tag,
          onTypeSelected: (type) => _onSubjectTypeSelected(context, type),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverStatsRangeHeader(statsRange: statsRange),
          SliverToBoxAdapter(
            child: ContentWidthLimit(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (content.headline case final headline?) headline,
                    ..._arrangeCharts(context, content.charts),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSubjectTypeSelected(
      BuildContext context, _SubjectType type) async {
    if (type == _SubjectType.mood) {
      setState(() => _tagId = null);
      return;
    }
    final tag = await showAppDialog<Tag>(
      context: context,
      builder: (_) => TagPickerDialog(
        mode: TagPickerMode.selectSingle,
        tagTypeFilter:
            type == _SubjectType.label ? TagType.label : TagType.tracker,
      ),
    );
    if (tag == null || !mounted) return;
    setState(() => _tagId = tag.id);
  }

  List<Widget> _arrangeCharts(BuildContext context, List<Widget> charts) {
    if (WindowSizeClass.of(context) != WindowSizeClass.expanded) return charts;
    return [
      charts.first,
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final chart in charts.skip(1)) Expanded(child: chart),
        ],
      ),
    ];
  }

  _SubjectContent _buildMoodContent(
      BuildContext context, _SubjectInputs inputs) {
    final l10n = AppLocalizations.of(context)!;
    final summary = moodSummary(inputs.allEntries, inputs.range);
    final weekdays = moodByWeekday(
      inputs.allEntries,
      inputs.range,
      firstDayIndex: context.select<ConfigProvider, int>(
          (config) => config.getFirstDayOfWeekIndex(context)),
    );
    final hasData = hasEnoughChartData(summary.dayMeans.length);

    return (
      headline: null,
      charts: [
        ValueOverTimeChart(
          dataPoints: summary.dayMeans,
          hasData: hasData,
          yRange: MoodTierMark.axisRange,
          combine: combineByAverage,
          title: l10n.chartOverTimeTitle(l10n.tagMoodTitle),
          buildLeftTitle: MoodTierMark.axisTitle,
        ),
        MoodSummaryChart(
          tierCounts: summary.tierCounts,
          hasData: hasEnoughChartData(summary.moodCount),
        ),
        MoodByDayChart(
          weekdays: weekdays,
          hasData: hasData,
          title: l10n.chartByDayTitle(l10n.tagMoodTitle),
        ),
      ],
    );
  }

  _SubjectContent _buildTrackerContent(
    BuildContext context,
    _SubjectInputs inputs,
    Tag tag,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final locale = l10n.localeName;
    final tagColor = tag.resolvedColor(context);
    final entries = inputs.rangedEntries;
    final tagsProvider = inputs.tagsProvider;
    final summary = trackerSummary(inputs.allEntries, tagsProvider.entryTags,
        tagsProvider.tags, tag.id!, inputs.range);

    final valueByEntryId =
        trackerValuesByEntry(entries, tagsProvider.entryTags, tag.id!);

    final dataPoints = [
      for (final entry in entries)
        if (valueByEntryId[entry.id] case final value?)
          (date: entry.timeCreate, value: value),
    ];
    final rawValues = dataPoints.map((point) => point.value).toList();

    final hasData = hasEnoughChartData(summary.daysLogged);
    final (minY, maxY) = trackerYRange(rawValues);
    final trackerRange = FixedYRange(minY: minY, maxY: maxY);

    return (
      headline: StatHeadlineCard(
        accentColor: tagColor,
        hasData: summary.daysLogged > 0,
        items: [
          StatHeadlineItem(
            label: l10n.statsAverageTitle,
            text: formatDecimal(summary.average ?? 0, locale),
            trend: TrendChip.fromChange(
                summary.trend, (amount) => formatDecimal(amount, locale)),
          ),
          StatHeadlineItem(
            label: l10n.statsHighestTitle,
            text: formatDecimal(summary.highest ?? 0, locale),
          ),
          StatHeadlineItem(
            label: l10n.statsLowestTitle,
            text: formatDecimal(summary.lowest ?? 0, locale),
          ),
          StatHeadlineItem(
            label: l10n.statsDaysLoggedTitle,
            text: formatCount(summary.daysLogged, locale),
          ),
        ],
      ),
      charts: [
        ValueOverTimeChart(
          dataPoints: dataPoints,
          hasData: hasData,
          yRange: trackerRange,
          combine: combineByAverage,
          title: l10n.chartOverTimeTitle(tag.name),
          color: tagColor,
          anchorAtZero: true,
        ),
        DistributionChart(
          values: rawValues,
          hasData: hasData,
          title: l10n.chartDistributionTitle(tag.name),
          color: tagColor,
        ),
        ValueByDayChart(
          averageValues:
              averageByDayOfWeek(entries, (entry) => valueByEntryId[entry.id]),
          hasData: hasData,
          yRange: trackerRange,
          title: l10n.chartByDayTitle(tag.name),
          color: tagColor,
          anchorAtZero: true,
        ),
      ],
    );
  }

  _SubjectContent _buildLabelContent(
    BuildContext context,
    _SubjectInputs inputs,
    Tag tag,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final locale = l10n.localeName;
    final tagColor = tag.resolvedColor(context);
    final entries = inputs.rangedEntries;
    final tagsProvider = inputs.tagsProvider;
    final summary = labelSummary(inputs.allEntries, tagsProvider.entryTags,
        tagsProvider.tags, tag.id!, inputs.range);

    final presentIds = entryIdsWithTag(tagsProvider.entryTags, tag.id!);
    final dayCounts =
        countByDayOfWeek(entries, (entry) => presentIds.contains(entry.id));
    final taggedEntryCount =
        entries.where((entry) => presentIds.contains(entry.id)).length;

    return (
      headline: StatHeadlineCard(
        accentColor: tagColor,
        hasData: summary.daysPresent + summary.daysAbsent > 0,
        items: [
          StatHeadlineItem(
            label: l10n.statsOfDaysLabel,
            text: formatPercent(summary.presentFraction, locale),
            trend: TrendChip.fromChange(summary.trendPoints,
                (points) => formatPercent(points / 100, locale)),
          ),
          StatHeadlineItem(
            label: l10n.labelPresentLabel,
            text: formatCount(summary.daysPresent, locale),
          ),
          StatHeadlineItem(
            label: l10n.labelAbsentLabel,
            text: formatCount(summary.daysAbsent, locale),
          ),
          StatHeadlineItem(
            label: l10n.statsLongestStreakTitle,
            text: formatCount(summary.bestStreak, locale),
          ),
        ],
      ),
      charts: [
        LabelCalendarCard(
          title: l10n.chartOverTimeTitle(tag.name),
          summary: summary,
          color: tagColor,
        ),
        ValueByDayChart(
          averageValues: dayCounts,
          hasData: hasEnoughChartData(taggedEntryCount),
          yRange: const DynamicYRange(),
          title: l10n.chartByDayTitle(tag.name),
          color: tagColor,
        ),
      ],
    );
  }
}

typedef _SubjectInputs = ({
  List<Entry> allEntries,
  List<Entry> rangedEntries,
  StatsRange range,
  TagsProvider tagsProvider,
});

typedef _SubjectContent = ({Widget? headline, List<Widget> charts});

enum _SubjectType { mood, label, tracker }

class _SubjectTitle extends StatelessWidget {
  const _SubjectTitle({required this.tag, required this.onTypeSelected});

  final Tag? tag;
  final ValueChanged<_SubjectType> onTypeSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final secondary = Theme.of(context).colorScheme.secondary;
    final subjectTag = tag;
    final subjectIcon = subjectTag?.typeIcon ?? Icons.mood_rounded;
    final subjectLabel = subjectTag?.name ?? l10n.tagMoodTitle;
    final subjectColor =
        subjectTag?.resolvedColor(context, fallback: secondary) ?? secondary;
    final currentType = switch (subjectTag?.tagType) {
      null => _SubjectType.mood,
      TagType.label => _SubjectType.label,
      TagType.tracker => _SubjectType.tracker,
    };

    return PopupMenuButton<_SubjectType>(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      onSelected: onTypeSelected,
      itemBuilder: (menuContext) => [
        _subjectMenuItem(
          menuContext,
          value: _SubjectType.mood,
          icon: Icons.mood_rounded,
          label: l10n.tagMoodTitle,
          selected: currentType == _SubjectType.mood,
        ),
        _subjectMenuItem(
          menuContext,
          value: _SubjectType.label,
          icon: Icons.label_rounded,
          label: l10n.tagTypeLabelTitle,
          selected: currentType == _SubjectType.label,
        ),
        _subjectMenuItem(
          menuContext,
          value: _SubjectType.tracker,
          icon: Icons.timeline_rounded,
          label: l10n.tagTypeTrackerTitle,
          selected: currentType == _SubjectType.tracker,
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: subjectColor.withValues(alpha: 0.5),
            width: 1.5,
          ),
          color: subjectColor.withValues(alpha: 0.08),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TagIconGlyph(
              icon: subjectTag?.icon,
              iconType: subjectTag?.iconType ?? TagIconType.character,
              fallbackIcon: subjectIcon,
              color: subjectColor,
              size: 16,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                subjectLabel,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.fade,
                style: TextStyle(
                  fontSize: 14,
                  color: subjectColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 18, color: subjectColor),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<_SubjectType> _subjectMenuItem(
    BuildContext context, {
    required _SubjectType value,
    required IconData icon,
    required String label,
    required bool selected,
  }) {
    return PopupMenuItem<_SubjectType>(
      value: value,
      child: Row(children: [
        Icon(Icons.check_rounded,
            size: 18,
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent),
        const SizedBox(width: 8),
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(label),
      ]),
    );
  }
}
