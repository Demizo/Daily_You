// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/mood.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/utils/filter_selection.dart';
import 'package:daily_you/widgets/gallery_filter_dialog.dart';
import 'package:daily_you/widgets/mood_option.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class MoodFilterDialog extends StatelessWidget {
  const MoodFilterDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<EntriesProvider>();
    final filter = provider.filter;

    return GalleryFilterDialog(
      title: l10n.tagMoodTitle,
      canClear: filter.hasMood,
      onClear: () => provider.filter = filter.withoutMood(),
      noneLabel: l10n.noMoodFilterLabel,
      noneValue: filter.noMood,
      onNoneChanged: (value) => provider.filter = filter.copyWith(
        noMood: value,
        moods: value ? const {} : filter.moods,
      ),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final mood in Mood.levels)
            MoodOption(
              mood: mood,
              isSelected: filter.moods.contains(mood),
              onTap: () => provider.filter = filter.copyWith(
                moods: toggledSelection(filter.moods, mood),
              ),
            ),
        ],
      ),
    );
  }
}
