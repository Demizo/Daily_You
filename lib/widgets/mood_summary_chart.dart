import 'package:daily_you/config_provider.dart';
import 'package:daily_you/widgets/material_shapes.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class MoodSummaryChart extends StatelessWidget {
  final Map<int, int> moodCounts;

  const MoodSummaryChart({super.key, required this.moodCounts});

  static const _moodOrder = [2, 1, 0, -1, -2];
  static const _barHeight = 44.0;
  static const _iconSize = 40.0;
  static const _countWidth = 44.0;
  static const _gap = 4.0;

  static const _dummyMoodCounts = {2: 4, 1: 8, 0: 9, -1: 3, -2: 1};

  @override
  Widget build(BuildContext context) {
    return Consumer<ConfigProvider>(
      builder: (context, configProvider, child) => _buildChart(context),
    );
  }

  Widget _buildChart(BuildContext context) {
    final hasData = moodCounts.values.any((v) => v > 0);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final displayCounts = hasData ? moodCounts : _dummyMoodCounts;
    final maxCount = displayCounts.values.reduce((a, b) => a > b ? a : b);
    final mostCommonMood = displayCounts.entries
        .where((e) => e.value > 0)
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;

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
                AppLocalizations.of(context)!.chartSummaryTitle(
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
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: _moodOrder.map((mood) {
                      final count = displayCounts[mood] ?? 0;
                      return _MoodBarRow(
                        mood: mood,
                        count: count,
                        maxCount: maxCount,
                        isMostCommon: mood == mostCommonMood,
                        isRtl: isRtl,
                        showLabel: hasData,
                        barHeight: _barHeight,
                        iconSize: _iconSize,
                        countWidth: _countWidth,
                        gap: _gap,
                      );
                    }).toList(),
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
}

class _MoodBarRow extends StatelessWidget {
  final int mood;
  final int count;
  final int maxCount;
  final bool isMostCommon;
  final bool isRtl;
  final bool showLabel;
  final double barHeight;
  final double iconSize;
  final double countWidth;
  final double gap;

  const _MoodBarRow({
    required this.mood,
    required this.count,
    required this.maxCount,
    required this.isMostCommon,
    required this.isRtl,
    required this.showLabel,
    required this.barHeight,
    required this.iconSize,
    required this.countWidth,
    required this.gap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final surface = Theme.of(context).colorScheme.surface;
    final fraction = maxCount > 0 ? count / maxCount : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: fraction),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        builder: (context, animatedFraction, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final minBarWidth = iconSize + gap;
              final maxBarWidth = constraints.maxWidth - countWidth - gap;
              final barWidth =
                  (minBarWidth + animatedFraction * (maxBarWidth - minBarWidth))
                      .clamp(minBarWidth, maxBarWidth);

              final iconWidget = _buildIconContainer(surface, primary);
              final bar = _buildBar(barWidth, iconWidget, primary);
              final countText = SizedBox(
                width: countWidth,
                child: Text(
                  (count > 0 && showLabel) ? '$count' : '',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: primary),
                  textAlign: isRtl ? TextAlign.right : TextAlign.left,
                ),
              );

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: isRtl
                    ? [countText, SizedBox(width: gap), bar]
                    : [bar, SizedBox(width: gap), countText],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBar(double width, Widget iconWidget, Color barColor) {
    return SizedBox(
      width: width,
      height: barHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(barHeight / 2),
              ),
            ),
          ),
          Positioned(
            left: isRtl ? null : (gap / 2),
            right: isRtl ? (gap / 2) : null,
            top: (barHeight - iconSize) / 2,
            child: iconWidget,
          ),
        ],
      ),
    );
  }

  Widget _buildIconContainer(Color surface, Color primary) {
    final icon = MoodIcon(
      moodValue: mood,
      allowScaling: false,
    );

    if (isMostCommon) {
      return SizedBox(
        width: iconSize,
        height: iconSize,
        child: ClipPath(
          clipper: SoftBurstClipper(),
          child: Container(
            color: surface,
            child: Center(child: icon),
          ),
        ),
      );
    }

    return SizedBox(
      width: iconSize,
      height: iconSize,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Container(
          decoration: BoxDecoration(color: surface, shape: BoxShape.circle),
          child: Center(child: icon),
        ),
      ),
    );
  }
}
