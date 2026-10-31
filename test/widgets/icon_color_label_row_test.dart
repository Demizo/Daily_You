// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/widgets/icon_color_label_row.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  const color = Color(0xFF3366CC);
  late TextEditingController controller;
  late List<String> taps;

  setUp(() {
    controller = TextEditingController(text: 'Water');
    taps = [];
  });

  tearDown(() => controller.dispose());

  Future<void> pumpRow(WidgetTester tester) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IconColorLabelRow(
            icon: const Icon(Icons.water_drop_rounded),
            color: color,
            controller: controller,
            hintText: 'Name',
            onPickIcon: () => taps.add('icon'),
            onPickColor: () => taps.add('color'),
          ),
        ),
      ),
    );
  }

  testWidgets('tapping the icon half picks an icon', (tester) async {
    await pumpRow(tester);

    await tester.tap(find.byIcon(Icons.water_drop_rounded));

    expect(taps, ['icon']);
  });

  testWidgets('tapping the color half picks a color', (tester) async {
    await pumpRow(tester);

    await tester.tap(find.byIcon(Icons.palette_rounded));

    expect(taps, ['color']);
  });

  testWidgets('the color half is filled with the color', (tester) async {
    await pumpRow(tester);

    final material = tester.widget<Material>(find
        .ancestor(
            of: find.byIcon(Icons.palette_rounded),
            matching: find.byType(Material))
        .first);

    expect(material.color, color);
  });

  testWidgets('typing edits the label', (tester) async {
    await pumpRow(tester);

    await tester.enterText(find.byType(TextField), 'Tea');

    expect(controller.text, 'Tea');
    expect(taps, isEmpty);
  });
}
