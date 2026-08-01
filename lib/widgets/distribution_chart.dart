import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';

class _Bin {
  final double min;
  final double max;
  int count;
  final String? explicitLabel;
  _Bin(this.min, this.max, this.count, {this.explicitLabel});
}

class DistributionChart extends StatelessWidget {
  final List<double> values;
  final String title;
  final Color? color;

  const DistributionChart({
    super.key,
    required this.values,
    required this.title,
    this.color,
  });

  static const _dummyValues = [
    1.0,
    2.0,
    2.0,
    3.0,
    3.0,
    3.0,
    4.0,
    4.0,
    4.0,
    4.0,
    5.0,
    5.0,
    5.0,
    5.0,
    5.0,
    6.0,
    6.0,
    6.0,
    7.0,
    7.0,
    8.0,
    9.0,
  ];

  static const int _maxDiscreteValues = 10;
  static const int _maxBins = 8;

  bool _isAllInteger(List<double> data) =>
      data.every((value) => value == value.truncateToDouble());

  int _sampleSizeBinCount(int n) => n <= 15
      ? 5
      : n <= 40
          ? 6
          : n <= 100
              ? 7
              : 8;

  List<_Bin> _computeBins(List<double> data) {
    if (data.isEmpty) return [];

    final isInteger = _isAllInteger(data);
    final distinctValues = data.toSet().toList()..sort();

    if (distinctValues.length <= _maxDiscreteValues) {
      final counts = <double, int>{for (final v in distinctValues) v: 0};
      for (final v in data) {
        counts[v] = counts[v]! + 1;
      }
      return [
        for (final value in distinctValues)
          _Bin(value, value, counts[value]!,
              explicitLabel:
                  isInteger ? value.toInt().toString() : _formatNumber(value)),
      ];
    }

    final dataMin = distinctValues.first;
    final dataMax = distinctValues.last;

    if (isInteger) {
      final intMin = dataMin.toInt();
      final totalSpan = dataMax.toInt() - intMin + 1;
      final binCount = math.min(_sampleSizeBinCount(data.length), _maxBins);

      final baseSize = totalSpan ~/ binCount;
      final remainder = totalSpan % binCount;
      final bins = <_Bin>[];
      int cursor = intMin;
      for (int i = 0; i < binCount; i++) {
        final size = baseSize + (i < remainder ? 1 : 0);
        bins.add(_Bin(cursor.toDouble(), (cursor + size).toDouble(), 0));
        cursor += size;
      }
      for (final value in data) {
        final index = bins.indexWhere((bin) =>
            value >= bin.min && (value < bin.max || identical(bin, bins.last)));
        bins[index.clamp(0, bins.length - 1)].count++;
      }
      return bins;
    }

    final binCount = math.min(_sampleSizeBinCount(data.length), _maxBins);
    final range = dataMax - dataMin;
    final binSize = range / binCount;

    final bins = List.generate(
      binCount,
      (i) => _Bin(dataMin + i * binSize, dataMin + (i + 1) * binSize, 0),
    );

    for (final value in data) {
      final index =
          ((value - dataMin) / binSize).floor().clamp(0, binCount - 1);
      bins[index].count++;
    }

    return bins;
  }

  String _formatNumber(double value) {
    if (value.abs() >= 100) return value.toInt().toString();
    if (value.abs() >= 10) return value.toStringAsFixed(1);
    return value.toStringAsFixed(1);
  }

  String _formatBinLabel(_Bin bin, bool isInteger) {
    if (bin.explicitLabel != null) return bin.explicitLabel!;
    if (isInteger) {
      final lo = bin.min.toInt();
      final hi = bin.max.toInt() - 1;
      return hi <= lo ? '$lo' : '$lo – $hi';
    }
    return '${_formatNumber(bin.min)} – ${_formatNumber(bin.max)}';
  }

  @override
  Widget build(BuildContext context) {
    final hasData = values.length > 1;
    final displayValues = hasData ? values : _dummyValues;
    final bins = _computeBins(displayValues);
    if (bins.isEmpty) return const SizedBox.shrink();

    final maxCount = bins.map((b) => b.count).reduce(math.max);
    final barColor = color ?? Theme.of(context).colorScheme.primary;
    final surfaceColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2);

    final isInteger = _isAllInteger(displayValues);

    final barGroups = bins.asMap().entries.map((entry) {
      final i = entry.key;
      final bin = entry.value;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            fromY: 0,
            toY: bin.count.toDouble(),
            color: barColor,
            width: 32,
          ),
        ],
      );
    }).toList();

    return Card.filled(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 8, right: 42, top: 8, bottom: 0),
                  child: AspectRatio(
                    aspectRatio: 2,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxCount.toDouble() * 1.15,
                        minY: 0,
                        barGroups: barGroups,
                        groupsSpace: 6,
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (value, _) {
                                final i = value.toInt();
                                if (i < 0 || i >= bins.length) {
                                  return const SizedBox.shrink();
                                }
                                final label =
                                    _formatBinLabel(bins[i], isInteger);
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      label,
                                      style: const TextStyle(fontSize: 11),
                                      textScaler: TextScaler.noScaling,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 36,
                              getTitlesWidget: (value, meta) {
                                if (value != value.truncateToDouble()) {
                                  return const SizedBox.shrink();
                                }
                                return SideTitleWidget(
                                  meta: meta,
                                  child: Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(),
                          rightTitles: const AxisTitles(),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawHorizontalLine: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) =>
                              FlLine(color: surfaceColor, strokeWidth: 1),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.symmetric(
                            horizontal:
                                BorderSide(color: surfaceColor, width: 1),
                          ),
                        ),
                        barTouchData: BarTouchData(enabled: false),
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
}
