import 'package:daily_you/models/tag.dart';
import 'package:daily_you/models/tag_category.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/utils/tag_category_visuals.dart';
import 'package:daily_you/widgets/tag_icon_glyph.dart';
import 'package:flutter/material.dart';

/// Renders a list of [TagSection]s as grouped chip rows.
class TagGroupedChipList extends StatelessWidget {
  final List<TagSection> sections;

  /// Builds the chip widget for each tag. The caller controls tap/remove behavior.
  final Widget Function(Tag) chipBuilder;

  const TagGroupedChipList({
    super.key,
    required this.sections,
    required this.chipBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) return const SizedBox.shrink();

    final items = <Widget>[];
    for (final section in sections) {
      if (section.category != null) {
        items.add(_PickerSectionHeader(category: section.category!));
      }
      items.add(Wrap(
        spacing: 6,
        runSpacing: 6,
        children: section.tags.map(chipBuilder).toList(),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items,
    );
  }
}

class _PickerSectionHeader extends StatelessWidget {
  final TagCategory category;
  const _PickerSectionHeader({required this.category});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        children: [
          TagIconGlyph(
            icon: category.icon,
            iconType: category.iconType,
            fallbackIcon: Icons.folder_rounded,
            color: category.resolvedColor(context),
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              category.name,
              overflow: TextOverflow.fade,
              softWrap: false,
              maxLines: 1,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
