import 'package:daily_you/config_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/utils/chart_y_range.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

typedef LeftTitleBuilder = Widget Function(double value, TitleMeta meta);

/// Generic bar chart showing values per day of week.
class ValueByDayChart extends StatelessWidget {
  final Map<String, double?> averageValues;
  final bool hasData;
  final ChartYRange yRange;
  final String title;
  final LeftTitleBuilder? buildLeftTitle;
  final Color? color;
  final bool anchorAtZero;

  const ValueByDayChart({
    super.key,
    required this.averageValues,
    required this.hasData,
    required this.yRange,
    required this.title,
    this.buildLeftTitle,
    this.color,
    this.anchorAtZero = false,
  });

  static const _dummyValues = {
    'Mon': 1.0,
    'Tue': -0.5,
    'Wed': 1.5,
    'Thu': 0.0,
    'Fri': 1.0,
    'Sat': 2.0,
    'Sun': 0.5,
  };

  @override
  Widget build(BuildContext context) {
    final displayValues = hasData ? averageValues : _scaledDummyValues();
    final range = hasData
        ? yRange.resolve(displayValues.values.whereType<double>())
        : yRange.previewRange;

    return Card.filled(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Center(
              child: Text(
                title,
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
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 0, right: 42, bottom: 0, top: 8),
                    child: AspectRatio(
                      aspectRatio: 2,
                      child: BarChart(
                        BarChartData(
                          groupsSpace: 10,
                          alignment: BarChartAlignment.spaceAround,
                          maxY: range.maxY,
                          minY: range.minY,
                          barGroups: _getBarGroups(
                              context,
                              color ?? Theme.of(context).colorScheme.primary,
                              displayValues,
                              range),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                interval: range.interval,
                                showTitles: true,
                                reservedSize: 42,
                                getTitlesWidget: (value, meta) =>
                                    buildLeftTitle != null
                                        ? buildLeftTitle!(value, meta)
                                        : _defaultLeftTitle(value, meta),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 36,
                                getTitlesWidget: (double value, _) {
                                  return SizedBox(
                                    width: 36,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Padding(
                                        padding: const EdgeInsets.all(2.0),
                                        child: Text(_getDayLabel(
                                            context, value.toInt())),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            rightTitles: const AxisTitles(),
                            topTitles: const AxisTitles(),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.symmetric(
                              horizontal: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawHorizontalLine: true,
                            horizontalInterval: range.interval,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.2),
                              strokeWidth: 1,
                            ),
                          ),
                          barTouchData: BarTouchData(enabled: false),
                        ),
                      ),
                    ),
                  ),
                ),
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

  Map<String, double> _scaledDummyValues() {
    const dummyMin = -0.5;
    const dummyMax = 2.0;
    const dummyRange = dummyMax - dummyMin;
    final preview = yRange.previewRange;
    final scaleRange = preview.maxY - preview.minY;
    return {
      for (final e in _dummyValues.entries)
        e.key: preview.minY + ((e.value - dummyMin) / dummyRange) * scaleRange,
    };
  }

  Widget _defaultLeftTitle(double value, TitleMeta meta) {
    final formatted = _formatValue(value);
    return SideTitleWidget(
      meta: meta,
      child: Text(
        formatted,
        style: const TextStyle(fontSize: 11),
        textAlign: TextAlign.right,
      ),
    );
  }

  String _formatValue(double value) {
    if (value == value.truncateToDouble()) return value.toInt().toString();
    if (value.abs() >= 100) return value.toInt().toString();
    if (value.abs() >= 10) return value.toStringAsFixed(1);
    return value
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  double _barBaseline(double rangeMinY, double rangeMaxY) {
    if (!anchorAtZero) return rangeMinY;
    if (rangeMinY > 0) return rangeMinY;
    if (rangeMaxY < 0) return rangeMaxY;
    return 0.0;
  }

  List<BarChartGroupData> _getBarGroups(BuildContext context, Color barColor,
      Map<String, double?> displayValues, ChartRange range) {
    final orderedDays = _getOrderedDays(context, displayValues);
    final baseline = _barBaseline(range.minY, range.maxY);
    return orderedDays.asMap().entries.map((entry) {
      final index = entry.key;
      final value = entry.value.value;
      if (value == null) {
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              color: Colors.transparent,
              width: 32,
              fromY: baseline,
              toY: baseline,
            ),
          ],
        );
      }
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            color: barColor,
            width: 32,
            fromY: baseline,
            toY: value,
          ),
        ],
      );
    }).toList();
  }

  List<MapEntry<String, double?>> _getOrderedDays(
      BuildContext context, Map<String, double?> displayValues) {
    final configProvider = Provider.of<ConfigProvider>(context);
    List<MapEntry<String, double?>> days = displayValues.entries.toList();
    final startingDayIndex = configProvider.getFirstDayOfWeekIndex(context);
    days = days.sublist(startingDayIndex)
      ..addAll(days.sublist(0, startingDayIndex));
    return days;
  }

  String _getDayLabel(BuildContext context, int index) {
    var days = TimeManager.daysOfWeekLabels(context);
    final startingDayIndex =
        ConfigProvider.instance.getFirstDayOfWeekIndex(context);
    days = days.sublist(startingDayIndex)
      ..addAll(days.sublist(0, startingDayIndex));
    return days[index];
  }
}
