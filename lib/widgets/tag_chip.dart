import 'package:daily_you/models/tag.dart';
import 'package:daily_you/utils/tag_visuals.dart';
import 'package:daily_you/widgets/tag_icon_glyph.dart';
import 'package:flutter/material.dart';

class TagChip extends StatelessWidget {
  final Tag tag;
  final String? value;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const TagChip(
      {super.key, required this.tag, this.value, this.onTap, this.onRemove});

  Widget _buildTrackerValueBox(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: value != null
          ? Text(value!,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  height: 1.0))
          : Icon(Icons.numbers_rounded,
              size: 12, color: colorScheme.onSurface.withValues(alpha: 0.6)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = tag.resolvedColor(context,
        fallback: Theme.of(context).colorScheme.secondary);
    final screenWidth = MediaQuery.of(context).size.width;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : screenWidth - 32;
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: color, width: 1.5),
                borderRadius: BorderRadius.circular(16),
                color: color.withValues(alpha: 0.12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TagIconGlyph(
                    icon: tag.icon,
                    iconType: tag.iconType,
                    fallbackIcon: tag.typeIcon,
                    color: color,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      tag.name,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.fade,
                    ),
                  ),
                  if (tag.tagType == TagType.tracker) ...[
                    const SizedBox(width: 6),
                    _buildTrackerValueBox(context),
                  ] else if (value != null) ...[
                    const SizedBox(width: 4),
                    Text(value!,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                  if (onRemove != null) ...[
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: onRemove,
                      child: Icon(Icons.close,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
