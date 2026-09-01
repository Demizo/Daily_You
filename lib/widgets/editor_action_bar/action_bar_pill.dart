import 'dart:ui' show lerpDouble;

import 'package:daily_you/widgets/editor_action_bar/dock_metrics.dart';
import 'package:daily_you/widgets/editor_action_bar/toolbar_entry.dart';
import 'package:daily_you/widgets/editor_action_bar/toolbar_morph.dart';
import 'package:flutter/material.dart';

class ActionBarPill extends StatelessWidget {
  static const double _iconTintHandoff = 0.5;

  final DockMetrics metrics;
  final ToolbarEntrySplit split;
  final bool showingMainActions;
  final void Function(BuildContext buttonContext) onShowOverflow;

  const ActionBarPill({
    super.key,
    required this.metrics,
    required this.split,
    required this.showingMainActions,
    required this.onShowOverflow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconTint =
        metrics.progress < _iconTintHandoff ? theme.colorScheme.primary : null;

    return Material(
      // Animated frame by frame
      animationDuration: Duration.zero,
      color: theme.colorScheme.primaryContainer
          .withValues(alpha: 1 - metrics.progress),
      shape: RoundedRectangleBorder(borderRadius: metrics.borderRadius),
      elevation: metrics.pillElevation,
      shadowColor: theme.shadowColor.withValues(alpha: 0.4),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        duration: toolbarMorphDuration,
        curve: toolbarMorphCurve,
        alignment: AlignmentDirectional.centerStart,
        child: Padding(
          padding: EdgeInsets.all(metrics.pillPadding),
          child: IconTheme.merge(
            data: IconThemeData(color: iconTint),
            child: MorphContent(
              child: KeyedSubtree(
                key: ValueKey(showingMainActions),
                child: IntrinsicHeight(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final entry in split.visible)
                        entry.build(context, null),
                      if (split.hasOverflow)
                        Builder(
                          builder: (buttonContext) => ToolbarIconButton(
                            size: metrics.buttonSize,
                            icon: Icons.more_horiz_rounded,
                            onPressed: () => onShowOverflow(buttonContext),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DockSurface extends StatelessWidget {
  final DockMetrics metrics;
  final AlignmentGeometry alignment;
  final double barWidth;
  final double pillWidth;

  const DockSurface({
    super.key,
    required this.metrics,
    required this.alignment,
    required this.barWidth,
    required this.pillWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: SizedBox(
        width: lerpDouble(barWidth, pillWidth, 1 - metrics.progress),
        height: metrics.barHeight,
        child: Material(
          animationDuration: Duration.zero,
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHigh
              .withValues(alpha: metrics.progress),
          shape: RoundedRectangleBorder(borderRadius: metrics.borderRadius),
          elevation: 0,
        ),
      ),
    );
  }
}

class ToolbarIconButton extends StatelessWidget {
  final double size;
  final IconData icon;
  final VoidCallback? onPressed;

  const ToolbarIconButton({
    super.key,
    required this.size,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: IconButton(
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, size: 24),
        onPressed: onPressed,
      ),
    );
  }
}
