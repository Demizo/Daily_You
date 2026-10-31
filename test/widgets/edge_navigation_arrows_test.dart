// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/widgets/desktop_arrow_button.dart';
import 'package:daily_you/widgets/edge_navigation_arrows.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  const windowSize = Size(1000, 600);
  const topInset = 56.0;
  const middleY = (topInset + 600) / 2;

  Future<void> pumpArrows(
    WidgetTester tester, {
    VoidCallback? onBackward,
    VoidCallback? onForward,
  }) {
    tester.view.physicalSize = windowSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EdgeNavigationArrows(
            topInset: topInset,
            onBackward: onBackward,
            onForward: onForward,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }

  Future<TestGesture> hoverAt(WidgetTester tester, Offset position) async {
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(500, 300));
    await mouse.moveTo(position);
    await tester.pump(const Duration(milliseconds: 200));
    return mouse;
  }

  Finder arrowOpacity(bool forward) => find.ancestor(
        of: find.byWidgetPredicate((widget) =>
            widget is DesktopArrowButton && widget.forward == forward),
        matching: find.byType(AnimatedOpacity),
      );

  double opacityOf(WidgetTester tester, bool forward) =>
      tester.widget<AnimatedOpacity>(arrowOpacity(forward)).opacity;

  testWidgets('arrows stay hidden while the cursor is mid screen',
      (tester) async {
    await pumpArrows(tester, onBackward: () {}, onForward: () {});
    await hoverAt(tester, const Offset(500, middleY));

    expect(opacityOf(tester, false), 0);
    expect(opacityOf(tester, true), 0);
  });

  testWidgets('the cursor near one edge at mid height shows both arrows',
      (tester) async {
    await pumpArrows(tester, onBackward: () {}, onForward: () {});
    await hoverAt(tester, const Offset(60, middleY));

    expect(opacityOf(tester, false), 1);
    expect(opacityOf(tester, true), 1);
  });

  testWidgets('the cursor near an edge just under the app bar shows nothing',
      (tester) async {
    await pumpArrows(tester, onBackward: () {}, onForward: () {});
    final mouse = await hoverAt(tester, const Offset(40, topInset + 10));

    expect(opacityOf(tester, false), 0);
    expect(opacityOf(tester, true), 0);

    await mouse.moveTo(const Offset(960, topInset + 10));
    await tester.pump(const Duration(milliseconds: 200));
    expect(opacityOf(tester, false), 0);
    expect(opacityOf(tester, true), 0);
  });

  testWidgets('moving out of the region hides the arrows', (tester) async {
    await pumpArrows(tester, onBackward: () {}, onForward: () {});
    final mouse = await hoverAt(tester, const Offset(60, middleY));
    expect(opacityOf(tester, false), 1);

    await mouse.moveTo(const Offset(60, topInset + 10));
    await tester.pump(const Duration(milliseconds: 200));
    expect(opacityOf(tester, false), 0);
    expect(opacityOf(tester, true), 0);
  });

  testWidgets('arrows hide once the cursor stops moving', (tester) async {
    await pumpArrows(tester, onBackward: () {}, onForward: () {});
    await hoverAt(tester, const Offset(60, middleY));
    expect(opacityOf(tester, false), 1);

    await tester.pump(const Duration(seconds: 3));
    expect(opacityOf(tester, false), 0);
    expect(opacityOf(tester, true), 0);
  });

  testWidgets('leaving the window hides the arrows', (tester) async {
    await pumpArrows(tester, onBackward: () {}, onForward: () {});
    final mouse = await hoverAt(tester, const Offset(60, middleY));
    expect(opacityOf(tester, false), 1);

    await mouse.removePointer();
    await tester.pump(const Duration(milliseconds: 200));
    expect(opacityOf(tester, false), 0);
  });

  testWidgets('a missing target removes its arrow and its edge',
      (tester) async {
    await pumpArrows(tester, onForward: () {});
    expect(find.byType(DesktopArrowButton), findsOneWidget);

    final mouse = await hoverAt(tester, const Offset(60, middleY));
    expect(opacityOf(tester, true), 0);

    await mouse.moveTo(const Offset(940, middleY));
    await tester.pump(const Duration(milliseconds: 200));
    expect(opacityOf(tester, true), 1);
  });

  testWidgets('arrows sit below the inset and press through', (tester) async {
    var pressed = 0;
    await pumpArrows(tester, onBackward: () => pressed++);
    await hoverAt(tester, const Offset(60, middleY));

    final center = tester.getCenter(find.byType(DesktopArrowButton));
    expect(center.dy, middleY);

    await tester.tapAt(center);
    expect(pressed, 1);
  });
}
