// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

class Wiggle extends StatefulWidget {
  const Wiggle({
    super.key,
    required this.child,
    this.enabled = true,
    this.phase = 0,
  });

  static const double maxAngle = 0.01;
  static const Duration period = Duration(milliseconds: 360);

  final Widget child;
  final bool enabled;
  final double phase;

  @override
  State<Wiggle> createState() => _WiggleState();
}

class _WiggleState extends State<Wiggle> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Wiggle.period,
  );
  final GlobalKey _childKey = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(Wiggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncAnimation() {
    final shouldAnimate =
        widget.enabled && !MediaQuery.disableAnimationsOf(context);
    if (shouldAnimate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!shouldAnimate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = RepaintBoundary(key: _childKey, child: widget.child);
    if (!widget.enabled || MediaQuery.disableAnimationsOf(context)) {
      return child;
    }
    return AnimatedBuilder(
      animation: _controller,
      child: child,
      builder: (context, child) => Transform.rotate(
        angle: math.sin(2 * math.pi * (_controller.value + widget.phase)) *
            Wiggle.maxAngle,
        child: child,
      ),
    );
  }
}
