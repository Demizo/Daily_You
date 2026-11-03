// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations_en.dart';
import 'package:daily_you/models/mood.dart';
import 'package:daily_you/models/mood_scale_level.dart';
import 'package:daily_you/models/tag_icon_type.dart';
import 'package:daily_you/utils/mood_scale_visuals.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();
  final worst = Mood.levels.first;

  test('a blank label falls back to the default for the level', () {
    expect(MoodScaleLevel(mood: worst).displayLabel(l10n), 'Very Unpleasant');
    expect(MoodScaleLevel(mood: worst, label: '  ').displayLabel(l10n),
        'Very Unpleasant');
    expect(MoodScaleLevel(mood: worst, label: 'Awful').displayLabel(l10n),
        'Awful');
  });

  test('plain text is the character icon, else the label', () {
    expect(MoodScaleLevel(mood: worst, icon: '😔').plainText(l10n), '😔');
    expect(
        MoodScaleLevel(
          mood: worst,
          icon: 'mood_bad',
          iconType: TagIconType.materialIcon,
        ).plainText(l10n),
        'Very Unpleasant');
    expect(
        MoodScaleLevel(mood: worst, label: 'Awful').plainText(l10n), 'Awful');
  });
}
