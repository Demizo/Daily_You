import 'package:daily_you/widgets/mood_icon.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MoodTotalsChart extends StatefulWidget {
  final Map<int, int> moodCounts;

  static final moodToIndexMapping = {
    -2: 0,
    -1: 1,
    0: 2,
    1: 3,
    2: 4,
  };

  static final indexToMoodValueMapping = Map.fromEntries(moodToIndexMapping
      .entries
      .map((entry) => MapEntry(entry.value, entry.key)));

  const MoodTotalsChart({super.key, required this.moodCounts});

  @override
  State<MoodTotalsChart> createState() => _MoodTotalsChartState();
}

class _MoodTotalsChartState extends State<MoodTotalsChart> {
  @override
  void initState() {
    super.initState();
  }

  BarChartGroupData generateBarGroup(
    int x,
    Color color,
    double value,
  ) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: value, color: color, width: 16),
      ],
      showingTooltipIndicators: touchedGroupIndex == x ? [0] : [],
    );
  }

  int touchedGroupIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 0, right: 42, bottom: 10, top: 8),
      child: AspectRatio(
        aspectRatio: 2,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            borderData: FlBorderData(
              show: true,
              border: Border.symmetric(
                horizontal: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.2),
                ),
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: const AxisTitles(
                drawBelowEverything: true,
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: _MoodLabelIconWidget(
                          isSelected: touchedGroupIndex == index,
                          mood: MoodTotalsChart.indexToMoodValueMapping[index]!,
                        ));
                  },
                ),
              ),
              rightTitles: const AxisTitles(),
              topTitles: const AxisTitles(),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.2),
                strokeWidth: 1,
              ),
            ),
            barGroups: widget.moodCounts.entries.map((e) {
              final index = e.key;
              final data = e.value;
              return generateBarGroup(
                  MoodTotalsChart.moodToIndexMapping[index]!,
                  Theme.of(context).colorScheme.primary,
                  data.toDouble());
            }).toList(),
            barTouchData: BarTouchData(
              enabled: true,
              handleBuiltInTouches: false,
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: Colors.transparent,
                tooltipMargin: 0,
                getTooltipItem: (
                  BarChartGroupData group,
                  int groupIndex,
                  BarChartRodData rod,
                  int rodIndex,
                ) {
                  return BarTooltipItem(
                    rod.toY.toInt().toString(),
                    TextStyle(
                      fontWeight: FontWeight.bold,
                      color: rod.color,
                      fontSize: 18,
                    ),
                  );
                },
              ),
              touchCallback: (event, response) {
                if (event.isInterestedForInteractions &&
                    response != null &&
                    response.spot != null) {
                  setState(() {
                    touchedGroupIndex = response.spot!.touchedBarGroupIndex;
                  });
                } else {
                  setState(() {
                    touchedGroupIndex = -1;
                  });
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _MoodLabelIconWidget extends ImplicitlyAnimatedWidget {
  const _MoodLabelIconWidget({
    required this.isSelected,
    required this.mood,
  }) : super(duration: const Duration(milliseconds: 100));
  final bool isSelected;
  final int mood;

  @override
  ImplicitlyAnimatedWidgetState<ImplicitlyAnimatedWidget> createState() =>
      _IconWidgetState();
}

class _IconWidgetState extends AnimatedWidgetBaseState<_MoodLabelIconWidget> {
  Tween<double>? _scaleTween;

  @override
  Widget build(BuildContext context) {
    final scale = 1 + _scaleTween!.evaluate(animation) * 0.5;
    return Transform(
        transform: Matrix4.rotationZ(0).scaled(scale, scale),
        origin: const Offset(14, 14),
        child: MoodIcon(moodValue: widget.mood));
  }

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _scaleTween = visitor(
      _scaleTween,
      widget.isSelected ? 1.0 : 0.0,
      (dynamic value) => Tween<double>(
        begin: value as double,
        end: widget.isSelected ? 1.0 : 0.0,
      ),
    ) as Tween<double>?;
  }
}
