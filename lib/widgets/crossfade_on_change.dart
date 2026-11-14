// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

class CrossfadeOnChange extends StatefulWidget {
  const CrossfadeOnChange({
    super.key,
    required this.changeKey,
    required this.child,
  });

  final Object? changeKey;
  final Widget child;

  @override
  State<CrossfadeOnChange> createState() => _CrossfadeOnChangeState();
}

class _CrossfadeOnChangeState extends State<CrossfadeOnChange>
    with SingleTickerProviderStateMixin {
  final GlobalKey _boundaryKey = GlobalKey();
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 150),
    value: 1,
  )..addStatusListener(_onStatusChanged);
  ui.Image? _previous;

  void _onStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    setState(_releasePrevious);
  }

  void _releasePrevious() {
    _previous?.dispose();
    _previous = null;
  }

  ui.Image? _captureCurrent() {
    final boundary = _boundaryKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary ||
        !boundary.hasSize ||
        boundary.debugNeedsPaint) {
      return null;
    }
    return boundary.toImageSync(
        pixelRatio: MediaQuery.devicePixelRatioOf(context));
  }

  @override
  void didUpdateWidget(CrossfadeOnChange oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.changeKey == oldWidget.changeKey) return;
    _releasePrevious();
    _previous = _captureCurrent();
    _controller.forward(from: _previous == null ? 1 : 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    _previous?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previous = _previous;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (previous != null)
          IgnorePointer(
            child: FadeTransition(
              opacity: ReverseAnimation(_controller),
              child: RawImage(image: previous, fit: BoxFit.fill),
            ),
          ),
        FadeTransition(
          opacity: _controller,
          child: RepaintBoundary(key: _boundaryKey, child: widget.child),
        ),
      ],
    );
  }
}
