// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/mood.dart';
import 'package:daily_you/models/mood_scale_level.dart';
import 'package:material_ui/material_ui.dart';

extension MoodScaleLevelVisuals on MoodScaleLevel {
  Color resolvedColor(BuildContext context) =>
      color != null ? Color(color!) : Theme.of(context).colorScheme.primary;

  String displayLabel(AppLocalizations l10n) {
    final custom = label?.trim() ?? '';
    return custom.isNotEmpty
        ? custom
        : Mood.defaultLabel(Mood.position(mood), l10n);
  }

  String plainText(AppLocalizations l10n) =>
      hasTextIcon ? icon! : displayLabel(l10n);
}
