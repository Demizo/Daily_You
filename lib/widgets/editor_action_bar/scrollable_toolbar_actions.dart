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

  const ScrollableToolbarActions({
    super.key,
    required this.entries,
    required this.maxWidth,
    required this.height,
  });

  @override
  State<ScrollableToolbarActions> createState() =>
      _ScrollableToolbarActionsState();
}

class _ScrollableToolbarActionsState extends State<ScrollableToolbarActions> {
  static const double _arrowSize = 16.0;
  static const double _fadeWidth = 16.0;
  static const double _pageFraction = 0.75;
  static const Duration _pageDuration = Duration(milliseconds: 200);

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
      {required bool hasStart, required bool hasEnd}) {
    const opaque = Color(0xFFFFFFFF);
    const transparent = Color(0x00FFFFFF);
    final fadeEnd = math.min(_arrowSize + _fadeWidth, bounds.width / 2);
    final arrowEnd = math.min(_arrowSize, fadeEnd);
    final startColor = hasStart ? transparent : opaque;
    final endColor = hasEnd ? transparent : opaque;
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

  Widget _arrow(IconData icon, {required bool towardEnd}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _page(towardEnd: towardEnd),
      child: SizedBox(
        width: _arrowSize,
        child: Center(child: Icon(icon, size: _arrowSize)),
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

    return SizedBox(
      width: viewportWidth,
      height: widget.height,
      child: Stack(
        children: [
          NotificationListener<Notification>(
            onNotification: _onNotification,
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (bounds) =>
                  _fadeShader(bounds, hasStart: hasStart, hasEnd: hasEnd),
              child: SingleChildScrollView(
                controller: _controller,
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
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
          ),
          if (hasStart)
            PositionedDirectional(
              start: 0,
              top: 0,
              bottom: 0,
              child: _arrow(
                isLeftToRight ? Icons.chevron_left : Icons.chevron_right,
                towardEnd: false,
              ),
            ),
          if (hasEnd)
            PositionedDirectional(
              end: 0,
              top: 0,
              bottom: 0,
              child: _arrow(
                isLeftToRight ? Icons.chevron_right : Icons.chevron_left,
                towardEnd: true,
              ),
            ),
        ],
      ),
    );
  }
}
