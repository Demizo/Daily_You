// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:daily_you/models/mood_scale_level.dart';
import 'package:daily_you/utils/generated/tag_icon_registry.dart';
import 'package:daily_you/utils/mood_scale_visuals.dart';
import 'package:daily_you/widgets/glyph_ink.dart';
import 'package:material_ui/material_ui.dart';

class MoodScaleGlyph extends StatefulWidget {
  static const double _boxScale = 1.3;

  final MoodScaleLevel level;
  final double size;
  final bool allowScaling;

  const MoodScaleGlyph({
    super.key,
    required this.level,
    required this.size,
    this.allowScaling = true,
  });

  @override
  State<MoodScaleGlyph> createState() => _MoodScaleGlyphState();
}

class _MoodScaleGlyphState extends State<MoodScaleGlyph> {
  TextPainter? _textPainter;
  GlyphSpec? _laidOutSpec;
  Color? _laidOutColor;

  TextPainter _layoutFor(GlyphSpec spec, Color color) {
    if (_textPainter == null ||
        _laidOutSpec != spec ||
        _laidOutColor != color) {
      _textPainter?.dispose();
      _textPainter = spec.layout(color);
      _laidOutSpec = spec;
      _laidOutColor = color;
    }
    return _textPainter!;
  }

  @override
  void dispose() {
    _textPainter?.dispose();
    super.dispose();
  }

  GlyphSpec _specFor(double scaledSize, double boxSize) {
    final level = widget.level;
    if (level.hasTextIcon) {
      return GlyphSpec(
        text: level.icon!,
        fontSize: scaledSize,
        fontFamily: Platform.isLinux ? 'Noto Color Emoji' : null,
        fixedLineHeight: true,
      );
    }
    final icon = lookupTagIcon(level.icon) ?? Icons.circle_rounded;
    return GlyphSpec(
      text: String.fromCharCode(icon.codePoint),
      fontSize: boxSize,
      fontFamily: icon.fontFamily,
      fontPackage: icon.fontPackage,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = widget.allowScaling
        ? MediaQuery.textScalerOf(context)
        : TextScaler.noScaling;
    final scaledSize = textScaler.scale(widget.size);
    final boxSize = scaledSize * MoodScaleGlyph._boxScale;
    final spec = _specFor(scaledSize, boxSize);

    if (!GlyphInk.isMeasured(spec)) {
      GlyphInk.measure(spec).then((_) {
        if (mounted) setState(() {});
      });
    }

    final glyph = SizedBox.square(
      dimension: boxSize,
      child: CustomPaint(
        painter: _GlyphPainter(
          textPainter: _layoutFor(spec, widget.level.resolvedColor(context)),
          inkOffset: GlyphInk.offsetOf(spec),
        ),
      ),
    );
    return widget.level.hasTextIcon
        ? Semantics(
            label: widget.level.icon, excludeSemantics: true, child: glyph)
        : glyph;
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter({
    required this.textPainter,
    required this.inkOffset,
  });

  final TextPainter textPainter;
  final Offset inkOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2,
    );
    textPainter.paint(canvas, center - inkOffset);
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.textPainter != textPainter || old.inkOffset != inkOffset;
}
