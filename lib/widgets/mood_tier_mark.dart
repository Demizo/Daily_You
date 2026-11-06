// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/mood.dart';
import 'package:daily_you/models/mood_scale_level.dart';
import 'package:daily_you/providers/mood_scale_provider.dart';
import 'package:daily_you/utils/chart_y_range.dart';
import 'package:daily_you/utils/mood_scale_visuals.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class MoodTierMark extends StatelessWidget {
  const MoodTierMark({super.key, required this.mood, this.size = defaultSize});

  static const double defaultSize = 30;
  static const double _axisSpace = 8;
  static const double axisWidth = defaultSize + _axisSpace;

  static final axisRange =
      FixedYRange(minY: 0, maxY: (Mood.count - 1).toDouble(), interval: 1);

  static Widget axisTitle(double value, TitleMeta meta) => SideTitleWidget(
        meta: meta,
        space: _axisSpace,
        child: MoodTierMark(mood: Mood.fromPosition(value.toInt())),
      );

  final int mood;
  final double size;

  @override
  Widget build(BuildContext context) {
    final level = context.select<MoodScaleProvider, MoodScaleLevel?>(
      (provider) => provider.levelOf(mood),
    );
    if (level == null || !level.hasTextIcon) {
      return SizedBox.square(
        dimension: size,
        child: Center(
          child:
              MoodIcon(moodValue: mood, size: size * 0.75, allowScaling: false),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border:
            Border.all(color: level.resolvedColor(context), width: size / 10),
      ),
      child: MoodIcon(moodValue: mood, size: size * 0.5, allowScaling: false),
    );
  }
}
