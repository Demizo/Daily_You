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

void main() {
  testWidgets('docked actions scroll and indicate hidden actions',
      (tester) async {
    final controller = MarkdownPreviewController();
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 220,
            child: DockProgressScope(
              progress: const AlwaysStoppedAnimation(1),
              child: EditorActionBar(
                controller: controller,
                focusNode: focusNode,
                showTemplateButton: false,
              ),
            ),
          ),
        ),
      ),
    ));

    expect(find.byIcon(Icons.more_horiz_rounded), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    // drags left, no more icons remain on the right, so right chevron disappears
    await tester.drag(find.byType(SingleChildScrollView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    expect(find.byIcon(Icons.link_rounded), findsOneWidget);
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
