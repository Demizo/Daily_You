// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/widgets/mood_icon.dart';
import 'package:daily_you/widgets/morphing_burst.dart';
import 'package:daily_you/widgets/pixel_snap.dart';
import 'package:daily_you/widgets/punch_scale.dart';
import 'package:material_ui/material_ui.dart';

class MoodOption extends StatelessWidget {
  const MoodOption({
    super.key,
    required this.mood,
    required this.isSelected,
    required this.onTap,
  });

  final int mood;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 52,
          height: 52,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            builder: (context, progress, child) {
              return PixelSnap(
                  child: CustomPaint(
                painter: MorphingBurstPainter(
                  progress: progress,
                  color: Color.lerp(
                    colorScheme.surfaceContainerLow,
                    colorScheme.surfaceContainerLowest,
                    progress,
                  )!,
                ),
                child: Center(child: child),
              ));
            },
            child: PunchScale(
              key: ValueKey(mood),
              trigger: isSelected,
              child: Opacity(
                  opacity: isSelected ? 1.0 : 0.6,
                  child: MoodIcon(
                    moodValue: mood,
                    size: 24,
                    allowScaling: false,
                  )),
            ),
          ),
        ),
      ),
    );
  }
}
