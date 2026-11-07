// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/widgets/editor_action_bar/action_bar_pill.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

const ColorScheme colorScheme = ColorScheme.light(
  primary: Color(0xFF112233),
  onPrimary: Color(0xFFAABBCC),
  secondary: Color(0xFF445566),
  onSecondary: Color(0xFFDDEEFF),
);

Future<void> pumpButton(WidgetTester tester,
    {required bool selected, required double dockProgress}) {
  return tester.pumpWidget(MaterialApp(
    theme: ThemeData(colorScheme: colorScheme),
    home: Scaffold(
      body: Center(
        child: ToolbarIconButton(
          size: 48,
          icon: const Icon(Icons.format_bold_rounded),
          onPressed: () {},
          selected: selected,
          dockProgress: dockProgress,
        ),
      ),
    ),
  ));
}

Material buttonMaterial(WidgetTester tester) => tester.widget<Material>(find
    .descendant(of: find.byType(IconButton), matching: find.byType(Material))
    .first);

Color iconColor(WidgetTester tester) =>
    IconTheme.of(tester.element(find.byIcon(Icons.format_bold_rounded))).color!;

void main() {
  testWidgets('an unselected button has no highlight', (tester) async {
    await pumpButton(tester, selected: false, dockProgress: 1);

    expect(buttonMaterial(tester).color, isNot(colorScheme.secondary));
    expect(buttonMaterial(tester).color, isNot(colorScheme.primary));
  });

  testWidgets('a docked selected button is a secondary circle', (tester) async {
    await pumpButton(tester, selected: true, dockProgress: 1);

    final material = buttonMaterial(tester);
    expect(material.color, colorScheme.secondary);
    expect(material.shape, isA<CircleBorder>());
    expect(iconColor(tester), colorScheme.onSecondary);
  });

  testWidgets('a floating selected button is a primary circle', (tester) async {
    await pumpButton(tester, selected: true, dockProgress: 0);

    final material = buttonMaterial(tester);
    expect(material.color, colorScheme.primary);
    expect(material.shape, isA<CircleBorder>());
    expect(iconColor(tester), colorScheme.onPrimary);
  });
}
