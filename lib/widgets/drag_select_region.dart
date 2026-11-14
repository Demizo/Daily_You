// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

class DragSelectItem extends StatelessWidget {
  const DragSelectItem({super.key, required this.itemId, required this.child});

  final int itemId;
  final Widget child;

  @override
  Widget build(BuildContext context) => MetaData(
        metaData: _DragSelectItemId(itemId),
        behavior: HitTestBehavior.translucent,
        child: child,
      );
}

class _DragSelectItemId {
  const _DragSelectItemId(this.value);

  final int value;
}

class DragSelectRegion extends StatefulWidget {
  const DragSelectRegion({
    super.key,
    required this.scrollController,
    required this.onStart,
    required this.onUpdate,
    required this.child,
  });

  final ScrollController scrollController;
  final ValueChanged<int> onStart;
  final ValueChanged<int> onUpdate;
  final Widget child;

  @override
  State<DragSelectRegion> createState() => _DragSelectRegionState();
}

class _DragSelectRegionState extends State<DragSelectRegion>
    with SingleTickerProviderStateMixin {
  static const double _edgeExtent = 72;
  static const double _maxScrollSpeed = 900;

  late final Ticker _ticker = createTicker(_onTick);
  Offset? _position;
  int? _lastItemId;
  double _scrollSpeed = 0;
  Duration _lastElapsed = Duration.zero;

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  int? _itemAt(Offset globalPosition) {
    final result = HitTestResult();
    WidgetsBinding.instance
        .hitTestInView(result, globalPosition, View.of(context).viewId);
    for (final hit in result.path) {
      final target = hit.target;
      if (target is RenderMetaData && target.metaData is _DragSelectItemId) {
        return (target.metaData as _DragSelectItemId).value;
      }
    }
    return null;
  }

  void _updateSelection() {
    final position = _position;
    if (position == null) return;
    final itemId = _itemAt(position);
    if (itemId == null || itemId == _lastItemId) return;
    _lastItemId = itemId;
    widget.onUpdate(itemId);
  }

  double _scrollSpeedAt(Offset globalPosition) {
    final box = context.findRenderObject() as RenderBox;
    final localY = box.globalToLocal(globalPosition).dy;
    final topDepth = (_edgeExtent - localY) / _edgeExtent;
    final bottomDepth =
        (localY - (box.size.height - _edgeExtent)) / _edgeExtent;
    if (topDepth > 0) return -math.min(topDepth, 1) * _maxScrollSpeed;
    if (bottomDepth > 0) return math.min(bottomDepth, 1) * _maxScrollSpeed;
    return 0;
  }

  void _onTick(Duration elapsed) {
    final deltaSeconds = (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    final controller = widget.scrollController;
    if (!controller.hasClients) return;
    final position = controller.position;
    position.jumpTo((position.pixels + _scrollSpeed * deltaSeconds)
        .clamp(position.minScrollExtent, position.maxScrollExtent));
    _updateSelection();
  }

  void _onLongPressStart(LongPressStartDetails details) {
    final itemId = _itemAt(details.globalPosition);
    if (itemId == null) return;
    _position = details.globalPosition;
    _lastItemId = itemId;
    widget.onStart(itemId);
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (_position == null) return;
    _position = details.globalPosition;
    _scrollSpeed = _scrollSpeedAt(details.globalPosition);
    if (_scrollSpeed != 0 && !_ticker.isActive) {
      _lastElapsed = Duration.zero;
      _ticker.start();
    } else if (_scrollSpeed == 0 && _ticker.isActive) {
      _ticker.stop();
    }
    _updateSelection();
  }

  void _onLongPressEnd() {
    _ticker.stop();
    _position = null;
    _lastItemId = null;
    _scrollSpeed = 0;
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPressStart: _onLongPressStart,
        onLongPressMoveUpdate: _onLongPressMoveUpdate,
        onLongPressEnd: (_) => _onLongPressEnd(),
        onLongPressCancel: _onLongPressEnd,
        child: widget.child,
      );
}
