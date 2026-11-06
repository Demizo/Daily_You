// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math' as math;

import 'package:daily_you/widgets/animated_values.dart';
import 'package:material_ui/material_ui.dart';

class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    required this.color,
    this.minimum,
  });

  final List<double?> values;
  final Color color;
  final double? minimum;

  @override
  Widget build(BuildContext context) => AnimatedValues(
        values: values,
        builder: (context, animatedValues) => CustomPaint(
          size: Size.infinite,
          painter: _SparklinePainter(animatedValues, color, minimum),
        ),
      );
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter(this.values, this.color, this.minimum);

  final List<double?> values;
  final Color color;
  final double? minimum;

  @override
  void paint(Canvas canvas, Size size) {
    final present = values.whereType<double>().toList();
    if (present.length < 2) return;
    final low = minimum ?? present.reduce(math.min);
    final high = present.reduce(math.max);
    final span = high - low == 0 ? 1 : high - low;

    final line = Path();
    final area = Path();
    double? firstX;
    double? lastX;
    for (final (index, value) in values.indexed) {
      if (value == null) continue;
      final x = index / (values.length - 1) * size.width;
      final y = size.height - (value - low) / span * size.height;
      if (firstX == null) {
        firstX = x;
        line.moveTo(x, y);
        area.moveTo(x, size.height);
        area.lineTo(x, y);
      } else {
        line.lineTo(x, y);
        area.lineTo(x, y);
      }
      lastX = x;
    }
    area
      ..lineTo(lastX!, size.height)
      ..close();

    canvas.drawPath(area, Paint()..color = color.withValues(alpha: 0.18));
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter oldPainter) =>
      oldPainter.values != values ||
      oldPainter.color != color ||
      oldPainter.minimum != minimum;
}
