import 'dart:math' as math;
import 'package:daily_you/config_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/utils/bucket_combiner.dart';
import 'package:daily_you/utils/chart_y_range.dart';
import 'package:daily_you/widgets/connected_button_group.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shamsi_date/shamsi_date.dart';

typedef LeftTitleBuilder = Widget Function(double value, TitleMeta meta);

enum ChartGrouping { day, week, month, year }

/// Generic time-series line chart. Accepts pre-computed (date, value) pairs.
/// [yRange] decides how the axis is sized. [combine] decides how values
/// within a bucket collapse into one point.
class ValueOverTimeChart extends StatefulWidget {
  final List<({DateTime date, double value})> dataPoints;
  final bool hasData;
  final ChartYRange yRange;
  final BucketCombiner combine;
  final String title;
  final LeftTitleBuilder? buildLeftTitle;
  final Color? color;
  final bool anchorAtZero;

  const ValueOverTimeChart({
    super.key,
    required this.dataPoints,
    required this.hasData,
    required this.yRange,
    required this.combine,
    required this.title,
    this.buildLeftTitle,
    this.color,
    this.anchorAtZero = false,
  });

  @override
  State<ValueOverTimeChart> createState() => _ValueOverTimeChartState();
}

class _ValueOverTimeChartState extends State<ValueOverTimeChart> {
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
  static const _dummyMin = -1.5;
  static const _dummyMax = 1.7;
  static const _dummyRange = _dummyMax - _dummyMin;

  static const int _monthThreshold = 35;
  static const int _yearThreshold = 366;

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

  static String _groupingToConfigString(ChartGrouping grouping) =>
      switch (grouping) {
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
    final preferred = _preferredGrouping;
    if (preferred == null) return _defaultGrouping(spanDays);
    if (available.contains(preferred)) return preferred;
    const order = [
      ChartGrouping.day,
      ChartGrouping.week,
      ChartGrouping.month,
      ChartGrouping.year
    ];
    final preferredIndex = order.indexOf(preferred);
    for (int index = preferredIndex + 1; index < order.length; index++) {
      if (available.contains(order[index])) return order[index];
    }
    for (int index = preferredIndex - 1; index >= 0; index--) {
      if (available.contains(order[index])) return order[index];
    }
    return available.first;
  }

  String _groupingLabel(ChartGrouping grouping, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (grouping) {
      ChartGrouping.day => l10n.chartGroupingDay,
      ChartGrouping.week => l10n.chartGroupingWeek,
      ChartGrouping.month => l10n.chartGroupingMonth,
      ChartGrouping.year => l10n.chartGroupingYear,
    };
  }

  double _scaleDummy(double value) {
    final preview = widget.yRange.previewRange;
    final range = preview.maxY - preview.minY;
    return preview.minY + ((value - _dummyMin) / _dummyRange) * range;
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

    final yRange = widget.hasData
        ? widget.yRange.resolve(spots.whereType<FlSpot>().map((spot) => spot.y))
        : widget.yRange.previewRange;

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

    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    final surfaceColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2);

    final labelCount = labelDates.length.clamp(1, 6);
    final chartWidget = LayoutBuilder(
      builder: (context, constraints) {
        final maxLabelWidth = ((constraints.maxWidth - 84) / labelCount);
        return Padding(
          padding: const EdgeInsets.only(right: 42, top: 8, bottom: 8),
          child: AspectRatio(
            aspectRatio: 2,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: totalDays,
                minY: yRange.minY,
                maxY: yRange.maxY,
                clipData: const FlClipData.all(),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: widget.hasData
                    ? _buildSegments(spots, color, smoothing, yRange)
                    : [
                        _makeSegment(spots.whereType<FlSpot>().toList(), color,
                            smoothing, yRange)
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
                      interval: yRange.interval,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) =>
                          widget.buildLeftTitle != null
                              ? widget.buildLeftTitle!(value, meta)
                              : _defaultLeftTitle(value, meta),
                    ),
                  ),
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                ),
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  horizontalInterval: yRange.interval,
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
                      widget.title,
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

  Widget _defaultLeftTitle(double value, TitleMeta meta) {
    final formatted = _formatNumericLabel(value);
    return SideTitleWidget(
      meta: meta,
      child: Text(
        formatted,
        style: const TextStyle(fontSize: 11),
        textAlign: TextAlign.right,
      ),
    );
  }

  String _formatNumericLabel(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    if (value.abs() >= 100) return value.toInt().toString();
    if (value.abs() >= 10) return value.toStringAsFixed(1);
    return value
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
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
                                .map((grouping) =>
                                    _groupingLabel(grouping, context))
                                .toList(),
                            selectedIndex: available.indexOf(selected),
                            onSelectionChanged: (index) {
                              final grouping = available[index];
                              setDialogState(() => selected = grouping);
                              ConfigProvider.instance.set(
                                  ConfigKey.moodOverTimeGrouping,
                                  _groupingToConfigString(grouping));
                            },
                          ),
                        ),
                      ],
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.chartSmoothingLabel),
                      value: smoothingValue,
                      onChanged: (value) {
                        setDialogState(() {});
                        ConfigProvider.instance
                            .set(ConfigKey.moodOverTimeSmoothing, value);
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
    final earliest = widget.dataPoints
        .map((point) => point.date)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    return DateTime(earliest.year, earliest.month, earliest.day);
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
    final Map<int, List<double>> bucketValues = {};
    for (final point in widget.dataPoints) {
      int bucketIndex = -1;
      for (int i = buckets.length - 1; i >= 0; i--) {
        if (!buckets[i].isAfter(point.date)) {
          bucketIndex = i;
          break;
        }
      }
      if (bucketIndex < 0) continue;
      (bucketValues[bucketIndex] ??= []).add(point.value);
    }
    return List.generate(buckets.length, (i) {
      final values = bucketValues[i];
      if (values == null || values.isEmpty) return null;
      final x = buckets[i].difference(rangeStart).inDays.toDouble();
      return FlSpot(x, widget.combine(values));
    });
  }

  List<FlSpot?> _dummySpots(List<DateTime> buckets, DateTime rangeStart) {
    return List.generate(buckets.length, (i) {
      final x = buckets[i].difference(rangeStart).inDays.toDouble();
      return FlSpot(x, _scaleDummy(_dummyYValues[i % _dummyYValues.length]));
    });
  }

  List<LineChartBarData> _buildSegments(
      List<FlSpot?> spots, Color color, bool smoothing, ChartRange yRange) {
    final segments = <LineChartBarData>[];
    var run = <FlSpot>[];
    for (final spot in spots) {
      if (spot != null) {
        run.add(spot);
      } else if (run.isNotEmpty) {
        segments.add(_makeSegment(run, color, smoothing, yRange));
        run = [];
      }
    }
    if (run.isNotEmpty) {
      segments.add(_makeSegment(run, color, smoothing, yRange));
    }
    return segments;
  }

  double _zeroFadeStop(double near, double far) {
    final denom = far - near;
    if (denom == 0) return 0.001;
    return ((0 - near) / denom).clamp(0.001, 1.0);
  }

  LineChartBarData _makeSegment(
      List<FlSpot> spots, Color color, bool smoothing, ChartRange yRange) {
    final anchorAtZero = widget.anchorAtZero;

    if (!anchorAtZero) {
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

    final maxSpotY = spots.map((s) => s.y).reduce(math.max);
    final minSpotY = spots.map((s) => s.y).reduce(math.min);
    final belowFadeStop = _zeroFadeStop(maxSpotY, yRange.minY);
    final aboveFadeStop = _zeroFadeStop(minSpotY, yRange.maxY);

    return LineChartBarData(
      spots: spots,
      isCurved: smoothing,
      color: color,
      barWidth: 4,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        applyCutOffY: true,
        cutOffY: 0,
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.35),
            color.withValues(alpha: 0.0),
          ],
          stops: [0.0, belowFadeStop],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      aboveBarData: BarAreaData(
        show: true,
        applyCutOffY: true,
        cutOffY: 0,
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.35),
            color.withValues(alpha: 0.0),
          ],
          stops: [0.0, aboveFadeStop],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
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
