// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/gallery_filter.dart';
import 'package:daily_you/layouts/window_size_class.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/attachment_filter_dialog.dart';
import 'package:daily_you/widgets/date_filter_dialog.dart';
import 'package:daily_you/widgets/date_selection_label.dart';
import 'package:daily_you/widgets/entry_card_widget.dart';
import 'package:daily_you/widgets/filter_pill.dart';
import 'package:daily_you/widgets/icons/svg_icon.dart';
import 'package:daily_you/widgets/mood_filter_dialog.dart';
import 'package:daily_you/widgets/tag_picker_dialog.dart';
import 'package:daily_you/widgets/text_filter_dialog.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class GalleryFilterPills extends StatelessWidget {
  const GalleryFilterPills({super.key, required this.onClearAll});

  final VoidCallback onClearAll;

  static const double _spacing = 8;

  void _showTagFilterDialog(BuildContext context, EntriesProvider provider) {
    final filter = provider.filter;
    showAppDialog(
      context: context,
      builder: (_) => TagPickerDialog(
        mode: TagPickerMode.filter,
        initialSelectedTagIds: filter.tagIds.toList(),
        initialFilterMode: filter.tagMode,
        initialNoTagsOnly: filter.noTags,
        onFilterChanged: (tagIds, mode, noTagsOnly) {
          provider.filter = provider.filter.copyWith(
            tagIds: tagIds.toSet(),
            tagMode: mode,
            noTags: noTagsOnly,
          );
        },
      ),
    );
  }

  void _showDialog(BuildContext context, Widget dialog) =>
      showAppDialog(context: context, builder: (_) => dialog);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<EntriesProvider>();
    final filter = provider.filter;

    FilterPill pill({
      required Widget icon,
      required VoidCallback onPressed,
      required String label,
      required bool hasSelection,
      required GalleryFilter Function() cleared,
    }) =>
        FilterPill(
          icon: icon,
          onPressed: onPressed,
          onClear: hasSelection ? () => provider.filter = cleared() : null,
          child: Text(label),
        );

    final pills = [
      pill(
        icon: const Icon(Icons.mood_rounded),
        onPressed: () => _showDialog(context, const MoodFilterDialog()),
        label: filter.noMood ? l10n.noMoodFilterLabel : l10n.tagMoodTitle,
        hasSelection: filter.hasMood,
        cleared: filter.withoutMood,
      ),
      pill(
        icon: const Icon(Icons.local_offer_rounded),
        onPressed: () => _showTagFilterDialog(context, provider),
        label: filter.noTags
            ? l10n.noTagsFilterLabel
            : filter.hasTags
                ? l10n.tagCount(filter.tagIds.length)
                : l10n.settingsTagsTitle,
        hasSelection: filter.hasTags,
        cleared: filter.withoutTags,
      ),
      pill(
        icon: const Icon(Icons.calendar_month_rounded),
        onPressed: () => _showDialog(context, const DateFilterDialog()),
        label: filter.date.label(context),
        hasSelection: filter.hasDate,
        cleared: filter.withoutDate,
      ),
      pill(
        icon: const Icon(Icons.notes_rounded),
        onPressed: () => _showDialog(context, const TextFilterDialog()),
        label: filter.noText
            ? l10n.noTextFilterLabel
            : filter.hasText
                ? l10n.keywordCount(filter.textTerms.length)
                : l10n.filterPillKeywords,
        hasSelection: filter.hasText,
        cleared: filter.withoutText,
      ),
      pill(
        icon: const SvgIcon('assets/icons/attach_file.svg'),
        onPressed: () => _showDialog(context, const AttachmentFilterDialog()),
        label: filter.noAttachments
            ? l10n.noAttachmentsFilterLabel
            : l10n.filterPillAttachments,
        hasSelection: filter.hasAttachments,
        cleared: filter.withoutAttachments,
      ),
      if (filter.isActive)
        TextButton(
          style: TextButton.styleFrom(
            minimumSize: const Size(0, FilterPill.height),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: onClearAll,
          child: Text(l10n.clearAllFilters),
        ),
    ];

    if (WindowSizeClass.of(context).isWide) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: entryCardMargin + galleryHorizontalPadding,
        ),
        child: Wrap(spacing: _spacing, runSpacing: _spacing, children: pills),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: entryCardMargin + galleryHorizontalPadding,
      ),
      child: Row(
        children: [
          for (final pill in pills)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: _spacing),
              child: pill,
            ),
        ],
      ),
    );
  }
}
