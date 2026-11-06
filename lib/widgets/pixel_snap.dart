// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

class PixelSnap extends SingleChildRenderObjectWidget {
  const PixelSnap({super.key, super.child});

  static List<ScrollPosition> _scrollPositionsAbove(BuildContext context) {
    final positions = <ScrollPosition>[];
    context.visitAncestorElements((element) {
      if (element is StatefulElement && element.state is ScrollableState) {
        positions.add((element.state as ScrollableState).position);
      }
      return true;
    });
    return positions;
  }

  @override
  RenderPixelSnap createRenderObject(BuildContext context) => RenderPixelSnap(
        devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
        scrollPositions: _scrollPositionsAbove(context),
      );

  @override
  void updateRenderObject(BuildContext context, RenderPixelSnap renderObject) {
    renderObject
      ..devicePixelRatio = MediaQuery.devicePixelRatioOf(context)
      ..scrollPositions = _scrollPositionsAbove(context);
  }
}

class RenderPixelSnap extends RenderProxyBox {
  RenderPixelSnap({
    required double devicePixelRatio,
    required List<ScrollPosition> scrollPositions,
  })  : _devicePixelRatio = devicePixelRatio,
        _scrollPositions = scrollPositions;

  double _devicePixelRatio;
  List<ScrollPosition> _scrollPositions;

  set devicePixelRatio(double value) {
    if (_devicePixelRatio == value) return;
    _devicePixelRatio = value;
    markNeedsPaint();
  }

  set scrollPositions(List<ScrollPosition> value) {
    if (listEquals(_scrollPositions, value)) return;
    if (attached) _removeScrollListeners();
    _scrollPositions = value;
    if (attached) _addScrollListeners();
    markNeedsPaint();
  }

  void _addScrollListeners() {
    for (final position in _scrollPositions) {
      position.addListener(markNeedsPaint);
    }
  }

  void _removeScrollListeners() {
    for (final position in _scrollPositions) {
      position.removeListener(markNeedsPaint);
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _addScrollListeners();
  }

  @override
  void detach() {
    _removeScrollListeners();
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final global = localToGlobal(Offset.zero);
    if (!global.isFinite) {
      super.paint(context, offset);
      return;
    }
    final snapped = Offset(
      (global.dx * _devicePixelRatio).roundToDouble() / _devicePixelRatio,
      (global.dy * _devicePixelRatio).roundToDouble() / _devicePixelRatio,
    );
    super.paint(context, offset + (snapped - global));
  }
}
