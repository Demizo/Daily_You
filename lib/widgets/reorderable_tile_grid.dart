// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/widgets/stat_tile.dart';
import 'package:daily_you/widgets/wiggle.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

class ReorderableTileGrid extends StatefulWidget {
  const ReorderableTileGrid({
    super.key,
    required this.gridDelegate,
    required this.children,
    required this.isEditing,
    required this.onEditStart,
    required this.onReorder,
  });

  final SliverGridDelegate gridDelegate;
  final List<Widget> children;
  final bool isEditing;
  final VoidCallback onEditStart;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  State<ReorderableTileGrid> createState() => _ReorderableTileGridState();
}

class _ReorderableTileGridState extends State<ReorderableTileGrid> {
  static const Duration _slideDuration = Duration(milliseconds: 400);
  static const Duration _editStartDelay = Duration(milliseconds: 600);
  static const Duration _dragStartDelay = Duration(milliseconds: 200);
  static const double _wigglePhaseStep = 0.382;
  static const double _autoScrollVelocityScalar = 50;
  static const double _settledDistance = 0.5;

  final OverlayPortalController _overlayController = OverlayPortalController();
  final LayerLink _gridLink = LayerLink();
  late EdgeDraggingAutoScroller _autoScroller;
  late SliverGridLayout _layout;
  late TextDirection _textDirection;

  Key? _draggedKey;
  bool _isSettling = false;
  int _targetIndex = 0;
  Offset _grabOffset = Offset.zero;
  Offset _pointerPosition = Offset.zero;
  Offset _draggedTopLeft = Offset.zero;

  int get _draggedIndex =>
      widget.children.indexWhere((child) => child.key == _draggedKey);

  RenderBox get _gridBox => context.findRenderObject()! as RenderBox;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _autoScroller = EdgeDraggingAutoScroller(
      Scrollable.of(context),
      onScrollViewScrolled: _updateDrag,
      velocityScalar: _autoScrollVelocityScalar,
    );
  }

  @override
  void dispose() {
    _autoScroller.stopAutoScroll();
    super.dispose();
  }

  Rect _slotRect(int index) {
    final geometry = _layout.getGeometryForChildIndex(index);
    return Rect.fromLTWH(
      geometry.crossAxisOffset,
      geometry.scrollOffset,
      geometry.crossAxisExtent,
      geometry.mainAxisExtent,
    );
  }

  List<int> _displayOrder() {
    final order = [
      for (var index = 0; index < widget.children.length; index++) index
    ];
    final draggedIndex = _draggedIndex;
    if (draggedIndex < 0) return order;
    order.remove(draggedIndex);
    order.insert(_targetIndex, draggedIndex);
    return order;
  }

  int _nearestSlotIndex(Offset point) {
    var nearest = 0;
    var nearestDistance = double.infinity;
    for (var index = 0; index < widget.children.length; index++) {
      final distance = (_slotRect(index).center - point).distanceSquared;
      if (distance < nearestDistance) {
        nearest = index;
        nearestDistance = distance;
      }
    }
    return nearest;
  }

  void _startDrag(Key key, Offset globalPosition) {
    final index = widget.children.indexWhere((child) => child.key == key);
    final slot = _slotRect(index);
    final localPosition = _gridBox.globalToLocal(globalPosition);
    _overlayController.show();
    setState(() {
      _draggedKey = key;
      _isSettling = false;
      _targetIndex = index;
      _grabOffset = localPosition - slot.topLeft;
      _pointerPosition = globalPosition;
      _draggedTopLeft = slot.topLeft;
    });
  }

  void _moveDrag(Offset globalPosition) {
    if (_draggedKey == null || _isSettling) return;
    _pointerPosition = globalPosition;
    _updateDrag();
  }

  void _updateDrag() {
    final draggedIndex = _draggedIndex;
    if (draggedIndex < 0 || _isSettling) return;
    final size = _slotRect(draggedIndex).size;
    final topLeft = _gridBox.globalToLocal(_pointerPosition) - _grabOffset;
    setState(() {
      _draggedTopLeft = topLeft;
      _targetIndex = _nearestSlotIndex(topLeft + size.center(Offset.zero));
    });
    _autoScroller.startAutoScrollIfNecessary(
      _gridBox.localToGlobal(topLeft) & size,
    );
  }

  void _endDrag() {
    if (_draggedKey == null || _isSettling) return;
    final oldIndex = _draggedIndex;
    final newIndex = _targetIndex;
    final slotTopLeft = _slotRect(newIndex).topLeft;
    _autoScroller.stopAutoScroll();
    setState(() => _isSettling = true);
    if (oldIndex >= 0 && oldIndex != newIndex) {
      widget.onReorder(oldIndex, newIndex);
    }
    if ((_draggedTopLeft - slotTopLeft).distance < _settledDistance) {
      _finishSettling();
    }
  }

  void _finishSettling() {
    if (!_isSettling) return;
    _overlayController.hide();
    setState(() {
      _draggedKey = null;
      _isSettling = false;
    });
  }

  Widget _onLongPress({
    required bool enabled,
    required Duration delay,
    required void Function(Offset globalPosition) onStart,
    required Widget child,
  }) {
    return RawGestureDetector(
      gestures: enabled
          ? {
              LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<
                  LongPressGestureRecognizer>(
                () => LongPressGestureRecognizer(duration: delay),
                (recognizer) => recognizer.onLongPressStart =
                    (details) => onStart(details.globalPosition),
              ),
            }
          : const {},
      child: child,
    );
  }

  Widget _buildTile(int index, {required bool wiggles}) {
    final child = widget.children[index];
    final key = child.key!;
    return Wiggle(
      enabled: wiggles && widget.isEditing,
      phase: (index * _wigglePhaseStep) % 1,
      child: _onLongPress(
        enabled: !widget.isEditing,
        delay: _editStartDelay,
        onStart: (globalPosition) {
          widget.onEditStart();
          _startDrag(key, globalPosition);
        },
        child: _onLongPress(
          enabled: widget.isEditing,
          delay: _dragStartDelay,
          onStart: (globalPosition) => _startDrag(key, globalPosition),
          child: child,
        ),
      ),
    );
  }

  Widget _buildDraggedTile(BuildContext context) {
    final draggedIndex = _draggedIndex;
    if (draggedIndex < 0) return const SizedBox.shrink();
    final slot = _slotRect(_targetIndex);
    return Align(
      alignment: Alignment.topLeft,
      child: TweenAnimationBuilder<Offset>(
        tween: Tween(end: _isSettling ? slot.topLeft : _draggedTopLeft),
        duration: _isSettling ? _slideDuration : Duration.zero,
        curve: Curves.easeOutCubic,
        onEnd: _finishSettling,
        builder: (context, topLeft, child) => CompositedTransformFollower(
          link: _gridLink,
          showWhenUnlinked: false,
          offset: topLeft,
          child: child,
        ),
        child: SizedBox.fromSize(
          size: slot.size,
          child: _Lift(
            isLifted: !_isSettling,
            child: _buildTile(draggedIndex, wiggles: false),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _textDirection = Directionality.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        _layout = widget.gridDelegate.getLayout(SliverConstraints(
          axisDirection: AxisDirection.down,
          growthDirection: GrowthDirection.forward,
          userScrollDirection: ScrollDirection.idle,
          scrollOffset: 0,
          precedingScrollExtent: 0,
          overlap: 0,
          remainingPaintExtent: double.infinity,
          crossAxisExtent: width,
          crossAxisDirection: _textDirection == TextDirection.ltr
              ? AxisDirection.right
              : AxisDirection.left,
          viewportMainAxisExtent: double.infinity,
          remainingCacheExtent: double.infinity,
          cacheOrigin: 0,
        ));
        final order = _displayOrder();
        final draggedIndex = _draggedIndex;
        return OverlayPortal(
          controller: _overlayController,
          overlayChildBuilder: _buildDraggedTile,
          child: Listener(
            onPointerMove: (event) => _moveDrag(event.position),
            onPointerUp: (_) => _endDrag(),
            onPointerCancel: (_) => _endDrag(),
            child: CompositedTransformTarget(
              link: _gridLink,
              child: SizedBox(
                width: width,
                height: _layout.computeMaxScrollOffset(widget.children.length),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (final index in order)
                      if (index != draggedIndex)
                        _positioned(index, order.indexOf(index)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _positioned(int index, int slotIndex) {
    final slot = _slotRect(slotIndex);
    return AnimatedPositioned(
      key: ValueKey(widget.children[index].key),
      duration: _slideDuration,
      curve: Curves.easeOutCubic,
      left: slot.left,
      top: slot.top,
      width: slot.width,
      height: slot.height,
      child: _buildTile(index, wiggles: true),
    );
  }
}

class _Lift extends StatelessWidget {
  const _Lift({required this.isLifted, required this.child});

  static const Duration _duration = Duration(milliseconds: 150);
  static const double _scale = 1.04;
  static const double _shadowBlur = 16;
  static const double _shadowAlpha = 0.35;

  final bool isLifted;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shadowColor = Theme.of(context).colorScheme.shadow;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: isLifted ? 1 : 0),
      duration: _duration,
      curve: Curves.easeInOut,
      builder: (context, progress, child) => Transform.scale(
        scale: 1 + (_scale - 1) * progress,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(StatTile.margin),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(StatTile.radius),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: _shadowBlur,
                        color: shadowColor.withValues(
                            alpha: _shadowAlpha * progress),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            child!,
          ],
        ),
      ),
      child: child,
    );
  }
}
