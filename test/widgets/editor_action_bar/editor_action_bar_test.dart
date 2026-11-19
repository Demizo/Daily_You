// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/widgets/editor_action_bar.dart';
import 'package:daily_you/widgets/editor_action_bar/dock_metrics.dart';
import 'package:daily_you/widgets/markdown_preview_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

bool isHighlighted(WidgetTester tester, IconData icon) {
  final button = find.ancestor(
    of: find.byIcon(icon),
    matching: find.byType(IconButton),
  );
  final material = tester.widget<Material>(
      find.descendant(of: button, matching: find.byType(Material)).first);
  final colorScheme = Theme.of(tester.element(button)).colorScheme;
  return material.color == colorScheme.secondary ||
      material.color == colorScheme.primary;
}

Future<void> pumpDockedBar(
  WidgetTester tester, {
  required double width,
  UndoHistoryController? undoController,
  TextDirection textDirection = TextDirection.ltr,
}) async {
  final controller = MarkdownPreviewController();
  final focusNode = FocusNode();
  addTearDown(controller.dispose);
  addTearDown(focusNode.dispose);

  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Directionality(
        textDirection: textDirection,
        child: Center(
          child: SizedBox(
            width: width,
            child: DockProgressScope(
              progress: const AlwaysStoppedAnimation(1),
              child: EditorActionBar(
                controller: controller,
                focusNode: focusNode,
                undoController: undoController,
                showTemplateButton: false,
              ),
            ),
          ),
        ),
      ),
    ),
  ));
}

void main() {
  testWidgets('docked actions scroll and indicate hidden actions',
      (tester) async {
    await pumpDockedBar(tester, width: 220);

    expect(find.byIcon(Icons.more_horiz_rounded), findsNothing);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left_rounded), findsNothing);

    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    expect(find.byIcon(Icons.link_rounded), findsOneWidget);
  });

  testWidgets('tapping an arrow scrolls toward that end', (tester) async {
    await pumpDockedBar(tester, width: 220);

    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.chevron_left_rounded), findsNothing);
  });

  testWidgets('arrows swap sides in right to left layouts', (tester) async {
    await pumpDockedBar(tester, width: 220, textDirection: TextDirection.rtl);

    expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
  });

  testWidgets('arrows update when the bar is resized', (tester) async {
    await pumpDockedBar(tester, width: 220);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

    await pumpDockedBar(tester, width: 600);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
  });

  testWidgets('undo and redo scroll with the actions', (tester) async {
    final undoController = UndoHistoryController();
    addTearDown(undoController.dispose);
    await pumpDockedBar(tester, width: 220, undoController: undoController);

    final barRight = tester.getTopRight(find.byType(EditorActionBar)).dx;
    expect(tester.getTopRight(find.byIcon(Icons.redo_rounded)).dx,
        greaterThan(barRight));

    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(tester.getTopRight(find.byIcon(Icons.redo_rounded)).dx,
        lessThanOrEqualTo(barRight));
  });

  testWidgets('docked divider spans the button height', (tester) async {
    final undoController = UndoHistoryController();
    addTearDown(undoController.dispose);
    await pumpDockedBar(tester, width: 220, undoController: undoController);

    expect(tester.getSize(find.byType(VerticalDivider)).height, 40);
  });

  testWidgets('format buttons follow the cursor and toggle off',
      (tester) async {
    final controller = MarkdownPreviewController(text: 'a **bold** b');
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    controller.selection = const TextSelection.collapsed(offset: 6);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: EditorActionBar(
            controller: controller,
            focusNode: focusNode,
            showTemplateButton: false,
          ),
        ),
      ),
    ));

    expect(isHighlighted(tester, Icons.format_bold_rounded), isTrue);
    expect(isHighlighted(tester, Icons.format_italic_rounded), isFalse);

    controller.selection = const TextSelection.collapsed(offset: 0);
    await tester.pump();
    expect(isHighlighted(tester, Icons.format_bold_rounded), isFalse);

    controller.selection = const TextSelection.collapsed(offset: 6);
    await tester.pump();
    await tester.tap(find.byIcon(Icons.format_bold_rounded));
    await tester.pump();

    expect(controller.text, 'a bold b');
    expect(isHighlighted(tester, Icons.format_bold_rounded), isFalse);
  });
}
