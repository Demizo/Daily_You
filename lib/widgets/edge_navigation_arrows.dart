// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:async';

import 'package:daily_you/utils/edge_arrow_region.dart';
import 'package:daily_you/widgets/desktop_arrow_button.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

Future<void> stepToPage(PageController controller, int page) =>
    controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );

class EdgeNavigationArrows extends StatefulWidget {
  const EdgeNavigationArrows({
    super.key,
    required this.child,
    this.onBackward,
    this.onForward,
    this.topInset = 0,
  });

  final Widget child;
  final VoidCallback? onBackward;
  final VoidCallback? onForward;
  final double topInset;

  @override
  State<EdgeNavigationArrows> createState() => _EdgeNavigationArrowsState();
}

class _EdgeNavigationArrowsState extends State<EdgeNavigationArrows> {
  static const double _arrowInset = 16;
  static const Duration _idleDuration = Duration(seconds: 2);
  static const Duration _fadeDuration = Duration(milliseconds: 150);

  Timer? _idleTimer;
  Size _size = Size.zero;
  bool _visible = false;

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }

  bool _isInRegion(Offset position) {
    final isRightToLeft = Directionality.of(context) == TextDirection.rtl;
    bool inRegionOf({required bool leftSide}) => isInEdgeArrowRegion(
          position: position,
          leftSide: leftSide,
          size: _size,
          topInset: widget.topInset,
        );
    return (widget.onBackward != null &&
            inRegionOf(leftSide: !isRightToLeft)) ||
        (widget.onForward != null && inRegionOf(leftSide: isRightToLeft));
  }

  void _setVisible(bool visible) {
    _idleTimer?.cancel();
    if (visible) _idleTimer = Timer(_idleDuration, _hide);
    if (visible != _visible) setState(() => _visible = visible);
  }

  void _hide() {
    if (mounted) _setVisible(false);
  }

  Widget _arrow({required bool forward, required VoidCallback? onPressed}) {
    if (onPressed == null) return const SizedBox.shrink();
    return Positioned.fill(
      child: Padding(
        padding: EdgeInsets.only(top: widget.topInset),
        child: Align(
          alignment: forward
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _arrowInset),
            child: IgnorePointer(
              ignoring: !_visible,
              child: AnimatedOpacity(
                opacity: _visible ? 1 : 0,
                duration: _fadeDuration,
                child: DesktopArrowButton(
                  forward: forward,
                  onPressed: onPressed,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isDesktopPlatform) return widget.child;
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = constraints.biggest;
        return MouseRegion(
          onHover: (PointerHoverEvent event) =>
              _setVisible(_isInRegion(event.localPosition)),
          onExit: (_) => _hide(),
          child: Stack(
            fit: StackFit.expand,
            children: [
              widget.child,
              _arrow(forward: false, onPressed: widget.onBackward),
              _arrow(forward: true, onPressed: widget.onForward),
            ],
          ),
        );
      },
    );
  }
}
