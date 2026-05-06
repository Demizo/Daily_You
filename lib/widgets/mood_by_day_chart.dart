import 'package:daily_you/config_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class MoodByDayChart extends StatelessWidget {
  final Map<String, double> averageMood;
  final bool hasData;

  const MoodByDayChart(
      {super.key, required this.averageMood, this.hasData = true});

  static const _dummyAverageMood = {
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
    final displayMood = hasData ? averageMood : _dummyAverageMood;

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
                AppLocalizations.of(context)!.chartByDayTitle(
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
                            maxY: 2,
                            minY: -2,
                            barGroups: _getBarGroups(
                                context,
                                Theme.of(context).colorScheme.primary,
                                displayMood),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                interval: 1,
                                showTitles: true,
                                reservedSize: 42,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  return SideTitleWidget(
                                      meta: meta,
                                      child: MoodIcon(
                                        moodValue: index,
                                        allowScaling: false,
                                      ));
                                },
                              )),
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
                                        )),
                                  );
                                },
                              )),
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
                                ))),
                            gridData: FlGridData(
                              show: true,
                              drawHorizontalLine: true,
                              horizontalInterval: 1,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.2),
                                strokeWidth: 1,
                              ),
                            ),
                            barTouchData: BarTouchData(enabled: false)),
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
                      color: Theme.of(context).disabledColor),
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _getBarGroups(
      BuildContext context, Color color, Map<String, double> displayMood) {
    List<MapEntry<String, double>> orderedDays =
        _getOrderedDays(context, displayMood);
    return orderedDays.asMap().entries.map((entry) {
      int index = entry.key;
      double mood = entry.value.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            color: color,
            width: 32,
            fromY: -2,
            toY: mood,
          ),
        ],
      );
    }).toList();
  }

  List<MapEntry<String, double>> _getOrderedDays(
      BuildContext context, Map<String, double> displayMood) {
    final configProvider = Provider.of<ConfigProvider>(context);
    List<MapEntry<String, double>> days = displayMood.entries.toList();
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
