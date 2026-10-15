// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';

abstract final class Mood {
  static const int veryUnpleasant = 1;
  static const int unpleasant = 2;
  static const int neutral = 3;
  static const int pleasant = 4;
  static const int veryPleasant = 5;

  static const List<int> levels = [
    veryUnpleasant,
    unpleasant,
    neutral,
    pleasant,
    veryPleasant,
  ];

  static const int _legacyLowest = -2;

  static final int count = levels.length;

  static int position(int mood) => mood - veryUnpleasant;

  static int fromPosition(int position) => levels[position];

  static int? fromLegacy(int? legacyMood) => legacyMood == null
      ? null
      : fromPosition((legacyMood - _legacyLowest).clamp(0, count - 1));

  static int fromRating(int rating, {bool bestFirst = false}) {
    final position = rating.clamp(1, count) - 1;
    return fromPosition(bestFirst ? count - 1 - position : position);
  }

  static int compare(int? first, int? second) =>
      _rank(first).compareTo(_rank(second));

  static int _rank(int? mood) => mood == null ? -1 : position(mood);

  static bool isBadDay(int? mood) =>
      mood == veryUnpleasant || mood == unpleasant;

  static bool isGreatDay(int? mood) => mood == pleasant || mood == veryPleasant;

  static String defaultLabel(int position, AppLocalizations l10n) =>
      switch (position) {
        0 => l10n.moodVeryUnpleasant,
        1 => l10n.moodUnpleasant,
        2 => l10n.moodNeutral,
        3 => l10n.moodPleasant,
        _ => l10n.moodVeryPleasant,
      };
}
