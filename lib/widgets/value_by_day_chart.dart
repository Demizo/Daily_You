// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/stats/stats_analysis.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/utils/chart_bar_width.dart';
import 'package:daily_you/utils/chart_y_range.dart';
import 'package:daily_you/widgets/no_data_overlay.dart';
import 'package:daily_you/utils/secondary_text_style.dart';
import 'package:material_ui/material_ui.dart';
import 'package:fl_chart/fl_chart.dart';
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

  static const double _leftAxisWidth = 42;

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
          NoDataOverlay(
            hasData: hasData,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 42, top: 8),
                child: AspectRatio(
                  aspectRatio: 2,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final barWidth = chartBarWidth(
                        plotWidth: constraints.maxWidth - _leftAxisWidth,
                        barCount: DateTime.daysPerWeek,
                      );
                      return BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: range.maxY,
                          minY: range.minY,
                          barGroups: _getBarGroups(
                              context,
                              color ?? Theme.of(context).colorScheme.primary,
                              displayValues,
                              range,
                              barWidth),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                interval: range.interval,
                                showTitles: true,
                                reservedSize: _leftAxisWidth,
                                getTitlesWidget: (value, meta) =>
                                    buildLeftTitle != null
                                        ? buildLeftTitle!(value, meta)
                                        : _defaultLeftTitle(
                                            context, value, meta),
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
                                        child: Text(
                                          _getDayLabel(context, value.toInt()),
                                          style: secondaryTextStyle(context),
                                        ),
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
                      );
                    },
                  ),
                ),
              ),
            ),
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

  Widget _defaultLeftTitle(BuildContext context, double value, TitleMeta meta) {
    final formatted = _formatValue(value);
    return SideTitleWidget(
      meta: meta,
      child: Text(
        formatted,
        style: secondaryTextStyle(context, fontSize: 11),
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

  List<BarChartGroupData> _getBarGroups(
    BuildContext context,
    Color barColor,
    Map<String, double?> displayValues,
    ChartRange range,
    double barWidth,
  ) {
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
              width: barWidth,
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
            width: barWidth,
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
    final days = displayValues.entries.toList();
    return [
      for (final dayIndex in weekdayDisplayOrder(
          configProvider.getFirstDayOfWeekIndex(context)))
        days[dayIndex],
    ];
  }

  String _getDayLabel(BuildContext context, int index) {
    final days = TimeManager.daysOfWeekLabels(context);
    final startingDayIndex =
        ConfigProvider.instance.getFirstDayOfWeekIndex(context);
    return days[weekdayDisplayOrder(startingDayIndex)[index]];
  }
}
