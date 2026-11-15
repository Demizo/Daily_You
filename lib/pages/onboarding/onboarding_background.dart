// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

enum _ShapeKind { circle, roundedSquare, pill }

class _DriftShape {
  const _DriftShape({
    required this.kind,
    required this.x,
    required this.y,
    required this.size,
    required this.depth,
    required this.phase,
    required this.colorIndex,
  });

  final _ShapeKind kind;
  final double x;
  final double y;
  final double size;
  final double depth;
  final double phase;
  final int colorIndex;
}

const _shapes = [
  _DriftShape(
      kind: _ShapeKind.circle,
      x: 0.12,
      y: 0.14,
      size: 0.30,
      depth: 0.5,
      phase: 0.0,
      colorIndex: 0),
  _DriftShape(
      kind: _ShapeKind.roundedSquare,
      x: 0.78,
      y: 0.22,
      size: 0.22,
      depth: 0.8,
      phase: 0.3,
      colorIndex: 1),
  _DriftShape(
      kind: _ShapeKind.pill,
      x: 0.40,
      y: 0.48,
      size: 0.34,
      depth: 0.65,
      phase: 0.6,
      colorIndex: 2),
  _DriftShape(
      kind: _ShapeKind.circle,
      x: 0.92,
      y: 0.62,
      size: 0.26,
      depth: 1.0,
      phase: 0.1,
      colorIndex: 0),
  _DriftShape(
      kind: _ShapeKind.roundedSquare,
      x: 0.18,
      y: 0.76,
      size: 0.28,
      depth: 0.7,
      phase: 0.8,
      colorIndex: 2),
  _DriftShape(
      kind: _ShapeKind.circle,
      x: 0.62,
      y: 0.92,
      size: 0.20,
      depth: 0.9,
      phase: 0.5,
      colorIndex: 1),
];

class OnboardingBackground extends StatelessWidget {
  const OnboardingBackground({
    super.key,
    required this.ambient,
    required this.position,
  });

  final Animation<double> ambient;
  final ValueListenable<double> position;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _BackgroundPainter(
            ambient: ambient,
            position: position,
            colors: [
              colorScheme.primary,
              colorScheme.tertiary,
              colorScheme.secondary,
            ],
          ),
        ),
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  _BackgroundPainter({
    required this.ambient,
    required this.position,
    required this.colors,
  }) : super(repaint: Listenable.merge([ambient, position]));

  static const double _parallax = 0.3;
  static const double _wrapWidth = 1.5;
  static const double _opacity = 0.045;

  final Animation<double> ambient;
  final ValueListenable<double> position;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    for (final shape in _shapes) {
      final cycle = 2 * math.pi * (ambient.value + shape.phase);
      final shift = position.value * _parallax * shape.depth;
      final wrapped =
          ((shape.x - shift) % _wrapWidth + _wrapWidth) % _wrapWidth - 0.25;
      final center = Offset(
        (wrapped + 0.02 * math.sin(cycle)) * size.width,
        (shape.y + 0.015 * math.cos(cycle)) * size.height,
      );
      final extent = shape.size * size.width;
      final slot = shape.colorIndex + position.value;
      final from = slot.floor();
      final paint = Paint()
        ..color = Color.lerp(
          colors[from % colors.length],
          colors[(from + 1) % colors.length],
          slot - from,
        )!
            .withValues(alpha: _opacity);

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(0.12 * math.sin(cycle));
      switch (shape.kind) {
        case _ShapeKind.circle:
          canvas.drawCircle(Offset.zero, extent / 2, paint);
        case _ShapeKind.roundedSquare:
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  Rect.fromCenter(
                      center: Offset.zero, width: extent, height: extent),
                  Radius.circular(extent * 0.3)),
              paint);
        case _ShapeKind.pill:
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  Rect.fromCenter(
                      center: Offset.zero,
                      width: extent * 1.5,
                      height: extent * 0.6),
                  Radius.circular(extent * 0.3)),
              paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter oldDelegate) =>
      !listEquals(oldDelegate.colors, colors);
}
