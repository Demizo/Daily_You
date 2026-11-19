// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math' as math;

import 'package:daily_you/widgets/editor_action_bar/toolbar_entry.dart';
import 'package:material_ui/material_ui.dart';

class ScrollableToolbarActions extends StatefulWidget {
  final List<ToolbarEntry> entries;
  final double maxWidth;
  final double height;
  final double verticalInset;

  const ScrollableToolbarActions({
    super.key,
    required this.entries,
    required this.maxWidth,
    required this.height,
    required this.verticalInset,
  });

  @override
  State<ScrollableToolbarActions> createState() =>
      _ScrollableToolbarActionsState();
}

class _ScrollableToolbarActionsState extends State<ScrollableToolbarActions> {
  static const double _arrowWidth = 32.0;
  static const double _arrowIconSize = 24.0;
  static const double _fadeWidth = 24.0;
  static const double _pageFraction = 0.75;
  static const Duration _pageDuration = Duration(milliseconds: 200);
  static const Duration _revealDuration = Duration(milliseconds: 150);

  final ScrollController _controller = ScrollController();
  bool _hasStart = false;
  bool? _hasEnd;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _onNotification(Notification notification) {
    final metrics = switch (notification) {
      ScrollMetricsNotification(:final metrics) => metrics,
      ScrollNotification(:final metrics) => metrics,
      _ => null,
    };
    if (metrics == null) return false;
    final hasStart = metrics.extentBefore > 0;
    final hasEnd = metrics.extentAfter > 0;
    if (hasStart != _hasStart || hasEnd != _hasEnd) {
      setState(() {
        _hasStart = hasStart;
        _hasEnd = hasEnd;
      });
    }
    return false;
  }

  void _page({required bool towardEnd}) {
    final position = _controller.position;
    final distance = position.viewportDimension * _pageFraction;
    _controller.animateTo(
      (position.pixels + (towardEnd ? distance : -distance))
          .clamp(0.0, position.maxScrollExtent),
      duration: _pageDuration,
      curve: Curves.easeOut,
    );
  }

  Shader _fadeShader(Rect bounds,
      {required double startAmount, required double endAmount}) {
    Color whiteWithAlpha(double alpha) => Color.fromRGBO(255, 255, 255, alpha);
    final opaque = whiteWithAlpha(1);
    final startColor = whiteWithAlpha(1 - startAmount);
    final endColor = whiteWithAlpha(1 - endAmount);
    final fadeEnd = math.min(_arrowWidth + _fadeWidth, bounds.width / 2);
    final arrowEnd = math.min(_arrowWidth, fadeEnd);
    return LinearGradient(
      begin: AlignmentDirectional.centerStart,
      end: AlignmentDirectional.centerEnd,
      colors: [startColor, startColor, opaque, opaque, endColor, endColor],
      stops: [
        0,
        arrowEnd / bounds.width,
        fadeEnd / bounds.width,
        1 - fadeEnd / bounds.width,
        1 - arrowEnd / bounds.width,
        1,
      ],
    ).createShader(bounds, textDirection: Directionality.of(context));
  }

  Widget _arrow(IconData icon,
      {required bool towardEnd, required double opacity}) {
    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _page(towardEnd: towardEnd),
        child: SizedBox(
          width: _arrowWidth,
          child: Center(
            child: Icon(
              icon,
              size: _arrowIconSize,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contentWidth =
        widget.entries.fold<double>(0, (total, entry) => total + entry.width);
    final viewportWidth = math.min(contentWidth, widget.maxWidth);
    final hasStart = _hasStart;
    final hasEnd = _hasEnd ?? contentWidth > viewportWidth;
    final isLeftToRight = Directionality.of(context) == TextDirection.ltr;

    final scrollView = NotificationListener<Notification>(
      onNotification: _onNotification,
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: widget.verticalInset),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final entry in widget.entries) entry.build(context, null),
            ],
          ),
        ),
      ),
    );

    return SizedBox(
      width: viewportWidth,
      height: widget.height + widget.verticalInset * 2,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: hasStart ? 1.0 : 0.0),
        duration: _revealDuration,
        builder: (context, startAmount, _) => TweenAnimationBuilder<double>(
          tween: Tween(end: hasEnd ? 1.0 : 0.0),
          duration: _revealDuration,
          builder: (context, endAmount, _) => Stack(
            children: [
              ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (bounds) => _fadeShader(bounds,
                    startAmount: startAmount, endAmount: endAmount),
                child: scrollView,
              ),
              if (startAmount > 0)
                PositionedDirectional(
                  start: 0,
                  top: 0,
                  bottom: 0,
                  child: _arrow(
                    isLeftToRight
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                    towardEnd: false,
                    opacity: startAmount,
                  ),
                ),
              if (endAmount > 0)
                PositionedDirectional(
                  end: 0,
                  top: 0,
                  bottom: 0,
                  child: _arrow(
                    isLeftToRight
                        ? Icons.chevron_right_rounded
                        : Icons.chevron_left_rounded,
                    towardEnd: true,
                    opacity: endAmount,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
