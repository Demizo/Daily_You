// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:ui' show lerpDouble;

import 'package:daily_you/widgets/editor_action_bar/dock_metrics.dart';
import 'package:daily_you/widgets/editor_action_bar/toolbar_entry.dart';
import 'package:daily_you/widgets/editor_action_bar/toolbar_morph.dart';
import 'package:material_ui/material_ui.dart';

class ActionBarPill extends StatelessWidget {
  static const double _iconTintHandoff = 0.5;

  final DockMetrics metrics;
  final ToolbarEntrySplit split;
  final List<ToolbarEntry> entries;
  final List<ToolbarEntry> scrollEntries;
  final List<ToolbarEntry> fixedEntries;
  final double maxWidth;
  final bool showingMainActions;
  final void Function(BuildContext buttonContext) onShowOverflow;

  const ActionBarPill({
    super.key,
    required this.metrics,
    required this.split,
    required this.entries,
    required this.scrollEntries,
    required this.fixedEntries,
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
          padding: EdgeInsets.all(metrics.pillPadding),
          child: IconTheme.merge(
            data: IconThemeData(color: iconTint),
            child: MorphContent(
              child: KeyedSubtree(
                key: ValueKey((showingMainActions, metrics.progress >= 0.5)),
                child: metrics.progress >= 0.5
                    ? _ScrollableActions(
                        entries: scrollEntries,
                        fixedEntries: fixedEntries,
                        maxWidth: maxWidth,
                        height: metrics.buttonSize,
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

class _ScrollableActions extends StatefulWidget {
  final List<ToolbarEntry> entries;
  final List<ToolbarEntry> fixedEntries;
  final double maxWidth;
  final double height;

  const _ScrollableActions({
    required this.entries,
    required this.fixedEntries,
    required this.maxWidth,
    required this.height,
  });

  @override
  State<_ScrollableActions> createState() => _ScrollableActionsState();
}

class _ScrollableActionsState extends State<_ScrollableActions> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_update);
  }

  void _update() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_update);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fixedWidth = widget.fixedEntries
        .fold<double>(0, (width, entry) => width + entry.width);
    final scrollMaxWidth =
        (widget.maxWidth - fixedWidth).clamp(0.0, widget.maxWidth);
    final contentWidth =
        widget.entries.fold<double>(0, (total, entry) => total + entry.width);
    final viewportWidth = contentWidth.clamp(0.0, scrollMaxWidth);
    final position = _controller.hasClients ? _controller.position : null;
    final hasStart =
        position?.extentBefore != null && position!.extentBefore > 0;
    final hasEnd = position?.extentAfter != null
        ? position!.extentAfter > 0
        : contentWidth > viewportWidth;
    final surface = Theme.of(context).colorScheme.surfaceContainerHigh;

    Widget indicator(IconData icon) => IgnorePointer(
          child: ColoredBox(
            color: surface.withValues(alpha: 0.9),
            child: Icon(icon, size: 16),
          ),
        );

    return Row(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: viewportWidth,
        height: widget.height,
        child: Stack(
          children: [
            SingleChildScrollView(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: SizedBox(
                height: widget.height,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final entry in widget.entries)
                      entry.build(context, null),
                  ],
                ),
              ),
            ),
            if (hasStart)
              PositionedDirectional(
                start: 0,
                top: 0,
                bottom: 0,
                child: indicator(Directionality.of(context) == TextDirection.ltr
                    ? Icons.chevron_left
                    : Icons.chevron_right),
              ),
            if (hasEnd)
              PositionedDirectional(
                end: 0,
                top: 0,
                bottom: 0,
                child: indicator(Directionality.of(context) == TextDirection.ltr
                    ? Icons.chevron_right
                    : Icons.chevron_left),
              ),
          ],
        ),
      ),
      for (final entry in widget.fixedEntries) entry.build(context, null),
    ]);
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
