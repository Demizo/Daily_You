// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/layouts/window_size_class.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('classifies widths at the boundaries', () {
    expect(WindowSizeClass.fromWidth(0), WindowSizeClass.compact);
    expect(WindowSizeClass.fromWidth(599.9), WindowSizeClass.compact);
    expect(WindowSizeClass.fromWidth(600), WindowSizeClass.medium);
    expect(WindowSizeClass.fromWidth(1099.9), WindowSizeClass.medium);
    expect(WindowSizeClass.fromWidth(1100), WindowSizeClass.expanded);
  });

  test('exposes wide and sidebar helpers', () {
    expect(WindowSizeClass.compact.isWide, isFalse);
    expect(WindowSizeClass.medium.isWide, isTrue);
    expect(WindowSizeClass.expanded.isWide, isTrue);
    expect(WindowSizeClass.compact.hasPersistentSidebar, isFalse);
    expect(WindowSizeClass.medium.hasPersistentSidebar, isFalse);
    expect(WindowSizeClass.expanded.hasPersistentSidebar, isTrue);
  });

  testWidgets('reads the class from the window size', (tester) async {
    late WindowSizeClass seen;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        seen = WindowSizeClass.of(context);
        return const SizedBox();
      }),
    ));

    tester.view.physicalSize = const Size(400, 800);
    await tester.pump();
    expect(seen, WindowSizeClass.compact);

    tester.view.physicalSize = const Size(800, 800);
    await tester.pump();
    expect(seen, WindowSizeClass.medium);

    tester.view.physicalSize = const Size(1400, 800);
    await tester.pump();
    expect(seen, WindowSizeClass.expanded);
  });
}
