import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

class ActionBarToggle extends StatefulWidget {
  final double size;

  final double dockProgress;

  final bool visible;
  final bool isShowingMainActions;
  final VoidCallback onPressed;

  const ActionBarToggle({
    super.key,
    required this.size,
    required this.dockProgress,
    required this.visible,
    required this.isShowingMainActions,
    required this.onPressed,
  });

  @override
  State<ActionBarToggle> createState() => _ActionBarToggleState();
}

class _ActionBarToggleState extends State<ActionBarToggle>
    with SingleTickerProviderStateMixin {
  static const double _closedCornerRadius = 16.0;

  static const double _iconSize = 24.0;

  late final AnimationController _controller;
  late final Animation<double> _iconProgress;
  late final Animation<double> _cornerProgress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      value: widget.isShowingMainActions ? 1.0 : 0.0,
    );
    _iconProgress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeOutBack,
    );
    _cornerProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOutQuad),
      reverseCurve: const Interval(0.0, 0.3, curve: Curves.easeOutBack),
    );
  }

  @override
  void didUpdateWidget(covariant ActionBarToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isShowingMainActions != oldWidget.isShowingMainActions) {
      widget.isShowingMainActions
          ? _controller.forward()
          : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final dockProgress = widget.visible ? widget.dockProgress : 0.0;
        final closedRadius =
            lerpDouble(_closedCornerRadius, widget.size / 2, dockProgress)!;
        final borderRadius = BorderRadius.circular(
            lerpDouble(closedRadius, widget.size / 2, _cornerProgress.value)!);
        final restingElevation = widget.isShowingMainActions ? 4.0 : 2.0;

        return Material(
          color: colorScheme.primary,
          elevation: widget.visible
              ? lerpDouble(restingElevation, 0.0, dockProgress)!
              : 0.0,
          shadowColor: theme.shadowColor.withValues(alpha: 0.4),
          borderRadius: borderRadius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onPressed,
            canRequestFocus: false,
            customBorder: RoundedRectangleBorder(borderRadius: borderRadius),
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: _buildIcons(colorScheme, _iconProgress.value),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIcons(ColorScheme colorScheme, double progress) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: progress * math.pi / 4,
          child: Transform.scale(
            scale: 1.0 - (progress * 0.5),
            child: Icon(Icons.add_rounded,
                size: _iconSize, color: colorScheme.onPrimary),
          ),
        ),
        Transform.rotate(
          angle: -(1.0 - progress) * math.pi / 4,
          child: Transform.scale(
            scale: 0.5 + (progress * 0.5),
            child: Icon(Icons.close_rounded,
                size: _iconSize, color: colorScheme.onPrimary),
          ),
        ),
      ],
    );
  }
}
