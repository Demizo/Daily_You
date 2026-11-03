// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:ui' as ui;

import 'package:daily_you/widgets/morphing_burst.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const side = 52;

  Future<List<int>> alphaOf(WidgetTester tester, double progress) async {
    final image = (await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      MorphingBurstPainter(progress: progress, color: const Color(0xFF3366CC))
          .paint(Canvas(recorder), const Size(52, 52));
      return recorder.endRecording().toImage(side, side);
    }))!;
    final data = (await tester.runAsync(() => image.toByteData()))!;
    return [for (var i = 3; i < data.lengthInBytes; i += 4) data.getUint8(i)];
  }

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await BurstShader.load();
  });

  testWidgets('fills the center and leaves the corners clear', (tester) async {
    final alpha = await alphaOf(tester, 1);

    expect(alpha[(side ~/ 2) * side + side ~/ 2], 255);
    expect(alpha[0], 0);
    expect(alpha[side * side - 1], 0);
  });

  testWidgets('anti-aliases the edge with partially covered pixels',
      (tester) async {
    for (final progress in [0.0, 0.5, 1.0]) {
      final alpha = await alphaOf(tester, progress);
      final partial = alpha.where((value) => value > 0 && value < 255).length;

      expect(partial, greaterThan(40), reason: 'progress $progress');
    }
  });

  testWidgets('morphs from a circle into a bumpy burst', (tester) async {
    final circle = await alphaOf(tester, 0);
    final burst = await alphaOf(tester, 1);

    expect(burst, isNot(circle));
    int covered(List<int> alpha) => alpha.where((value) => value > 127).length;
    expect(covered(burst), greaterThan(covered(circle)));
  });
}
