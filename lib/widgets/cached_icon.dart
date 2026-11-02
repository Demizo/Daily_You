// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/widgets/glyph_ink.dart';
import 'package:material_ui/material_ui.dart';

class CachedIcon extends StatelessWidget {
  const CachedIcon(this.icon,
      {super.key, required this.size, required this.color});

  final IconData icon;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final spec = GlyphSpec(
      text: String.fromCharCode(icon.codePoint),
      fontSize: size,
      fontFamily: icon.fontFamily,
      fontPackage: icon.fontPackage,
    );
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: GlyphPainter(textPainter: GlyphLayouts.of(spec, color)),
      ),
    );
  }
}
