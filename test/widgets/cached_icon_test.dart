// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:daily_you/widgets/cached_icon.dart';
import 'package:daily_you/widgets/glyph_ink.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  const color = Color(0xFF008080);

  Future<Uint8List> render(WidgetTester tester, Widget icon) async {
    final key = GlobalKey();
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: RepaintBoundary(
          key: key,
          child: ColoredBox(
            color: const Color(0xFFFFFFFF),
            child: SizedBox.square(dimension: 40, child: Center(child: icon)),
          ),
        ),
      ),
    ));
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    late Uint8List bytes;
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      bytes = data!.buffer.asUint8List();
      image.dispose();
    });
    return bytes;
  }

  testWidgets('draws exactly what Icon draws', (tester) async {
    final iconBytes = await render(
        tester, const Icon(Icons.favorite_rounded, size: 18, color: color));
    final cachedBytes = await render(tester,
        const CachedIcon(Icons.favorite_rounded, size: 18, color: color));

    expect(cachedBytes, iconBytes);
  });

  test('reuses the laid out painter for the same glyph and color', () {
    const spec = GlyphSpec(text: 'x', fontSize: 14);

    expect(
        identical(GlyphLayouts.of(spec, color), GlyphLayouts.of(spec, color)),
        isTrue);
    expect(
        identical(GlyphLayouts.of(spec, color),
            GlyphLayouts.of(spec, const Color(0xFFFF0000))),
        isFalse);
  });
}
