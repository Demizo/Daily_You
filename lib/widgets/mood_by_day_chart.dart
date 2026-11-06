// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math' as math;

import 'package:daily_you/models/mood.dart';
import 'package:daily_you/providers/mood_scale_provider.dart';
import 'package:daily_you/stats/stats_analysis.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/utils/mood_scale_visuals.dart';
import 'package:daily_you/widgets/animated_values.dart';
import 'package:daily_you/widgets/mood_tier_mark.dart';
import 'package:daily_you/widgets/no_data_overlay.dart';
import 'package:daily_you/utils/secondary_text_style.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class MoodByDayChart extends StatelessWidget {
  const MoodByDayChart({
    super.key,
    required this.weekdays,
    required this.hasData,
    required this.title,
  });

  static const double _plotHeight = 200;
  static const double _markSize = 30;
  static const double _axisWidth = 40;

  final List<WeekdayMood> weekdays;
  final bool hasData;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final moodScale = context.watch<MoodScaleProvider>();
    final weekdayNames = TimeManager.daysOfWeekLabels(context);

    return Card.filled(
      color: colorScheme.surfaceContainerLow,
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
          NoDataOverlay(
            hasData: hasData,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 12, 8),
              child: Column(children: [
                SizedBox(
                  height: _plotHeight,
                  child: Row(children: [
                    SizedBox(
                      width: _axisWidth,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (final mood in Mood.levels.reversed)
                            MoodTierMark(mood: mood, size: _markSize),
                        ],
                      ),
                    ),
                    Expanded(
                      child: AnimatedValues(
                        values: _animationFrame(weekdays),
                        builder: (context, frame) => CustomPaint(
                          size: const Size.fromHeight(_plotHeight),
                          painter: _MoodByDayPainter(
                            frame: frame,
                            tierColors: [
                              for (final mood in Mood.levels)
                                moodScale
                                        .levelOf(mood)
                                        ?.resolvedColor(context) ??
                                    colorScheme.primary,
                            ],
                            emptyColor: colorScheme.surfaceContainerHighest,
                            separatorColor: colorScheme.surfaceContainerLow,
                            gridColor:
                                colorScheme.onSurface.withValues(alpha: 0.12),
                            lineColor: colorScheme.onSurface,
                            markSize: _markSize,
                            isRtl:
                                Directionality.of(context) == TextDirection.rtl,
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 6),
                Row(children: [
                  const SizedBox(width: _axisWidth),
                  for (final weekday in weekdays)
                    Expanded(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            weekdayNames[weekday.weekdayIndex],
                            style: secondaryTextStyle(context),
                          ),
                        ),
                      ),
                    ),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

final int _valuesPerWeekday = Mood.count + 1;

List<double?> _animationFrame(List<WeekdayMood> weekdays) => [
      for (final weekday in weekdays) ...[
        for (final count in weekday.tierCounts)
          count / math.max(1, weekday.tierCounts.reduce((a, b) => a + b)),
        weekday.meanMood,
      ],
    ];

class _MoodByDayPainter extends CustomPainter {
  _MoodByDayPainter({
    required this.frame,
    required this.tierColors,
    required this.emptyColor,
    required this.separatorColor,
    required this.gridColor,
    required this.lineColor,
    required this.markSize,
    required this.isRtl,
  });

  static const double _maximumBarWidth = 36;
  static const double _barRadius = 10;
  static const double _separatorHeight = 1.5;

  final List<double?> frame;
  final List<Color> tierColors;
  final Color emptyColor;
  final Color separatorColor;
  final Color gridColor;
  final Color lineColor;
  final double markSize;
  final bool isRtl;

  int get _weekdayCount => frame.length ~/ _valuesPerWeekday;

  double _share(int column, int tier) =>
      frame[column * _valuesPerWeekday + tier]!;

  double? _meanMood(int column) =>
      frame[column * _valuesPerWeekday + Mood.count];

  double _markY(Size size, double position) =>
      markSize / 2 +
      (Mood.count - 1 - position) * (size.height - markSize) / (Mood.count - 1);

  double _centerX(Size size, int column) {
    final x = (column + 0.5) * size.width / _weekdayCount;
    return isRtl ? size.width - x : x;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var tier = 0; tier < Mood.count; tier++) {
      final y = _markY(size, tier.toDouble());
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final barWidth =
        math.min(_maximumBarWidth, size.width / _weekdayCount * 0.7);
    for (var column = 0; column < _weekdayCount; column++) {
      _paintBar(canvas, size, column, _centerX(size, column), barWidth);
    }
    _paintMeanLine(canvas, size);
  }

  void _paintBar(
    Canvas canvas,
    Size size,
    int column,
    double centerX,
    double barWidth,
  ) {
    final bar = RRect.fromRectAndRadius(
      Rect.fromLTWH(centerX - barWidth / 2, 0, barWidth, size.height),
      const Radius.circular(_barRadius),
    );
    canvas.save();
    canvas.clipRRect(bar);
    canvas.drawRect(bar.outerRect, Paint()..color = emptyColor);
    var bottom = size.height;
    final boundaries = <double>[];
    for (var tier = 0; tier < Mood.count; tier++) {
      final share = _share(column, tier);
      if (share <= 0) continue;
      final top = bottom - size.height * share;
      canvas.drawRect(
        Rect.fromLTRB(bar.left, top, bar.right, bottom),
        Paint()..color = tierColors[tier],
      );
      boundaries.add(top);
      bottom = top;
    }
    final separatorPaint = Paint()..color = separatorColor;
    for (final boundary
        in boundaries.take(math.max(0, boundaries.length - 1))) {
      canvas.drawRect(
        Rect.fromLTWH(bar.left, boundary - _separatorHeight / 2, barWidth,
            _separatorHeight),
        separatorPaint,
      );
    }
    canvas.restore();
  }

  void _paintMeanLine(Canvas canvas, Size size) {
    final points = [
      for (var column = 0; column < _weekdayCount; column++)
        if (_meanMood(column) case final mean?)
          Offset(_centerX(size, column), _markY(size, mean)),
    ];
    if (points.isEmpty) return;
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()..addPolygon(points, false),
      linePaint,
    );
    for (final point in points) {
      canvas.drawCircle(point, 6, Paint()..color = separatorColor);
      canvas.drawCircle(point, 4, Paint()..color = lineColor);
    }
  }

  @override
  bool shouldRepaint(_MoodByDayPainter oldPainter) =>
      oldPainter.frame != frame ||
      oldPainter.tierColors != tierColors ||
      oldPainter.emptyColor != emptyColor ||
      oldPainter.separatorColor != separatorColor ||
      oldPainter.gridColor != gridColor ||
      oldPainter.lineColor != lineColor ||
      oldPainter.markSize != markSize ||
      oldPainter.isRtl != isRtl;
}
