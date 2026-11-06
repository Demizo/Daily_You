// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:material_ui/material_ui.dart';

const Duration statsAnimationDuration = Duration(milliseconds: 200);
const Curve statsAnimationCurve = Curves.easeInOut;

typedef AnimatedValuesBuilder = Widget Function(
    BuildContext context, List<double?> values);

class AnimatedValues extends StatelessWidget {
  const AnimatedValues(
      {super.key, required this.values, required this.builder});

  final List<double?> values;
  final AnimatedValuesBuilder builder;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<List<double?>>(
        tween: _ValuesTween(end: values),
        duration: statsAnimationDuration,
        curve: statsAnimationCurve,
        builder: (context, animatedValues, _) =>
            builder(context, animatedValues),
      );
}

class _ValuesTween extends Tween<List<double?>> {
  _ValuesTween({required List<double?> super.end});

  @override
  List<double?> lerp(double t) {
    final from = begin!;
    final to = end!;
    if (from.length != to.length) return to;
    return [
      for (var index = 0; index < to.length; index++)
        from[index] == null || to[index] == null
            ? to[index]
            : from[index]! + (to[index]! - from[index]!) * t,
    ];
  }
}
