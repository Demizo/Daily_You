import 'dart:math';
import 'package:flutter/material.dart';

//Note: See https://github.com/flutter/flutter/issues/55103#issuecomment-747059541
class FastPageViewScrollPhysics extends ScrollPhysics {
  const FastPageViewScrollPhysics({super.parent});

  @override
  FastPageViewScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return FastPageViewScrollPhysics(parent: buildParent(ancestor)!);
  }

  @override
  SpringDescription get spring => noBounceSpring(0.10);

  SpringDescription noBounceSpring(double settleTimeSeconds) {
    const mass = 1.0;
    final stiffness = mass * pow(4 / settleTimeSeconds, 2);
    final damping = 2 * sqrt(stiffness * mass);

    return SpringDescription(
      mass: mass,
      stiffness: stiffness,
      damping: damping,
    );
  }
}
