import 'package:daily_you/config_provider.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/connected_button_group.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shamsi_date/shamsi_date.dart';

enum ChartGrouping { day, week, month, year }

class MoodOverTimeChart extends StatefulWidget {
  final List<Entry> entries;
  final bool hasData;

  const MoodOverTimeChart({
    super.key,
    required this.entries,
    required this.hasData,
  });

  @override
  State<MoodOverTimeChart> createState() => _MoodOverTimeChartState();
}

class _MoodOverTimeChartState extends State<MoodOverTimeChart> {
  static const _dummyYValues = [
    -0.5,
    -0.4,
    0.0,
    0.3,
    -0.6,
    0.1,
    0.6,
    1.2,
    1.3,
    0.6,
    0.4,
    0.4,
    0.7,
    0.8,
    0.4,
    0.2,
    -0.5,
    -0.8,
    -1.5,
    -1.0,
    -0.3,
    0.0,
    0.2,
    0.2,
    0.5,
    0.5,
    0.7,
    0.8,
    0.9,
    0.8,
    0.6,
    0.9,
    1.2,
    1.3,
    1.2,
    1.2,
    1.3,
    1.5,
    1.0,
    1.4,
    1.7,
  ];

  static const int _monthThreshold = 35; // Catches 31-day months easily
  static const int _yearThreshold = 366; // Catches leap years

  ChartGrouping? get _preferredGrouping {
    final value = ConfigProvider.instance.get(ConfigKey.moodOverTimeGrouping);
    return switch (value) {
      'day' => ChartGrouping.day,
      'week' => ChartGrouping.week,
      'month' => ChartGrouping.month,
      'year' => ChartGrouping.year,
      _ => null,
    };
  }

  bool get _smoothing =>
      ConfigProvider.instance.get(ConfigKey.moodOverTimeSmoothing) ?? true;

  static String _groupingToConfigString(ChartGrouping g) => switch (g) {
        ChartGrouping.day => 'day',
        ChartGrouping.week => 'week',
        ChartGrouping.month => 'month',
        ChartGrouping.year => 'year',
      };

  List<ChartGrouping> _availableGroupings(int spanDays) {
    if (spanDays <= _monthThreshold) {
      return [ChartGrouping.day, ChartGrouping.week];
    }
    if (spanDays <= _yearThreshold) {
      return [ChartGrouping.week, ChartGrouping.month];
    }
    if (spanDays <= 2 * _yearThreshold) {
      return [ChartGrouping.week, ChartGrouping.month];
    }
    return [ChartGrouping.month, ChartGrouping.year];
  }

  ChartGrouping _defaultGrouping(int spanDays) =>
      spanDays <= _yearThreshold ? ChartGrouping.week : ChartGrouping.month;

  ChartGrouping _effectiveGrouping(int spanDays) {
    final available = _availableGroupings(spanDays);
    final pref = _preferredGrouping;
    if (pref == null) return _defaultGrouping(spanDays);
    if (available.contains(pref)) return pref;
    // Clamp to nearest available grouping (prefer coarser to match why it was unavailable)
    const order = [
      ChartGrouping.day,
      ChartGrouping.week,
      ChartGrouping.month,
      ChartGrouping.year
    ];
    final idx = order.indexOf(pref);
    for (int i = idx + 1; i < order.length; i++) {
      if (available.contains(order[i])) return order[i];
    }
    for (int i = idx - 1; i >= 0; i--) {
      if (available.contains(order[i])) return order[i];
    }
    return available.first;
  }

  String _groupingLabel(ChartGrouping g, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (g) {
      ChartGrouping.day => l10n.chartGroupingDay,
      ChartGrouping.week => l10n.chartGroupingWeek,
      ChartGrouping.month => l10n.chartGroupingMonth,
      ChartGrouping.year => l10n.chartGroupingYear,
    };
  }

  @override
  Widget build(BuildContext context) {
    final _ = context.watch<ConfigProvider>();

    final isJalali = TimeManager.isJalaliCalendar(context);
    final today = DateTime.now();
    final rangeEnd = DateTime(today.year, today.month, today.day, 23, 59, 59);
    final rangeStart =
        widget.hasData ? _dataRangeStart() : _dummyRangeStart(today, isJalali);

    final totalDays = rangeEnd.difference(rangeStart).inDays.toDouble();
    final spanDays = totalDays.toInt().clamp(1, 999999);
    final available = _availableGroupings(spanDays);
    final effective = _effectiveGrouping(spanDays);
    final smoothing = _smoothing;

    final buckets = switch (effective) {
      ChartGrouping.day => _generateDailyBuckets(rangeStart, rangeEnd),
      ChartGrouping.week => _generateWeeklyBuckets(rangeStart, rangeEnd),
      ChartGrouping.month =>
        _generateMonthlyBuckets(rangeStart, rangeEnd, isJalali: isJalali),
      ChartGrouping.year =>
        _generateYearlyBuckets(rangeStart, rangeEnd, isJalali: isJalali),
    };

    if (buckets.isEmpty) return const SizedBox.shrink();

    final spots = widget.hasData
        ? _computeSpots(buckets, rangeStart)
        : _dummySpots(buckets, rangeStart);

    final markerDates =
        _computeMarkerDates(rangeStart, rangeEnd, spanDays, isJalali);
    final labelDates = _computeLabelDates(markerDates, spanDays, isJalali);

    final labelTextMap = <int, String>{
      for (final d in labelDates)
        d.difference(rangeStart).inDays: _formatLabel(d, spanDays, context),
    };
    final markerDayOffsets = markerDates
        .map((d) => d.difference(rangeStart).inDays.toDouble())
        .toList();

    final color = Theme.of(context).colorScheme.primary;
    final surfaceColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2);

    final labelCount = labelDates.length.clamp(1, 6);
    final chartWidget = LayoutBuilder(
      builder: (context, constraints) {
        // Plot area = total width minus right padding (42) and left axis (42).
        final maxLabelWidth = ((constraints.maxWidth - 84) / labelCount);
        return Padding(
          padding: const EdgeInsets.only(right: 42, top: 8),
          child: AspectRatio(
            aspectRatio: 2,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: totalDays,
                minY: -2,
                maxY: 2,
                clipData: const FlClipData.all(),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: widget.hasData
                    ? _buildSegments(spots, color, smoothing)
                    : [
                        _makeSegment(spots.whereType<FlSpot>().toList(), color,
                            smoothing)
                      ],
                extraLinesData: ExtraLinesData(
                  verticalLines: markerDayOffsets
                      .map((x) => VerticalLine(
                            x: x,
                            color: surfaceColor,
                            strokeWidth: 1,
                          ))
                      .toList(),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 32,
                      getTitlesWidget: (value, _) {
                        final label = labelTextMap[value.toInt()];
                        if (label != null) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: SizedBox(
                              width: maxLabelWidth,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  label,
                                  textScaler: TextScaler.noScaling,
                                ),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) => SideTitleWidget(
                        meta: meta,
                        child: MoodIcon(
                          moodValue: value.toInt(),
                          allowScaling: false,
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                ),
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  horizontalInterval: 1,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: surfaceColor, strokeWidth: 1),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.symmetric(
                    horizontal: BorderSide(color: surfaceColor, width: 1),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    return Card.filled(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4.0, right: 4.0),
            child: Row(
              children: [
                const SizedBox(width: 48),
                Expanded(
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)!.chartOverTimeTitle(
                          AppLocalizations.of(context)!.tagMoodTitle),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.tune, size: 20),
                  tooltip: AppLocalizations.of(context)!.chartGroupingLabel,
                  onPressed: () =>
                      _showGroupingDialog(context, available, effective),
                ),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: widget.hasData ? 1.0 : 0.3,
                child: Center(child: chartWidget),
              ),
              if (!widget.hasData)
                Text(
                  AppLocalizations.of(context)!.statisticsNotEnoughData,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).disabledColor,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showGroupingDialog(BuildContext context, List<ChartGrouping> available,
      ChartGrouping effective) {
    var selected = effective;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final l10n = AppLocalizations.of(context)!;
          final smoothingValue = _smoothing;
          final screenWidth = MediaQuery.of(context).size.width;
          final dialogWidth = (screenWidth - 80).clamp(240.0, 360.0);
          return Dialog(
            child: SizedBox(
              width: dialogWidth,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(l10n.chartGroupingLabel,
                            style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ConnectedButtonGroup(
                            mainAxisAlignment: MainAxisAlignment.end,
                            labels: available
                                .map((g) => _groupingLabel(g, context))
                                .toList(),
                            selectedIndex: available.indexOf(selected),
                            onSelectionChanged: (i) {
                              final g = available[i];
                              setDialogState(() => selected = g);
                              ConfigProvider.instance.set(
                                  ConfigKey.moodOverTimeGrouping,
                                  _groupingToConfigString(g));
                            },
                          ),
                        ),
                      ],
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.chartSmoothingLabel),
                      value: smoothingValue,
                      onChanged: (v) {
                        setDialogState(() {});
                        ConfigProvider.instance
                            .set(ConfigKey.moodOverTimeSmoothing, v);
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: Text(MaterialLocalizations.of(context)
                              .closeButtonLabel),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  DateTime _dataRangeStart() {
    return widget.entries
        .where((e) => e.mood != null)
        .map((e) => e.timeCreate)
        .reduce((a, b) => a.isBefore(b) ? a : b)
        .let((d) => DateTime(d.year, d.month, d.day));
  }

  DateTime _dummyRangeStart(DateTime today, bool isJalali) {
    if (isJalali) {
      final j = Jalali.fromDateTime(today);
      final prev = Jalali(j.year - 1, j.month, j.day);
      final dt = prev.toDateTime();
      return DateTime(dt.year, dt.month, dt.day);
    }
    return DateTime(today.year, today.month - 12, today.day);
  }

  List<DateTime> _generateDailyBuckets(DateTime start, DateTime end) {
    final buckets = <DateTime>[];
    DateTime current = DateTime(start.year, start.month, start.day);
    while (!current.isAfter(end)) {
      buckets.add(current);
      current = current.add(const Duration(days: 1));
    }
    return buckets;
  }

  List<DateTime> _generateWeeklyBuckets(DateTime start, DateTime end) {
    final buckets = <DateTime>[];
    DateTime current = DateTime(start.year, start.month, start.day);
    while (!current.isAfter(end)) {
      buckets.add(current);
      current = current.add(const Duration(days: 7));
    }
    return buckets;
  }

  List<DateTime> _generateMonthlyBuckets(DateTime start, DateTime end,
      {bool isJalali = false}) {
    final buckets = <DateTime>[];
    if (isJalali) {
      final jStart = Jalali.fromDateTime(start);
      Jalali current = Jalali(jStart.year, jStart.month, 1);
      while (!current.toDateTime().isAfter(end)) {
        buckets.add(current.toDateTime());
        int m = current.month + 1, y = current.year;
        if (m > 12) {
          m = 1;
          y++;
        }
        current = Jalali(y, m, 1);
      }
      return buckets;
    }
    DateTime current = DateTime(start.year, start.month, 1);
    while (!current.isAfter(end)) {
      buckets.add(current);
      current = DateTime(current.year, current.month + 1, 1);
    }
    return buckets;
  }

  List<DateTime> _generateYearlyBuckets(DateTime start, DateTime end,
      {bool isJalali = false}) {
    final buckets = <DateTime>[];
    if (isJalali) {
      final jStart = Jalali.fromDateTime(start);
      Jalali current = Jalali(jStart.year, 1, 1);
      while (!current.toDateTime().isAfter(end)) {
        buckets.add(current.toDateTime());
        current = Jalali(current.year + 1, 1, 1);
      }
      return buckets;
    }
    DateTime current = DateTime(start.year, 1, 1);
    while (!current.isAfter(end)) {
      buckets.add(current);
      current = DateTime(current.year + 1, 1, 1);
    }
    return buckets;
  }

  List<FlSpot?> _computeSpots(List<DateTime> buckets, DateTime rangeStart) {
    final Map<int, List<double>> bucketMoods = {};

    for (final entry in widget.entries) {
      if (entry.mood == null) continue;
      final entryDate = entry.timeCreate;
      int bucketIndex = -1;
      for (int i = buckets.length - 1; i >= 0; i--) {
        if (!buckets[i].isAfter(entryDate)) {
          bucketIndex = i;
          break;
        }
      }
      if (bucketIndex < 0) continue;
      (bucketMoods[bucketIndex] ??= []).add(entry.mood!.toDouble());
    }

    return List.generate(buckets.length, (i) {
      final moods = bucketMoods[i];
      if (moods == null || moods.isEmpty) return null;
      final x = buckets[i].difference(rangeStart).inDays.toDouble();
      return FlSpot(x, moods.reduce((a, b) => a + b) / moods.length);
    });
  }

  List<FlSpot?> _dummySpots(List<DateTime> buckets, DateTime rangeStart) {
    return List.generate(
      buckets.length,
      (i) {
        final x = buckets[i].difference(rangeStart).inDays.toDouble();
        return FlSpot(x, _dummyYValues[i % _dummyYValues.length]);
      },
    );
  }

  List<LineChartBarData> _buildSegments(
      List<FlSpot?> spots, Color color, bool smoothing) {
    final segments = <LineChartBarData>[];
    var run = <FlSpot>[];
    for (final spot in spots) {
      if (spot != null) {
        run.add(spot);
      } else if (run.isNotEmpty) {
        segments.add(_makeSegment(run, color, smoothing));
        run = [];
      }
    }
    if (run.isNotEmpty) segments.add(_makeSegment(run, color, smoothing));
    return segments;
  }

  LineChartBarData _makeSegment(
      List<FlSpot> spots, Color color, bool smoothing) {
    return LineChartBarData(
      spots: spots,
      isCurved: smoothing,
      color: color,
      barWidth: 4,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.35),
            color.withValues(alpha: 0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  List<DateTime> _computeMarkerDates(
      DateTime rangeStart, DateTime rangeEnd, int spanDays, bool isJalali) {
    final markers = <DateTime>[];
    if (spanDays <= _monthThreshold) {
      DateTime current = rangeStart;
      while (!current.isAfter(rangeEnd)) {
        markers.add(current);
        current = current.add(const Duration(days: 7));
      }
    } else if (spanDays <= _yearThreshold) {
      if (isJalali) {
        final jStart = Jalali.fromDateTime(rangeStart);
        Jalali current = Jalali(jStart.year, jStart.month, 1);
        while (!current.toDateTime().isAfter(rangeEnd)) {
          final dt = current.toDateTime();
          if (!dt.isBefore(rangeStart)) markers.add(dt);
          int m = current.month + 1, y = current.year;
          if (m > 12) {
            m = 1;
            y++;
          }
          current = Jalali(y, m, 1);
        }
      } else {
        DateTime current = DateTime(rangeStart.year, rangeStart.month, 1);
        while (!current.isAfter(rangeEnd)) {
          if (!current.isBefore(rangeStart)) markers.add(current);
          current = DateTime(current.year, current.month + 1, 1);
        }
      }
    } else {
      // Quarterly markers for both the 1-3 year and >3 year ranges
      if (isJalali) {
        final jStart = Jalali.fromDateTime(rangeStart);
        final jEnd = Jalali.fromDateTime(rangeEnd);
        for (int year = jStart.year; year <= jEnd.year + 1; year++) {
          for (final month in [1, 4, 7, 10]) {
            final dt = Jalali(year, month, 1).toDateTime();
            if (!dt.isBefore(rangeStart) && !dt.isAfter(rangeEnd)) {
              markers.add(dt);
            }
          }
        }
      } else {
        for (int year = rangeStart.year; year <= rangeEnd.year + 1; year++) {
          for (final month in [1, 4, 7, 10]) {
            final d = DateTime(year, month, 1);
            if (!d.isBefore(rangeStart) && !d.isAfter(rangeEnd)) {
              markers.add(d);
            }
          }
        }
      }
    }
    return markers;
  }

  List<DateTime> _computeLabelDates(
      List<DateTime> markerDates, int spanDays, bool isJalali) {
    if (spanDays > 3 * _yearThreshold) {
      // Only label year starts for very long ranges
      if (isJalali) {
        return markerDates
            .where((d) => Jalali.fromDateTime(d).month == 1)
            .toList();
      }
      return markerDates.where((d) => d.month == 1).toList();
    }
    if (markerDates.length <= 6) return List.from(markerDates);
    final result = <DateTime>[];
    final step = (markerDates.length / 6).ceil();
    for (int i = 0; i < markerDates.length; i += step) {
      result.add(markerDates[i]);
    }
    return result;
  }

  String _formatLabel(DateTime date, int spanDays, BuildContext context) {
    final locale = TimeManager.currentLocale(context);
    if (TimeManager.isJalaliCalendar(context)) {
      final j = Jalali.fromDateTime(date);
      final monthName = TimeManager.jalaliMonthName(j.month, locale);
      if (spanDays <= _monthThreshold) {
        return '${j.formatter.d} $monthName';
      } else if (spanDays <= _yearThreshold) {
        return monthName;
      } else if (spanDays < 3 * _yearThreshold) {
        return "$monthName '${j.formatter.yyyy.substring(2)}";
      } else {
        return j.formatter.yyyy;
      }
    }
    if (spanDays <= _monthThreshold) {
      return DateFormat('MMM d', locale).format(date);
    } else if (spanDays <= _yearThreshold) {
      return DateFormat('MMM', locale).format(date);
    } else if (spanDays < 3 * _yearThreshold) {
      return DateFormat("MMM ''yy", locale).format(date);
    } else {
      return DateFormat('yyyy', locale).format(date);
    }
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T) block) => block(this);
}
