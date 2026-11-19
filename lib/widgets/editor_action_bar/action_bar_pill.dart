// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:ui' show lerpDouble;

import 'package:daily_you/widgets/editor_action_bar/dock_metrics.dart';
import 'package:daily_you/widgets/editor_action_bar/scrollable_toolbar_actions.dart';
import 'package:daily_you/widgets/editor_action_bar/toolbar_entry.dart';
import 'package:daily_you/widgets/editor_action_bar/toolbar_morph.dart';
import 'package:material_ui/material_ui.dart';

class ActionBarPill extends StatelessWidget {
  static const double _iconTintHandoff = 0.5;

  final DockMetrics metrics;
  final ToolbarEntrySplit split;
  final List<ToolbarEntry> entries;
  final double maxWidth;
  final bool showingMainActions;
  final void Function(BuildContext buttonContext) onShowOverflow;

  const ActionBarPill({
    super.key,
    required this.metrics,
    required this.split,
    required this.entries,
    required this.maxWidth,
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
          padding: EdgeInsets.symmetric(
            horizontal: metrics.pillPadding,
            vertical: metrics.isDocked ? 0 : metrics.pillPadding,
          ),
          child: IconTheme.merge(
            data: IconThemeData(color: iconTint),
            child: MorphContent(
              child: KeyedSubtree(
                key: ValueKey((showingMainActions, metrics.isDocked)),
                child: metrics.isDocked
                    ? ScrollableToolbarActions(
                        entries: entries,
                        maxWidth: maxWidth - metrics.pillPadding * 2,
                        height: metrics.buttonSize,
                        verticalInset: metrics.pillPadding,
                      )
                    : IntrinsicHeight(
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
                                  icon: const Icon(Icons.more_horiz_rounded),
                                  onPressed: () =>
                                      onShowOverflow(buttonContext),
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
  final Widget icon;
  final VoidCallback? onPressed;
  final bool selected;
  final double dockProgress;

  const ToolbarIconButton({
    super.key,
    required this.size,
    required this.icon,
    required this.onPressed,
    this.selected = false,
    this.dockProgress = 1,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: IconButton(
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: selected
              ? Color.lerp(
                  colorScheme.primary, colorScheme.secondary, dockProgress)
              : null,
          foregroundColor: selected
              ? Color.lerp(
                  colorScheme.onPrimary, colorScheme.onSecondary, dockProgress)
              : null,
        ),
        icon: icon,
        onPressed: onPressed,
      ),
    );
  }
}
