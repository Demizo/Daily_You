// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/providers/mood_scale_provider.dart';
import 'package:material_ui/material_ui.dart';

const int _maxLabelCharacters = 250;

String entrySemanticsLabel(BuildContext context, Entry entry, String title) {
  final mood = MoodScaleProvider.instance
      .moodPrefixOf(entry.mood, AppLocalizations.of(context)!)
      .trim();
  final text = entry.text.length > _maxLabelCharacters
      ? entry.text.substring(0, _maxLabelCharacters)
      : entry.text;
  return [title, mood, text].where((part) => part.isNotEmpty).join('. ');
}
