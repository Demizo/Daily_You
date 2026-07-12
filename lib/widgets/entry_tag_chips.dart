import 'package:daily_you/models/tag.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/widgets/tag_grouped_chip_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EntryTagChips extends StatelessWidget {
  final int entryId;
  final EdgeInsetsGeometry? padding;

  /// Builds the chip widget for each tag attached to the entry.
  final Widget Function(Tag tag, EntryTag entryTag) chipBuilder;

  const EntryTagChips({
    super.key,
    required this.entryId,
    required this.chipBuilder,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TagsProvider>(
      builder: (context, tagsProvider, _) {
        final entryTags = tagsProvider.getEntryTagsForEntry(entryId);
        if (entryTags.isEmpty) return const SizedBox.shrink();

        final entryTagByTagId = {
          for (final entryTag in entryTags) entryTag.tagId: entryTag
        };
        final tagPool = tagsProvider.tags
            .where((tag) => entryTagByTagId.containsKey(tag.id))
            .toList();
        final sections = tagsProvider.buildSections('', tagPool: tagPool);

        final chipList = TagGroupedChipList(
          sections: sections,
          chipBuilder: (tag) => chipBuilder(tag, entryTagByTagId[tag.id]!),
        );

        return padding == null
            ? chipList
            : Padding(padding: padding!, child: chipList);
      },
    );
  }
}
