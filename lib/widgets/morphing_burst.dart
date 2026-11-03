// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

abstract final class BurstShader {
  static ui.FragmentProgram? _program;

  static Future<void> load() async {
    _program ??= await ui.FragmentProgram.fromAsset('shaders/mood_burst.frag');
  }
}

class MorphingBurstPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double radiusScale;

  const MorphingBurstPainter({
    required this.progress,
    required this.color,
    this.radiusScale = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final program = BurstShader._program;
    if (program == null) return;

    final devicePixelRatio =
        ui.PlatformDispatcher.instance.implicitView?.devicePixelRatio ?? 1.0;
    final shader = program.fragmentShader()
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, progress)
      ..setFloat(3, radiusScale)
      ..setFloat(4, 1 / devicePixelRatio)
      ..setFloat(5, color.r)
      ..setFloat(6, color.g)
      ..setFloat(7, color.b)
      ..setFloat(8, color.a);
    canvas.drawRect(
      (Offset.zero & size).inflate(size.shortestSide * 0.05),
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(MorphingBurstPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.radiusScale != radiusScale;
}
