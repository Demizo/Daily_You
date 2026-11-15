// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

class OnboardingProgressBar extends StatelessWidget {
  static const double _checkSize = 20;
  static const double _segmentHeight = 6;
  static const double _gap = 4;

  const OnboardingProgressBar({
    super.key,
    required this.count,
    required this.position,
  });

  final int count;
  final ValueListenable<double> position;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: position,
      builder: (context, value, _) => Row(
        spacing: _gap,
        children: [
          for (var index = 0; index < count; index++) ...[
            Expanded(child: _Segment(fill: _fill(value, index))),
            _Check(fill: _checkFill(value, index)),
          ],
        ],
      ),
    );
  }

  static double _fill(double position, int index) =>
      (position + 1 - index).clamp(0.0, 1.0);

  static double _checkFill(double position, int index) =>
      (_fill(position, index) * 2 - 1).clamp(0.0, 1.0);
}

class _Check extends StatelessWidget {
  const _Check({required this.fill});

  final double fill;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Transform.scale(
      scale: 0.85 + 0.15 * fill,
      child: Container(
        width: OnboardingProgressBar._checkSize,
        height: OnboardingProgressBar._checkSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              Color.lerp(colorScheme.outlineVariant, colorScheme.primary, fill),
        ),
        child: Icon(
          Icons.check_rounded,
          size: 13,
          color: Color.lerp(Colors.transparent, colorScheme.onPrimary, fill),
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.fill});

  final double fill;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(OnboardingProgressBar._segmentHeight / 2),
      child: Container(
        height: OnboardingProgressBar._segmentHeight,
        color: colorScheme.outlineVariant,
        alignment: AlignmentDirectional.centerStart,
        child: FractionallySizedBox(
          widthFactor: fill,
          heightFactor: 1,
          child: ColoredBox(color: colorScheme.primary),
        ),
      ),
    );
  }
}
