// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math' as math;

import 'package:daily_you/widgets/animated_values.dart';
import 'package:material_ui/material_ui.dart';

class FrequencyBars extends StatelessWidget {
  const FrequencyBars({
    super.key,
    required this.values,
    required this.color,
    this.highlightedIndexes,
  });

  static const double _minimumBarHeight = 4;

  final List<double> values;
  final Color color;
  final List<int>? highlightedIndexes;

  @override
  Widget build(BuildContext context) {
    final peak = values.fold(0.0, math.max);
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        height: constraints.maxHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final (index, value) in values.indexed)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: AnimatedContainer(
                    duration: statsAnimationDuration,
                    curve: statsAnimationCurve,
                    height: _minimumBarHeight +
                        (constraints.maxHeight - _minimumBarHeight) *
                            (peak == 0 ? 0 : value / peak),
                    decoration: BoxDecoration(
                      color: highlightedIndexes == null ||
                              highlightedIndexes!.contains(index)
                          ? color
                          : color.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
