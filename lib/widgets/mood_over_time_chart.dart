import 'package:daily_you/models/entry.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class MoodOverTimeChart extends StatelessWidget {
  final List<Entry> entries;
  final bool hasData;

  const MoodOverTimeChart({
    super.key,
    required this.entries,
    required this.hasData,
  });

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

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final rangeEnd = DateTime(today.year, today.month, today.day, 23, 59, 59);
    final rangeStart = hasData ? _dataRangeStart() : _dummyRangeStart(today);

    final totalDays = rangeEnd.difference(rangeStart).inDays.toDouble();
    final spanDays = totalDays.toInt().clamp(1, 999999);
    final useWeekly = spanDays <= 365;

    final buckets = useWeekly
        ? _generateWeeklyBuckets(rangeStart, rangeEnd)
        : _generateMonthlyBuckets(rangeStart, rangeEnd);

    if (buckets.isEmpty) return const SizedBox.shrink();

    final spots = hasData
        ? _computeSpots(buckets, rangeStart)
        : _dummySpots(buckets, rangeStart);

    final markerDates = _computeMarkerDates(rangeStart, rangeEnd, spanDays);
    final labelDates = _computeLabelDates(markerDates, spanDays);

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

    final chartWidget = Padding(
      padding: const EdgeInsets.only(right: 42, top: 8),
      child: AspectRatio(
        aspectRatio: 2,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: totalDays,
            minY: -2,
            maxY: 2,
            lineTouchData: const LineTouchData(enabled: false),
            lineBarsData: hasData
                ? _buildSegments(spots, color)
                : [_makeSegment(spots.whereType<FlSpot>().toList(), color)],
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
                        child: Text(
                          label,
                          textScaler: TextScaler.noScaling,
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

    return Card.filled(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.chartOverTimeTitle(
                    AppLocalizations.of(context)!.tagMoodTitle),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: hasData ? 1.0 : 0.3,
                child: Center(child: chartWidget),
              ),
              if (!hasData)
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

  DateTime _dataRangeStart() {
    return entries
        .where((e) => e.mood != null)
        .map((e) => e.timeCreate)
        .reduce((a, b) => a.isBefore(b) ? a : b)
        .let((d) => DateTime(d.year, d.month, d.day));
  }

  DateTime _dummyRangeStart(DateTime today) {
    return DateTime(today.year, today.month - 12, today.day);
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

  List<DateTime> _generateMonthlyBuckets(DateTime start, DateTime end) {
    final buckets = <DateTime>[];
    DateTime current = DateTime(start.year, start.month, 1);
    while (!current.isAfter(end)) {
      buckets.add(current);
      current = DateTime(current.year, current.month + 1, 1);
    }
    return buckets;
  }

  List<FlSpot?> _computeSpots(List<DateTime> buckets, DateTime rangeStart) {
    final Map<int, List<double>> bucketMoods = {};

    for (final entry in entries) {
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

  List<LineChartBarData> _buildSegments(List<FlSpot?> spots, Color color) {
    final segments = <LineChartBarData>[];
    var run = <FlSpot>[];
    for (final spot in spots) {
      if (spot != null) {
        run.add(spot);
      } else if (run.isNotEmpty) {
        segments.add(_makeSegment(run, color));
        run = [];
      }
    }
    if (run.isNotEmpty) segments.add(_makeSegment(run, color));
    return segments;
  }

  LineChartBarData _makeSegment(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 4,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }

  List<DateTime> _computeMarkerDates(
      DateTime rangeStart, DateTime rangeEnd, int spanDays) {
    final markers = <DateTime>[];
    if (spanDays <= _monthThreshold) {
      DateTime current = rangeStart;
      while (!current.isAfter(rangeEnd)) {
        markers.add(current);
        current = current.add(const Duration(days: 7));
      }
    } else if (spanDays <= _yearThreshold) {
      DateTime current = DateTime(rangeStart.year, rangeStart.month, 1);
      while (!current.isAfter(rangeEnd)) {
        if (!current.isBefore(rangeStart)) markers.add(current);
        current = DateTime(current.year, current.month + 1, 1);
      }
    } else {
      // Quarterly markers for both the 1-3 year and >3 year ranges
      for (int year = rangeStart.year; year <= rangeEnd.year + 1; year++) {
        for (final month in [1, 4, 7, 10]) {
          final d = DateTime(year, month, 1);
          if (!d.isBefore(rangeStart) && !d.isAfter(rangeEnd)) {
            markers.add(d);
          }
        }
      }
    }
    return markers;
  }

  List<DateTime> _computeLabelDates(List<DateTime> markerDates, int spanDays) {
    if (spanDays > 3 * _yearThreshold) {
      // Only label year starts for very long ranges
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
