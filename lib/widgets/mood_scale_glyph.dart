// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:daily_you/models/mood_scale_level.dart';
import 'package:daily_you/utils/generated/tag_icon_registry.dart';
import 'package:daily_you/utils/mood_scale_visuals.dart';
import 'package:material_ui/material_ui.dart';

class MoodScaleGlyph extends StatelessWidget {
  static const double _materialIconScale = 1.3;

  final MoodScaleLevel level;
  final double size;
  final bool allowScaling;

  const MoodScaleGlyph({
    super.key,
    required this.level,
    required this.size,
    this.allowScaling = true,
  });

  @override
  Widget build(BuildContext context) {
    final textScaler =
        allowScaling ? MediaQuery.textScalerOf(context) : TextScaler.noScaling;
    final textStyle = TextStyle(
      fontSize: size,
      fontFamily: Platform.isLinux ? 'Noto Color Emoji' : null,
    );
    if (level.hasTextIcon) {
      return Text(level.icon!, style: textStyle, textScaler: textScaler);
    }

    return Icon(
      lookupTagIcon(level.icon) ?? Icons.circle_rounded,
      size: textScaler.scale(size) * _materialIconScale,
      color: level.resolvedColor(context),
    );
  }
}
