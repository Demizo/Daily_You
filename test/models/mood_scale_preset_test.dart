// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/mood.dart';
import 'package:daily_you/models/mood_scale_preset.dart';
import 'package:daily_you/widgets/color_picker_dialog.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('each preset covers every level from worst to best', () {
    for (final preset in MoodScalePreset.values) {
      expect(preset.levels.map((level) => level.mood), Mood.levels);
    }
  });

  test('presets leave labels to the user', () {
    for (final preset in MoodScalePreset.values) {
      expect(preset.levels.map((level) => level.label), everyElement(isNull));
    }
  });

  test('every preset color is in the color picker palette', () {
    final palette = tagColorPalette.map((color) => color.toARGB32()).toSet();

    for (final preset in MoodScalePreset.values) {
      expect(
        preset.levels.map((level) => level.color),
        everyElement(isIn(palette)),
      );
    }
  });

  test('the icon and emoji presets share five distinct colors, yellow last',
      () {
    final colors = MoodScalePreset.icons.levels.map((level) => level.color);

    expect(colors, everyElement(isNotNull));
    expect(colors.toSet(), hasLength(Mood.count));
    expect(MoodScalePreset.emoji.levels.map((level) => level.color), colors);
    expect(colors.last, Colors.yellow.shade700.toARGB32());
  });
}
