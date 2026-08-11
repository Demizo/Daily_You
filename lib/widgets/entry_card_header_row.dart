import 'package:daily_you/models/entry.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/widgets/entry_tag_icon_preview.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EntryCardHeaderRow extends StatelessWidget {
  final Entry entry;
  final String title;
  final TextStyle? titleStyle;
  final EdgeInsetsGeometry titlePadding;

  static const double _tagIconSize = 18;
  static const double _tagIconSpacing = 4;

  static const double _moodReserve = 24;
  static const double _segmentGap = 2;

  const EntryCardHeaderRow({
    super.key,
    required this.entry,
    required this.title,
    this.titleStyle,
    this.titlePadding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final tagsProvider = context.watch<TagsProvider>();
    final hasTags = entry.id != null &&
        tagsProvider.getEntryTagsForEntry(entry.id!).isNotEmpty;
    final hasMood = MoodIcon.getMoodIcon(entry.mood).isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final moodReserve = _segmentGap + (hasMood ? _moodReserve : 0.0);
        final minTagReserve = hasTags ? _tagIconSize + _segmentGap : 0.0;
        final titleCap = (constraints.maxWidth - moodReserve - minTagReserve)
            .clamp(0.0, constraints.maxWidth);

        return Row(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: titleCap),
              child: Padding(
                padding: titlePadding,
                child: Text(
                  title,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                  style: titleStyle,
                ),
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
            const SizedBox(width: _segmentGap),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: MoodIcon(moodValue: entry.mood),
            ),
          ],
        );
      },
    );
  }
}
