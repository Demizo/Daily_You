// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/mood_scale_level.dart';
import 'package:daily_you/providers/mood_scale_provider.dart';
import 'package:daily_you/widgets/mood_scale_glyph.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class MoodIcon extends StatelessWidget {
  final int? moodValue;
  final double size;
  final bool allowScaling;

  const MoodIcon({
    super.key,
    this.moodValue,
    this.size = 20,
    this.allowScaling = true,
  });

  @override
  Widget build(BuildContext context) {
    final level = context.select<MoodScaleProvider, MoodScaleLevel?>(
      (provider) => provider.levelOf(moodValue),
    );
    if (level == null) return const SizedBox.shrink();

    return MoodScaleGlyph(
      level: level,
      size: size,
      allowScaling: allowScaling,
    );
  }
}
