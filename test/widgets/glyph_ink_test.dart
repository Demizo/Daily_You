// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:daily_you/widgets/glyph_ink.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _fontFamily = 'GlyphInkTestRoboto';
const _scale = 4.0;

Future<ui.Image> _paint(GlyphSpec spec, Offset shift, double margin) {
  final painter = spec.layout(const Color(0xFF000000));
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(_scale);
  painter.paint(canvas, Offset(margin, margin) + shift);
  return recorder.endRecording().toImage(
        ((painter.width + 2 * margin) * _scale).ceil(),
        ((painter.height + 2 * margin) * _scale).ceil(),
      );
}

void main() {
  setUpAll(() async {
    final font = File('tool/screenshots/fonts/Roboto-Regular.ttf');
    await (FontLoader(_fontFamily)
          ..addFont(Future.value(ByteData.sublistView(font.readAsBytesSync()))))
        .load();
  });

  setUp(GlyphInk.reset);

  group('inkBounds', () {
    test('returns the box around visible pixels only', () {
      const width = 6, height = 5;
      final rgba = Uint8List(width * height * 4);
      void ink(int x, int y) => rgba[(y * width + x) * 4 + 3] = 255;
      ink(2, 1);
      ink(4, 3);

      expect(GlyphInk.inkBounds(rgba, width, height),
          const Rect.fromLTRB(2, 1, 5, 4));
    });

    test('ignores nearly transparent pixels and reports empty glyphs', () {
      const width = 4, height = 4;
      final rgba = Uint8List(width * height * 4);
      rgba[3] = 5;

      expect(GlyphInk.inkBounds(rgba, width, height), isNull);
    });
  });

  testWidgets('measuring then shifting by the offset centers the visible ink',
      (tester) async {
    const spec = GlyphSpec(text: 'É', fontSize: 40, fontFamily: _fontFamily);
    const margin = 40.0;

    await tester.runAsync(() => GlyphInk.measure(spec));
    final offset = GlyphInk.offsetOf(spec);
    expect(offset.dy.abs(), greaterThan(1),
        reason: 'the glyph should start visibly off center');

    Future<Offset> inkCenterError(Offset shift) async {
      final image = (await tester.runAsync(() => _paint(spec, shift, margin)))!;
      final data = (await tester.runAsync(() => image.toByteData()))!;
      final bounds = GlyphInk.inkBounds(
          data.buffer.asUint8List(), image.width, image.height)!;
      final layout = spec.layout(const Color(0xFF000000));
      return bounds.center / _scale -
          Offset(margin + layout.width / 2, margin + layout.height / 2);
    }

    final before = await inkCenterError(Offset.zero);
    final after = await inkCenterError(-offset);

    expect(before.dy.abs(), greaterThan(1));
    expect(after.dx.abs(), lessThan(0.5));
    expect(after.dy.abs(), lessThan(0.5));
  });
}
