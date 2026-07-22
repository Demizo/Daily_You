import 'package:daily_you/models/tag.dart';
import 'package:flutter/material.dart';

extension TagVisuals on Tag {
  /// Fallback icon shown when the tag has no icon of its own set.
  IconData get typeIcon =>
      tagType == TagType.tracker ? Icons.timeline_rounded : Icons.label_rounded;

  /// Resolves the tag's color against the theme; a null [Tag.color] means
  /// no color has been chosen, so the theme default applies instead.
  Color resolvedColor(BuildContext context, {Color? fallback}) {
    if (color != null) return Color(color!);
    return fallback ?? Theme.of(context).colorScheme.primary;
  }
}
