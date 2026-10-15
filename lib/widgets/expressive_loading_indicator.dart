// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math' as math;

import 'package:daily_you/widgets/material_shapes.dart';
import 'package:material_ui/material_ui.dart';

class ExpressiveLoadingIndicator extends StatefulWidget {
  const ExpressiveLoadingIndicator({
    super.key,
    this.size = 48,
    this.color,
  });

  final double size;
  final Color? color;

  @override
  State<ExpressiveLoadingIndicator> createState() =>
      _ExpressiveLoadingIndicatorState();
}

class _ExpressiveLoadingIndicatorState extends State<ExpressiveLoadingIndicator>
    with SingleTickerProviderStateMixin {
  static const Duration _rotationPeriod = Duration(milliseconds: 3000);
  static const int _morphsPerRotation = 4;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _rotationPeriod,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final morph = Curves.easeInOut.transform((math.sin(
                        _controller.value * 2 * math.pi * _morphsPerRotation) +
                    1) /
                2);
            return Transform.rotate(
              angle: _controller.value * 2 * math.pi,
              child: CustomPaint(
                size: Size.square(widget.size),
                painter: MorphingBurstPainter(progress: morph, color: color),
              ),
            );
          },
        ),
      ),
    );
  }
}
