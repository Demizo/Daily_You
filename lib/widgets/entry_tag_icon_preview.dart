import 'package:daily_you/models/tag.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/utils/tag_visuals.dart';
import 'package:daily_you/widgets/tag_icon_glyph.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EntryTagIconPreview extends StatelessWidget {
  final int? entryId;
  final double iconSize;
  final double spacing;

  const EntryTagIconPreview({
    super.key,
    required this.entryId,
    this.iconSize = 18,
    this.spacing = 4,
  });

  String _glyphKey(Tag tag) {
    final hasIcon = tag.icon != null && tag.icon!.isNotEmpty;
    return hasIcon
        ? '${tag.iconType.name}:${tag.icon}'
        : 'fallback:${tag.typeIcon.codePoint}';
  }

  int _maxFittingIcons(double availableWidth) {
    if (availableWidth < iconSize) return 0;
    return 1 + ((availableWidth - iconSize) / (iconSize + spacing)).floor();
  }

  /// Fixed size slot of a tag icon or character
  Widget _slot(Widget child) {
    return SizedBox(
      width: iconSize,
      height: iconSize,
      child: FittedBox(fit: BoxFit.scaleDown, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final id = entryId;
    if (id == null) return const SizedBox.shrink();

    return Consumer<TagsProvider>(
      builder: (context, tagsProvider, _) {
        final entryTags = tagsProvider.getEntryTagsForEntry(id);
        if (entryTags.isEmpty) return const SizedBox.shrink();

        final attachedTagIds =
            entryTags.map((entryTag) => entryTag.tagId).toSet();
        final attachedTags = tagsProvider.tags
            .where((tag) => attachedTagIds.contains(tag.id))
            .toList();
        if (attachedTags.isEmpty) return const SizedBox.shrink();

        final orderedTags = tagsProvider
            .buildSections('', tagPool: attachedTags)
            .expand((section) => section.tags)
            .toList();

        final colorScheme = Theme.of(context).colorScheme;
        final seenKeys = <String>{};
        final uniqueTags = <Tag>[];
        final uniqueColors = <Color>[];
        for (final tag in orderedTags) {
          final color =
              tag.resolvedColor(context, fallback: colorScheme.secondary);
          if (seenKeys.add('${_glyphKey(tag)}|${color.toARGB32()}')) {
            uniqueTags.add(tag);
            uniqueColors.add(color);
          }
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final fit = constraints.maxWidth.isFinite
                ? _maxFittingIcons(constraints.maxWidth)
                : uniqueTags.length;
            if (fit <= 0) return const SizedBox.shrink();

            final List<Widget> icons;
            if (uniqueTags.length <= fit) {
              // Full tags list
              icons = [
                for (var i = 0; i < uniqueTags.length; i++)
                  _slot(TagIconGlyph(
                    icon: uniqueTags[i].icon,
                    iconType: uniqueTags[i].iconType,
                    fallbackIcon: uniqueTags[i].typeIcon,
                    color: uniqueColors[i],
                    size: iconSize,
                  )),
              ];
            } else if (fit == 1) {
              // Tag presence indicator
              icons = [
                _slot(Icon(Icons.local_offer_rounded,
                    size: iconSize, color: colorScheme.secondary)),
              ];
            } else {
              // Additional tags indicator
              icons = [
                for (var i = 0; i < fit - 1; i++)
                  _slot(TagIconGlyph(
                    icon: uniqueTags[i].icon,
                    iconType: uniqueTags[i].iconType,
                    fallbackIcon: uniqueTags[i].typeIcon,
                    color: uniqueColors[i],
                    size: iconSize,
                  )),
                _slot(Icon(Icons.more_horiz_rounded,
                    size: iconSize, color: colorScheme.secondary)),
              ];
            }

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < icons.length; i++) ...[
                  if (i > 0) SizedBox(width: spacing),
                  icons[i],
                ],
              ],
            );
          },
        );
      },
    );
  }
}
