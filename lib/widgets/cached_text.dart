// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/widgets/glyph_ink.dart';
import 'package:material_ui/material_ui.dart';

class CachedText extends StatelessWidget {
  const CachedText(this.text,
      {super.key, required this.size, required this.color, this.fontWeight});

  final String text;
  final double size;
  final Color color;
  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    final spec = GlyphSpec(
      text: text,
      fontSize: MediaQuery.textScalerOf(context).scale(size),
      fontWeight: fontWeight,
    );
    final painter = GlyphLayouts.of(spec, color);
    return SizedBox(
      width: painter.width,
      height: painter.height,
      child: CustomPaint(painter: GlyphPainter(textPainter: painter)),
    );
  }
}
