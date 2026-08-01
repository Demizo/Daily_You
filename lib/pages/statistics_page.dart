import 'dart:math' as math;
import 'package:daily_you/config_provider.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/stats_subject.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/models/tag_icon_type.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/widgets/distribution_chart.dart';
import 'package:daily_you/widgets/label_summary_card.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:daily_you/widgets/mood_summary_chart.dart';
import 'package:daily_you/widgets/stat_range_selector.dart';
import 'package:daily_you/widgets/stats_overview_card.dart';
import 'package:daily_you/widgets/tag_icon_glyph.dart';
import 'package:daily_you/widgets/tag_picker_dialog.dart';
import 'package:daily_you/utils/bucket_combiner.dart';
import 'package:daily_you/utils/chart_y_range.dart';
import 'package:daily_you/utils/tag_visuals.dart';
import 'package:daily_you/widgets/value_by_day_chart.dart';
import 'package:daily_you/widgets/value_over_time_chart.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage>
    with AutomaticKeepAliveClientMixin {
  late StatsRange statsRange;
  late String _subjectConfig;

  // Header height calculated based on an offstage copy
  double _headerHeight = 98.0;
  final GlobalKey _headerMeasureKey = GlobalKey();

  static const _rangeToString = {
    StatsRange.month: 'month',
    StatsRange.sixMonths: 'sixMonths',
    StatsRange.year: 'year',
    StatsRange.allTime: 'allTime',
  };

  static const _stringToRange = {
    'month': StatsRange.month,
    'sixMonths': StatsRange.sixMonths,
    'year': StatsRange.year,
    'allTime': StatsRange.allTime,
  };

  @override
  void initState() {
    super.initState();
    final saved = ConfigProvider.instance.get(ConfigKey.statsRange) as String?;
    statsRange = _stringToRange[saved] ?? StatsRange.allTime;
    _subjectConfig =
        ConfigProvider.instance.get(ConfigKey.statsSubject) as String? ??
            'mood';
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Recalculate header height when text size changes
    MediaQuery.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeaderHeight());
    return buildPage(context);
  }

  void _measureHeaderHeight() {
    if (!mounted) return;
    final renderBox =
        _headerMeasureKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;
    final measuredHeight = renderBox.size.height;
    if ((measuredHeight - _headerHeight).abs() > 0.5) {
      setState(() => _headerHeight = measuredHeight);
    }
  }

  Widget buildPage(BuildContext context) {
    final entriesProvider = Provider.of<EntriesProvider>(context);
    final tagsProvider = Provider.of<TagsProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    final subject =
        StatsSubject.fromConfigString(_subjectConfig, tagsProvider.tags);
    final entriesInRange = entriesProvider.getEntriesInRange(statsRange);
    final (currentStreak, longestStreak, daysSinceBadDay) =
        entriesProvider.getStreaks();

    final logCount = entriesProvider.entries.length;
    final entryDayCount = entriesProvider.getEntryDayCount();
    final greatDayCount = _getGreatDayCount(entriesProvider.entries);

    final primaryStreakItem = logCount > 0
        ? StatItem(
            icon: Icons.bolt,
            title: l10n.streakCurrent(currentStreak),
          )
        : null;

    final streakSideItems = <StatItem>[
      if (longestStreak > 0)
        StatItem(
          icon: Icons.history_rounded,
          title: l10n.streakLongest(longestStreak),
        ),
      if (logCount > 0)
        StatItem(
          icon: Icons.mood_rounded,
          title: l10n.streakGreatDays(greatDayCount),
        ),
      if (daysSinceBadDay != null && daysSinceBadDay > 3)
        StatItem(
          icon: Icons.timeline_rounded,
          title: l10n.streakSinceBadDay(daysSinceBadDay),
        ),
    ];

    final writingItems = <StatItem>[
      if (logCount > 0)
        StatItem(
          icon: Icons.description_outlined,
          title: l10n.logCount(logCount),
        ),
      if (entryDayCount > 0 && entryDayCount != logCount)
        StatItem(
          icon: Icons.today_rounded,
          title: l10n.dayCount(entryDayCount),
        ),
      if (entriesProvider.wordCount > 100)
        StatItem(
          icon: Icons.sort_rounded,
          title: l10n.wordCount(entriesProvider.wordCount),
        ),
    ];

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            if (primaryStreakItem != null || writingItems.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: StatsOverviewCard(
                    primary: primaryStreakItem,
                    sideItems: streakSideItems,
                    writingItems: writingItems,
                  ),
                ),
              ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _HeaderDelegate(
                statsRange: statsRange,
                subject: subject,
                height: _headerHeight,
                onRangeChanged: (newRange) {
                  setState(() => statsRange = newRange);
                  ConfigProvider.instance
                      .set(ConfigKey.statsRange, _rangeToString[newRange]);
                },
                onSubjectTypeSelected: (type) =>
                    _onSubjectTypeSelected(context, type),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._buildChartsForSubject(
                        context, subject, entriesInRange, tagsProvider),
                    const SizedBox(height: 8.0),
                  ],
                ),
              ),
            ),
          ],
        ),

        // An offstage copy of the header content, so _measureHeaderHeight can read its
        // natural size.
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: Offstage(
            offstage: true,
            child: _HeaderContent(
              key: _headerMeasureKey,
              statsRange: statsRange,
              subject: subject,
              onRangeChanged: (_) {},
              onSubjectTypeSelected: (_) {},
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onSubjectTypeSelected(BuildContext context, String type) async {
    if (type == 'mood') {
      _applySubject(const MoodSubject());
      return;
    }
    final tag = await showDialog<Tag>(
      context: context,
      builder: (_) => TagPickerDialog(
        mode: TagPickerMode.selectSingle,
        tagTypeFilter: type == 'label' ? TagType.label : TagType.tracker,
      ),
    );
    if (tag == null) return; // cancelled, leave current subject untouched
    _applySubject(type == 'label' ? LabelSubject(tag) : TrackerSubject(tag));
  }

  void _applySubject(StatsSubject subject) {
    setState(() => _subjectConfig = subject.toConfigString());
    ConfigProvider.instance.set(ConfigKey.statsSubject, _subjectConfig);
  }

  List<Widget> _buildChartsForSubject(
    BuildContext context,
    StatsSubject subject,
    List<Entry> entries,
    TagsProvider tagsProvider,
  ) {
    return switch (subject) {
      MoodSubject() => _buildMoodCharts(context, entries),
      TrackerSubject(tag: final tag) =>
        _buildTrackerCharts(context, entries, tagsProvider, tag),
      LabelSubject(tag: final tag) =>
        _buildLabelCharts(context, entries, tagsProvider, tag),
    };
  }

  static const _moodRange = FixedYRange(minY: -2, maxY: 2, interval: 1);

  List<Widget> _buildMoodCharts(BuildContext context, List<Entry> entries) {
    final l10n = AppLocalizations.of(context)!;
    final moodPoints = entries
        .where((entry) => entry.mood != null)
        .map((entry) => (date: entry.timeCreate, value: entry.mood!.toDouble()))
        .toList();
    final moodTotals = _getMoodTotals(entries);
    final hasData = moodPoints.length > 1;

    return [
      ValueOverTimeChart(
        dataPoints: moodPoints,
        hasData: hasData,
        yRange: _moodRange,
        combine: combineByAverage,
        title: l10n.chartOverTimeTitle(l10n.tagMoodTitle),
        buildLeftTitle: (value, meta) => SideTitleWidget(
          meta: meta,
          child: MoodIcon(moodValue: value.toInt(), allowScaling: false),
        ),
      ),
      MoodSummaryChart(
        moodCounts: moodTotals,
        hasData: hasData,
      ),
      ValueByDayChart(
        averageValues: _averageByDayOfWeek(
            entries, (entry) => entry.mood?.toDouble(),
            emptyDayValue: -2),
        hasData: hasData,
        yRange: _moodRange,
        title: l10n.chartByDayTitle(l10n.tagMoodTitle),
        buildLeftTitle: (value, meta) => SideTitleWidget(
          meta: meta,
          child: MoodIcon(moodValue: value.toInt(), allowScaling: false),
        ),
      ),
    ];
  }

  List<Widget> _buildTrackerCharts(
    BuildContext context,
    List<Entry> entries,
    TagsProvider tagsProvider,
    Tag tag,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final tagColor = tag.resolvedColor(context);

    final entryIds = entries.map((entry) => entry.id).toSet();
    final valueByEntryId = <int, double>{};
    for (final entryTag in tagsProvider.entryTags) {
      if (entryTag.tagId != tag.id) continue;
      if (!entryIds.contains(entryTag.entryId)) continue;
      final value = double.tryParse(entryTag.value ?? '');
      if (value == null) continue;
      valueByEntryId[entryTag.entryId] = value;
    }

    final dataPoints = [
      for (final entry in entries)
        if (valueByEntryId[entry.id] case final value?)
          (date: entry.timeCreate, value: value),
    ];
    final rawValues = dataPoints.map((point) => point.value).toList();

    final hasData = dataPoints.length > 1;
    final (minY, maxY) = _computeTrackerYRange(rawValues);
    final trackerRange = FixedYRange(minY: minY, maxY: maxY);

    return [
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
        title: l10n.chartDistributionTitle(tag.name),
        color: tagColor,
      ),
      ValueByDayChart(
        averageValues:
            _averageByDayOfWeek(entries, (entry) => valueByEntryId[entry.id]),
        hasData: hasData,
        yRange: trackerRange,
        title: l10n.chartByDayTitle(tag.name),
        color: tagColor,
        anchorAtZero: true,
      ),
    ];
  }

  List<Widget> _buildLabelCharts(
    BuildContext context,
    List<Entry> entries,
    TagsProvider tagsProvider,
    Tag tag,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final tagColor = tag.resolvedColor(context);

    final presentIds = tagsProvider.entryTags
        .where((entryTag) => entryTag.tagId == tag.id)
        .map((entryTag) => entryTag.entryId)
        .toSet();

    final presentCount =
        entries.where((entry) => presentIds.contains(entry.id)).length;
    final totalCount = entries.length;

    final coveragePoints = entries
        .map((entry) => (
              date: entry.timeCreate,
              value: presentIds.contains(entry.id) ? 1.0 : 0.0,
            ))
        .toList();

    final dayCounts =
        _countByDayOfWeek(entries, (entry) => presentIds.contains(entry.id));

    return [
      ValueOverTimeChart(
        dataPoints: coveragePoints,
        hasData: entries.isNotEmpty,
        yRange: const DynamicYRange(),
        combine: combineBySum,
        title: l10n.chartOverTimeTitle(tag.name),
        color: tagColor,
      ),
      LabelSummaryCard(
        tag: tag,
        presentCount: presentCount,
        totalCount: totalCount,
      ),
      ValueByDayChart(
        averageValues: dayCounts,
        hasData: entries.isNotEmpty,
        yRange: const DynamicYRange(),
        title: l10n.chartByDayTitle(tag.name),
        color: tagColor,
      ),
    ];
  }

  static const List<String> _weekdayKeys = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static int _getGreatDayCount(List<Entry> entries) {
    final greatDays = <DateTime>{};
    for (final entry in entries) {
      if (entry.mood == null || entry.mood! < 1) continue;
      final date = entry.timeCreate;
      greatDays.add(DateTime(date.year, date.month, date.day));
    }
    return greatDays.length;
  }

  static Map<int, int> _getMoodTotals(List<Entry> entries) {
    final moodTotals = {-2: 0, -1: 0, 0: 0, 1: 0, 2: 0};
    for (final entry in entries) {
      if (entry.mood == null) continue;
      moodTotals.update(entry.mood!, (count) => count + 1);
    }
    return moodTotals;
  }

  // Averages [valueOf] per weekday across [entries]. A weekday with no
  // contributing entries resolves to [emptyDayValue] (null by default) so
  // charts can tell "no data that day" apart from a genuine zero average.
  static Map<String, double?> _averageByDayOfWeek(
    List<Entry> entries,
    double? Function(Entry entry) valueOf, {
    double? emptyDayValue,
  }) {
    final valuesByDay = <String, List<double>>{};
    for (final entry in entries) {
      final value = valueOf(entry);
      if (value == null) continue;
      final dayKey = DateFormat('EEE', 'en').format(entry.timeCreate);
      (valuesByDay[dayKey] ??= []).add(value);
    }

    double? average(String dayKey) {
      final values = valuesByDay[dayKey];
      if (values == null || values.isEmpty) return emptyDayValue;
      return values.reduce((a, b) => a + b) / values.length;
    }

    return {for (final dayKey in _weekdayKeys) dayKey: average(dayKey)};
  }

  // Counts entries matching [matches] per weekday across [entries].
  static Map<String, double> _countByDayOfWeek(
    List<Entry> entries,
    bool Function(Entry entry) matches,
  ) {
    final counts = {for (final dayKey in _weekdayKeys) dayKey: 0};
    for (final entry in entries) {
      if (!matches(entry)) continue;
      final dayKey = DateFormat('EEE', 'en').format(entry.timeCreate);
      counts[dayKey] = (counts[dayKey] ?? 0) + 1;
    }
    return counts.map((key, value) => MapEntry(key, value.toDouble()));
  }

  static (double minY, double maxY) _computeTrackerYRange(List<double> values) {
    if (values.isEmpty) return (0, 10);
    final dataMin = values.reduce(math.min);
    final dataMax = values.reduce(math.max);
    return (dataMin >= 0 ? 0 : dataMin, dataMax);
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  final StatsRange statsRange;
  final StatsSubject subject;
  final double height;
  final ValueChanged<StatsRange> onRangeChanged;
  final ValueChanged<String> onSubjectTypeSelected;

  const _HeaderDelegate({
    required this.statsRange,
    required this.subject,
    required this.height,
    required this.onRangeChanged,
    required this.onSubjectTypeSelected,
  });

  static const double _fadeHeight = 8.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    // Wrapped in align to avoid painting size issue https://github.com/flutter/flutter/issues/78748
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      backgroundColor,
                      backgroundColor,
                      backgroundColor.withValues(alpha: 0.0),
                    ],
                    stops: [
                      0.0,
                      (height - _fadeHeight) / height,
                      1.0,
                    ],
                  ),
                ),
              ),
            ),
            _HeaderContent(
              statsRange: statsRange,
              subject: subject,
              onRangeChanged: onRangeChanged,
              onSubjectTypeSelected: onSubjectTypeSelected,
            ),
          ],
        ),
      ),
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _HeaderDelegate oldDelegate) =>
      oldDelegate.statsRange != statsRange ||
      oldDelegate.subject.toConfigString() != subject.toConfigString() ||
      oldDelegate.height != height;
}

class _HeaderContent extends StatelessWidget {
  final StatsRange statsRange;
  final StatsSubject subject;
  final ValueChanged<StatsRange> onRangeChanged;
  final ValueChanged<String> onSubjectTypeSelected;

  const _HeaderContent({
    super.key,
    required this.statsRange,
    required this.subject,
    required this.onRangeChanged,
    required this.onSubjectTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final secondary = Theme.of(context).colorScheme.secondary;

    final (subjectIcon, subjectLabel, subjectColor) = switch (subject) {
      MoodSubject() => (
          Icons.mood_rounded,
          l10n.tagMoodTitle,
          secondary,
        ),
      LabelSubject(tag: final t) => (
          t.typeIcon,
          t.name,
          t.resolvedColor(context, fallback: secondary),
        ),
      TrackerSubject(tag: final t) => (
          t.typeIcon,
          t.name,
          t.resolvedColor(context, fallback: secondary),
        ),
    };

    final currentType = switch (subject) {
      MoodSubject() => 'mood',
      LabelSubject() => 'label',
      TrackerSubject() => 'tracker',
    };

    final subjectTag = switch (subject) {
      LabelSubject(tag: final t) => t,
      TrackerSubject(tag: final t) => t,
      MoodSubject() => null,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 6),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: onSubjectTypeSelected,
            itemBuilder: (menuContext) => [
              _subjectMenuItem(
                menuContext,
                value: 'mood',
                icon: Icons.mood_rounded,
                label: l10n.tagMoodTitle,
                selected: currentType == 'mood',
              ),
              _subjectMenuItem(
                menuContext,
                value: 'label',
                icon: Icons.label_rounded,
                label: l10n.tagTypeLabelTitle,
                selected: currentType == 'label',
              ),
              _subjectMenuItem(
                menuContext,
                value: 'tracker',
                icon: Icons.timeline_rounded,
                label: l10n.tagTypeTrackerTitle,
                selected: currentType == 'tracker',
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
          ),
          const SizedBox(height: 6),
          StatsRangeSelector(
            statsRange: statsRange,
            onSelectionChanged: onRangeChanged,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  PopupMenuItem<String> _subjectMenuItem(
    BuildContext context, {
    required String value,
    required IconData icon,
    required String label,
    required bool selected,
  }) {
    return PopupMenuItem<String>(
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
