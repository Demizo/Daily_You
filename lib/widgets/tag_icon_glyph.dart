import 'package:daily_you/models/tag_icon_type.dart';
import 'package:daily_you/utils/generated/tag_icon_registry.dart';
import 'package:flutter/material.dart';

/// Renders a tag or category icon: a curated Material icon tinted in
/// [color], a custom character/emoji at its natural glyph size, or
/// [fallbackIcon] when no icon has been set (or a stored material icon key
/// no longer exists in the registry).
class TagIconGlyph extends StatelessWidget {
  final String? icon;
  final TagIconType iconType;
  final IconData fallbackIcon;
  final Color color;
  final double size;
  final double? characterSize;

  const TagIconGlyph({
    super.key,
    required this.icon,
    required this.iconType,
    required this.fallbackIcon,
    required this.color,
    required this.size,
    this.characterSize,
  });

  @override
  Widget build(BuildContext context) {
    final hasIcon = icon != null && icon!.isNotEmpty;
    if (!hasIcon) {
      return Icon(fallbackIcon, size: size, color: color);
    }

    if (iconType == TagIconType.materialIcon) {
      final data = lookupTagIcon(icon) ?? fallbackIcon;
      return Icon(data, size: size, color: color);
    }

    return Text(
      icon!,
      textScaler: TextScaler.noScaling,
      style: TextStyle(fontSize: characterSize ?? size, height: 1.0),
    );
  }
}
