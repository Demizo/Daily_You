// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/mood.dart';
import 'package:daily_you/models/mood_scale_level.dart';
import 'package:daily_you/models/tag_icon_type.dart';
import 'package:daily_you/utils/generated/tag_icon_registry.dart';
import 'package:material_ui/material_ui.dart';

enum MoodScalePreset {
  emoji,
  icons,
  colors;

  List<MoodScaleLevel> get levels => switch (this) {
        emoji => _emojiLevels,
        icons => _iconLevels,
        colors => _colorLevels,
      };

  static final _red = Colors.red.shade500.toARGB32();
  static final _orange = Colors.orange.shade600.toARGB32();
  static final _yellow = Colors.yellow.shade700.toARGB32();
  static final _green = Colors.green.shade600.toARGB32();
  static final _cyan = Colors.cyan.shade700.toARGB32();
  static final _lightBlue = Colors.lightBlue.shade600.toARGB32();
  static final _blueGrey = Colors.blueGrey.shade500.toARGB32();

  static final _moodColors = [_red, _lightBlue, _blueGrey, _green, _yellow];

  static final _emojiLevels = [
    for (final (position, emoji) in ['😔', '😕', '😐', '🙂', '☺️'].indexed)
      MoodScaleLevel(
        mood: Mood.fromPosition(position),
        icon: emoji,
        color: _moodColors[position],
      ),
  ];

  static final _iconLevels = [
    for (final (position, icon) in [
      TagIconKey.moodBad,
      TagIconKey.sentimentDissatisfied,
      TagIconKey.sentimentNeutral,
      TagIconKey.sentimentSatisfied,
      TagIconKey.sentimentVerySatisfied,
    ].indexed)
      MoodScaleLevel(
        mood: Mood.fromPosition(position),
        icon: icon,
        iconType: TagIconType.materialIcon,
        color: _moodColors[position],
      ),
  ];

  static final _colorLevels = [
    for (final (position, color)
        in [_red, _orange, _yellow, _green, _cyan].indexed)
      MoodScaleLevel(
        mood: Mood.fromPosition(position),
        icon: TagIconKey.circle,
        iconType: TagIconType.materialIcon,
        color: color,
      ),
  ];
}
