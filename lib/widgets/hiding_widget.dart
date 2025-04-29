import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

enum HideDirection { up, down, left, right }

class HidingWidget extends StatefulWidget {
  const HidingWidget({
    super.key,
    required this.child,
    required this.scrollController,
    this.duration = const Duration(milliseconds: 300),
    required this.hideDirection,
    this.focusNode,
  });

  final Widget child;
  final ScrollController scrollController;
  final Duration duration;
  final HideDirection hideDirection;
  final FocusNode? focusNode;

  @override
  State<HidingWidget> createState() => _HidingWidgetState();
}

class _HidingWidgetState extends State<HidingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_listen);

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _offsetAnimation = _createTween().animate(_controller);
  }

  Tween<Offset> _createTween() {
    switch (widget.hideDirection) {
      case HideDirection.up:
        return Tween(begin: Offset.zero, end: const Offset(0, -1));
      case HideDirection.down:
        return Tween(begin: Offset.zero, end: const Offset(0, 1));
      case HideDirection.left:
        return Tween(begin: Offset.zero, end: const Offset(-1, 0));
      case HideDirection.right:
        return Tween(begin: Offset.zero, end: const Offset(1, 0));
    }
  }

  void _listen() {
    if (!mounted) return;

    if (widget.focusNode == null || !widget.focusNode!.hasFocus) {
      final direction = widget.scrollController.position.userScrollDirection;
      if (direction == ScrollDirection.forward) {
        if (_controller.status != AnimationStatus.reverse &&
            _controller.status != AnimationStatus.dismissed) {
          _controller.reverse();
        }
      } else if (direction == ScrollDirection.reverse) {
        if (_controller.status != AnimationStatus.forward &&
            _controller.status != AnimationStatus.completed) {
          _controller.forward();
        }
      }
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_listen);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: widget.child,
    );
  }
}
