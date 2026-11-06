// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/mood.dart';
import 'package:daily_you/providers/mood_scale_provider.dart';
import 'package:daily_you/utils/mood_scale_visuals.dart';
import 'package:daily_you/widgets/animated_values.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class MoodTierBar extends StatelessWidget {
  const MoodTierBar({super.key, required this.shares});

  static const double _height = 10;
  static const double _gap = 1.5;
  static const int _flexResolution = 1000;

  final List<double> shares;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final moodScale = context.watch<MoodScaleProvider>();

    return ClipRRect(
      borderRadius: BorderRadius.circular(_height / 2),
      child: SizedBox(
        height: _height,
        child: ColoredBox(
          color: colorScheme.surfaceContainerHighest,
          child: AnimatedValues(
            values: shares,
            builder: (context, animatedShares) => Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (position, share) in animatedShares.indexed)
                  if (share! > 0)
                    Expanded(
                      flex: (share * _flexResolution).ceil(),
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: _gap / 2),
                        child: ColoredBox(
                          color: moodScale
                                  .levelOf(Mood.fromPosition(position))
                                  ?.resolvedColor(context) ??
                              colorScheme.primary,
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
