// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/widgets/segmented_group.dart';
import 'package:daily_you/widgets/settings_rows.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final boundaryKey = GlobalKey();

  Future<void> pumpGroup(
    WidgetTester tester,
    ColorScheme colorScheme,
    List<Widget> rows,
  ) {
    return tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorScheme: colorScheme),
        home: RepaintBoundary(
          key: boundaryKey,
          child: Scaffold(
            backgroundColor: colorScheme.surface,
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 300,
                child: SegmentedGroup(children: rows),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Offset samplePointOf(WidgetTester tester, int rowIndex) =>
      tester.getTopRight(find.byType(ListTile).at(rowIndex)) +
      const Offset(-20, 20);

  Future<Color> pixelAt(WidgetTester tester, Offset position) async {
    final boundary =
        boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final color = await tester.runAsync(() async {
      final image = await boundary.toImage();
      final data = (await image.toByteData())!;
      image.dispose();
      final index =
          (position.dy.round() * image.width + position.dx.round()) * 4;
      return Color.fromARGB(
        255,
        data.getUint8(index),
        data.getUint8(index + 1),
        data.getUint8(index + 2),
      );
    });
    return color!;
  }

  for (final brightness in Brightness.values) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: brightness,
    );

    testWidgets(
        'a hovered row differs from its resting color in ${brightness.name} mode',
        (tester) async {
      await pumpGroup(tester, colorScheme, [
        ListTile(title: const Text('First'), onTap: () {}),
        ListTile(title: const Text('Second'), onTap: () {}),
      ]);
      final sample = samplePointOf(tester, 0);
      final resting = await pixelAt(tester, sample);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: sample);
      await tester.pumpAndSettle();
      final hovered = await pixelAt(tester, sample);

      expect(hovered, isNot(resting));
    });

    testWidgets(
        'a selected section row uses the secondary container in ${brightness.name} mode',
        (tester) async {
      await pumpGroup(tester, colorScheme, [
        SettingsSectionRow(
            icon: Icons.palette_rounded,
            title: 'First',
            selected: true,
            onTap: () {}),
        SettingsSectionRow(
            icon: Icons.language_rounded,
            title: 'Second',
            selected: false,
            onTap: () {}),
      ]);

      final selected = await pixelAt(tester, samplePointOf(tester, 0));
      final unselected = await pixelAt(tester, samplePointOf(tester, 1));

      expect(selected.toARGB32(), colorScheme.secondaryContainer.toARGB32());
      expect(unselected.toARGB32(), colorScheme.surfaceContainer.toARGB32());
    });
  }
}
