import 'package:flutter/material.dart';

class PunchScale extends StatefulWidget {
  final Widget child;
  final bool trigger;

  const PunchScale({required this.child, required this.trigger, super.key});

  @override
  State<PunchScale> createState() => _PunchScaleState();
}

class _PunchScaleState extends State<PunchScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    _scale = AlwaysStoppedAnimation(widget.trigger ? 1.3 : 1.0);
  }

  @override
  void didUpdateWidget(covariant PunchScale oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      final punchTween = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.4)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 50, // fast rise
        ),
        TweenSequenceItem(
          tween: Tween(begin: 1.4, end: 1.3)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 50, // longer settle
        ),
      ]);
      _scale = punchTween.animate(_controller);
      _controller.forward(from: 0.0);
    } else if (!widget.trigger && oldWidget.trigger) {
      final shrinkTween = Tween<double>(begin: 1.3, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOut));

      _scale = shrinkTween.animate(_controller);
      _controller.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) {
        return Transform.scale(scale: _scale.value, child: child);
      },
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
