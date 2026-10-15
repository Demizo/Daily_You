// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math';
import 'package:material_ui/material_ui.dart';

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
