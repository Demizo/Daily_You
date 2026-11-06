// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/widgets/morphing_burst.dart';
import 'package:material_ui/material_ui.dart';

class FlameBadge extends StatelessWidget {
  const FlameBadge({
    super.key,
    required this.size,
    required this.color,
    required this.flameColor,
  });

  final double size;
  final Color color;
  final Color flameColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: MorphingBurstPainter(progress: 1, color: color),
        child: Center(
          child: Icon(Icons.local_fire_department_rounded,
              size: size * 0.5, color: flameColor),
        ),
      ),
    );
  }
}
