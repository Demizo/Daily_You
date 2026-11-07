// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/widgets/editor_action_bar.dart';
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
