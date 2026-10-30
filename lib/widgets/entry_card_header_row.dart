// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/entry.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/widgets/entry_tag_icon_preview.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class EntryCardHeaderRow extends StatelessWidget {
  final Entry entry;
  final String title;
  final TextStyle? titleStyle;

  static const double _tagIconSize = 18;
  static const double _tagIconSpacing = 4;

  static const double _segmentGap = 2;
  static const double _titleInset = 6;
  static const double _moodInset = 4;
  static const double _moodBottomInset = 1.5;
  static const double _moodSize = 20;
  static const double _moodLineHeightScale = 1.3;

  const EntryCardHeaderRow({
    super.key,
    required this.entry,
    required this.title,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final tagsProvider = context.watch<TagsProvider>();
    final hasTags = entry.id != null &&
        tagsProvider.getEntryTagsForEntry(entry.id!).isNotEmpty;
    final moodHeight = MediaQuery.textScalerOf(context).scale(_moodSize) *
        _moodLineHeightScale;

    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: _titleInset,
        end: _moodInset,
      ),
      child: Row(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final minTagReserve =
                    hasTags ? _tagIconSize + _segmentGap : 0.0;
                final titleCap = (constraints.maxWidth - minTagReserve)
                    .clamp(0.0, constraints.maxWidth);

                return Row(
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: titleCap),
                      child: Text(
                        title,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                        style: titleStyle,
                      ),
                    ),
                    Expanded(
                      child: hasTags
                          ? Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: EntryTagIconPreview(
                                entryId: entry.id,
                                iconSize: _tagIconSize,
                                spacing: _tagIconSpacing,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: _segmentGap),
          Padding(
            padding: const EdgeInsets.only(bottom: _moodBottomInset),
            child: SizedBox(
              height: moodHeight,
              child: Center(
                child: MoodIcon(moodValue: entry.mood, size: _moodSize),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
