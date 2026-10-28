// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:ui' as ui;

import 'package:daily_you/widgets/segmented_group.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance() + 0.05;
  final secondLuminance = second.computeLuminance() + 0.05;
  return firstLuminance > secondLuminance
      ? firstLuminance / secondLuminance
      : secondLuminance / firstLuminance;
}

void main() {
  final boundaryKey = GlobalKey();

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
    testWidgets(
        'a hovered row stands out from its page and its resting row in ${brightness.name} mode',
        (tester) async {
      final colorScheme = ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: brightness,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorScheme: colorScheme),
          home: RepaintBoundary(
            key: boundaryKey,
            child: Scaffold(
              backgroundColor: colorScheme.surfaceContainer,
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 300,
                  child: SegmentedGroup(
                    children: [
                      ListTile(title: const Text('First'), onTap: () {}),
                      ListTile(title: const Text('Second'), onTap: () {}),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final sample = tester.getTopRight(find.byType(ListTile).first) +
          const Offset(-20, 20);
      final resting = await pixelAt(tester, sample);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: sample);
      await tester.pumpAndSettle();
      final hovered = await pixelAt(tester, sample);

      expect(_contrastRatio(hovered, colorScheme.surfaceContainer),
          greaterThan(1.2));
      expect(_contrastRatio(hovered, resting), greaterThan(1.2));
    });
  }
}
