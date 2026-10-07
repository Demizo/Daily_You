// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:material_ui/material_ui.dart';

const Duration _dialogDuration = Duration(milliseconds: 220);
const double _exitDurationFraction = 150 / 220;
const double _enterSlideDistance = 20;
const double _exitSlideDistance = -10;

const Curve _enterCurve = Cubic(0.2, 0.0, 0.0, 1.0);
const Curve _exitCurve = FlippedCurve(
  Interval(0.0, _exitDurationFraction, curve: Cubic(0.3, 0.0, 1.0, 1.0)),
);

Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    animationStyle: const AnimationStyle(
      duration: _dialogDuration,
      curve: _enterCurve,
      reverseCurve: _exitCurve,
    ),
    builder: (context) => _DialogSlide(child: builder(context)),
  );
}

class _DialogSlide extends StatefulWidget {
  const _DialogSlide({required this.child});

  final Widget child;

  @override
  State<_DialogSlide> createState() => _DialogSlideState();
}

class _DialogSlideState extends State<_DialogSlide> {
  CurvedAnimation? _progress;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final routeAnimation = ModalRoute.of(context)?.animation;
    if (routeAnimation == null || _progress?.parent == routeAnimation) return;
    _progress?.dispose();
    _progress = CurvedAnimation(
      parent: routeAnimation,
      curve: _enterCurve,
      reverseCurve: _exitCurve,
    );
  }

  @override
  void dispose() {
    _progress?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    if (progress == null || MediaQuery.disableAnimationsOf(context)) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: progress,
      child: RepaintBoundary(child: widget.child),
      builder: (context, child) {
        final distance = progress.status == AnimationStatus.reverse
            ? _exitSlideDistance
            : _enterSlideDistance;
        return Transform.translate(
          offset: Offset(0, distance * (1 - progress.value)),
          child: child,
        );
      },
    );
  }
}
