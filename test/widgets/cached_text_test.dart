// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:daily_you/widgets/cached_text.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  const color = Color(0xFF008080);

  Future<Uint8List> render(WidgetTester tester, Widget child) async {
    final key = GlobalKey();
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: RepaintBoundary(
          key: key,
          child: ColoredBox(
            color: const Color(0xFFFFFFFF),
            child: SizedBox.square(dimension: 60, child: Center(child: child)),
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

  testWidgets('draws exactly what Text draws', (tester) async {
    final textBytes = await render(
        tester,
        const Text('28',
            style: TextStyle(
                inherit: false,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color)));
    final cachedBytes = await render(
        tester,
        const CachedText('28',
            size: 16, color: color, fontWeight: FontWeight.bold));

    expect(cachedBytes, textBytes);
  });

  testWidgets('follows the text scale like Text does', (tester) async {
    final textBytes = await render(
        tester,
        const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: Text('7',
              style: TextStyle(inherit: false, fontSize: 16, color: color)),
        ));
    final cachedBytes = await render(
        tester,
        const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: CachedText('7', size: 16, color: color),
        ));

    expect(cachedBytes, textBytes);
  });
}
