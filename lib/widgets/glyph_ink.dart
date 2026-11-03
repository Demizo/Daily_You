// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

@immutable
class GlyphSpec {
  const GlyphSpec({
    required this.text,
    required this.fontSize,
    this.fontFamily,
    this.fontPackage,
    this.fixedLineHeight = false,
  });

  final String text;
  final double fontSize;
  final String? fontFamily;
  final String? fontPackage;

  final bool fixedLineHeight;

  TextPainter layout(Color color) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          inherit: false,
          color: color,
          fontSize: fontSize,
          fontFamily: fontFamily,
          package: fontPackage,
        ),
      ),
      textDirection: TextDirection.ltr,
      strutStyle: fixedLineHeight
          ? StrutStyle(
              fontSize: fontSize,
              fontFamily: fontFamily,
              package: fontPackage,
              height: 1,
              forceStrutHeight: true,
              leadingDistribution: TextLeadingDistribution.even,
            )
          : null,
      textHeightBehavior: fixedLineHeight
          ? const TextHeightBehavior(
              leadingDistribution: TextLeadingDistribution.even,
            )
          : null,
    )..layout();
  }

  @override
  bool operator ==(Object other) =>
      other is GlyphSpec &&
      other.text == text &&
      other.fontSize == fontSize &&
      other.fontFamily == fontFamily &&
      other.fontPackage == fontPackage &&
      other.fixedLineHeight == fixedLineHeight;

  @override
  int get hashCode =>
      Object.hash(text, fontSize, fontFamily, fontPackage, fixedLineHeight);
}

abstract final class GlyphInk {
  static const double _measureScale = 4;
  static const int _opaqueAlpha = 24;

  static final Map<GlyphSpec, Offset> _offsets = {};
  static final Map<GlyphSpec, Future<void>> _pending = {};

  static bool isMeasured(GlyphSpec spec) => _offsets.containsKey(spec);

  static Offset offsetOf(GlyphSpec spec) => _offsets[spec] ?? Offset.zero;

  static Future<void> measure(GlyphSpec spec) =>
      _pending[spec] ??= _measure(spec);

  static Future<void> _measure(GlyphSpec spec) async {
    final painter = spec.layout(const Color(0xFF000000));
    final layoutCenter = Offset(painter.width / 2, painter.height / 2);
    final margin = spec.fontSize;
    final width = ((painter.width + 2 * margin) * _measureScale).ceil();
    final height = ((painter.height + 2 * margin) * _measureScale).ceil();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(_measureScale);
    painter.paint(canvas, Offset(margin, margin));
    painter.dispose();

    try {
      final image = await recorder.endRecording().toImage(width, height);
      final data = await image.toByteData();
      image.dispose();
      final bounds = inkBounds(data!.buffer.asUint8List(), width, height);
      _offsets[spec] = bounds == null
          ? Offset.zero
          : bounds.center / _measureScale -
              (layoutCenter + Offset(margin, margin));
    } catch (error) {
      debugPrint('Could not measure glyph ink for "${spec.text}": $error');
      _offsets[spec] = Offset.zero;
    }
  }

  @visibleForTesting
  static Rect? inkBounds(Uint8List rgba, int width, int height) {
    var minX = width, minY = height, maxX = -1, maxY = -1;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (rgba[(y * width + x) * 4 + 3] < _opaqueAlpha) continue;
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
    if (maxX < 0) return null;
    return Rect.fromLTRB(
        minX.toDouble(), minY.toDouble(), maxX + 1.0, maxY + 1.0);
  }

  @visibleForTesting
  static void reset() {
    _offsets.clear();
    _pending.clear();
  }
}
