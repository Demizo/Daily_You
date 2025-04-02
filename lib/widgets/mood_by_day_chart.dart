import 'package:daily_you/config_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MoodByDayChart extends StatelessWidget {
  final Map<String, double> averageMood;

  const MoodByDayChart({super.key, required this.averageMood});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(left: 0, right: 42, bottom: 0, top: 8),
        child: AspectRatio(
          aspectRatio: 2,
          child: BarChart(
            BarChartData(
                groupsSpace: 10,
                alignment: BarChartAlignment.spaceAround,
                maxY: 2,
                minY: -2,
                barGroups: _getBarGroups(Theme.of(context).colorScheme.primary),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                    interval: 1,
                    showTitles: true,
                    reservedSize: 42,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: MoodIcon(
                            moodValue: index,
                          ));
                    },
                  )),
                  bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (double value, _) {
                      return Text(_getDayLabel(value.toInt()));
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
                          .withOpacity(0.2),
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
                        .withOpacity(0.2),
                    strokeWidth: 1,
                  ),
                ),
                barTouchData: BarTouchData(enabled: false)),
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> _getBarGroups(Color color) {
    List<MapEntry<String, double>> orderedDays = _getOrderedDays();
    return orderedDays.asMap().entries.map((entry) {
      int index = entry.key;
      double mood = entry.value.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            color: color,
            width: 16,
            fromY: -2,
            toY: mood,
          ),
        ],
      );
    }).toList();
  }

  List<MapEntry<String, double>> _getOrderedDays() {
    List<MapEntry<String, double>> days = averageMood.entries.toList();
    final startingDayIndex = ConfigProvider.instance.getFirstDayOfWeekIndex();
    days = days.sublist(startingDayIndex)
      ..addAll(days.sublist(0, startingDayIndex));
    return days;
  }

  String _getDayLabel(int index) {
    var days = TimeManager.daysOfWeekLabels();

    final startingDayIndex = ConfigProvider.instance.getFirstDayOfWeekIndex();
    days = days.sublist(startingDayIndex)
      ..addAll(days.sublist(0, startingDayIndex));

    return days[index];
  }
}
