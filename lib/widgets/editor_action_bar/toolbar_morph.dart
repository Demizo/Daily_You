import 'package:flutter/material.dart';

const Duration toolbarMorphDuration = Duration(milliseconds: 260);
const Curve toolbarMorphCurve = Curves.easeOutCubic;

class MorphContent extends StatefulWidget {
  final Widget child;

  const MorphContent({super.key, required this.child});

  @override
  State<MorphContent> createState() => _MorphContentState();
}

class _MorphContentState extends State<MorphContent>
    with SingleTickerProviderStateMixin {
  static const Duration _fadeOutDuration = Duration(milliseconds: 90);
  static const Duration _fadeInDuration = Duration(milliseconds: 200);

  late final AnimationController _controller;
  late Widget _displayedChild;
  Widget? _pendingChild;
  bool _fadingOut = false;

  @override
  void initState() {
    super.initState();
    _displayedChild = widget.child;
    _controller = AnimationController(
      vsync: this,
      duration: _fadeInDuration,
      value: 1.0,
    );
  }

  @override
  void didUpdateWidget(covariant MorphContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.child.key != oldWidget.child.key) {
      if (_fadingOut) {
        _pendingChild = widget.child;
      } else {
        _startTransition(widget.child);
      }
    } else if (!_fadingOut) {
      _displayedChild = widget.child;
    }
  }

  Future<void> _startTransition(Widget target) async {
    _fadingOut = true;
    _controller.duration = _fadeOutDuration;
    await _controller.animateTo(0.0, curve: Curves.easeIn);
    if (!mounted) return;

    setState(() => _displayedChild = _pendingChild ?? target);
    _pendingChild = null;

    _controller.duration = _fadeInDuration;
    _fadingOut = false;
    await _controller.animateTo(1.0, curve: Curves.easeOut);
    if (!mounted) return;

    final queued = _pendingChild;
    if (queued != null) {
      _pendingChild = null;
      _startTransition(queued);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.94, end: 1.0).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutBack)),
        child: _displayedChild,
      ),
    );
  }
}
