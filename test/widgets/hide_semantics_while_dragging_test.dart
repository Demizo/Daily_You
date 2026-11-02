// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/widgets/hide_semantics_while_dragging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  late ScrollController controller;

  Future<void> pumpList(WidgetTester tester) {
    controller = ScrollController();
    return tester.pumpWidget(
      MaterialApp(
        home: HideSemanticsWhileDragging(
          child: ListView(
            controller: controller,
            children: [
              for (var index = 0; index < 50; index++)
                SizedBox(height: 100, child: Text('item $index')),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('hides the list from semantics only while a finger scrolls it',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpList(tester);
    expect(find.semantics.byLabel('item 2'), findsOneWidget);

    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(ListView)));
    await gesture.moveBy(const Offset(0, -100));
    await tester.pump();
    expect(find.semantics.byLabel('item 2'), findsNothing);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.semantics.byLabel(RegExp(r'item \d+')), findsWidgets);
    handle.dispose();
  });

  testWidgets('keeps the list in semantics when an action scrolls it',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpList(tester);

    controller.animateTo(300,
        duration: const Duration(milliseconds: 300), curve: Curves.linear);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.semantics.byLabel(RegExp(r'item \d+')), findsWidgets);

    await tester.pumpAndSettle();
    handle.dispose();
  });
}
