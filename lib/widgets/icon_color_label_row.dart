// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/utils/color_utils.dart';
import 'package:material_ui/material_ui.dart';

class IconColorLabelRow extends StatelessWidget {
  const IconColorLabelRow({
    super.key,
    required this.icon,
    required this.color,
    required this.controller,
    required this.hintText,
    required this.onPickIcon,
    required this.onPickColor,
    this.autofocus = false,
    this.onSubmitted,
  });

  final Widget icon;
  final Color color;
  final TextEditingController controller;
  final String hintText;
  final VoidCallback onPickIcon;
  final VoidCallback onPickColor;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  static const double _minHeight = 48;
  static const double _segmentWidth = 52;
  static const double _gap = 2;
  static const Radius _outerRadius = Radius.circular(24);
  static const Radius _innerRadius = Radius.circular(4);

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surfaceContainerLowest;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _minHeight),
      child: IntrinsicHeight(
        child: Row(
          spacing: _gap,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Segment(
              width: _segmentWidth,
              color: surface,
              borderRadius: const BorderRadiusDirectional.horizontal(
                start: _outerRadius,
                end: _innerRadius,
              ),
              onTap: onPickIcon,
              child: Center(child: icon),
            ),
            Expanded(
              child: _Segment(
                color: surface,
                borderRadius: const BorderRadius.all(_innerRadius),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextField(
                    controller: controller,
                    autofocus: autofocus,
                    maxLines: 1,
                    textCapitalization: TextCapitalization.words,
                    onSubmitted: onSubmitted,
                    decoration: InputDecoration(
                      hintText: hintText,
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _Segment(
              width: _segmentWidth,
              color: color,
              borderRadius: const BorderRadiusDirectional.horizontal(
                start: _innerRadius,
                end: _outerRadius,
              ),
              onTap: onPickColor,
              child: Center(
                child: Icon(
                  Icons.palette_rounded,
                  size: 20,
                  color: contrastingTextColor(color),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    this.width,
    required this.color,
    required this.borderRadius,
    this.onTap,
    required this.child,
  });

  final double? width;
  final Color color;
  final BorderRadiusGeometry borderRadius;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: color,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        child: onTap == null ? child : InkWell(onTap: onTap, child: child),
      ),
    );
  }
}
