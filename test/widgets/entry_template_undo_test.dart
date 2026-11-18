// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/utils/text_editing.dart';
import 'package:daily_you/widgets/entry_text_edit.dart';
import 'package:daily_you/widgets/markdown_preview_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  for (final initialText in ['', 'Existing entry']) {
    testWidgets('template insertion can be undone and redone: $initialText',
        (tester) async {
      final controller = MarkdownPreviewController();
      final focusNode = FocusNode();
      final undoController = UndoHistoryController();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);
      addTearDown(undoController.dispose);

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Column(
            children: [
              Expanded(
                child: EntryTextEditor(
                  text: initialText,
                  focusNode: focusNode,
                  textEditingController: controller,
                  undoHistoryController: undoController,
                ),
              ),
            ],
          ),
        ),
      ));
      // Flutter waits 500ms after a text change before saving it to undo history
      await tester.pump(const Duration(milliseconds: 500));
      // Simulate choosing a main action while the editor is unfocused
      insertTemplateText(controller, 'Template', hasFocus: false);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byType(TextField));
      await tester.pump();

      final insertedText =
          initialText.isEmpty ? 'Template' : '$initialText\nTemplate';
      expect(controller.text, insertedText);
      expect(undoController.value.canUndo, isTrue);
      undoController.undo();
      await tester.pump();
      expect(controller.text, initialText);
      expect(undoController.value.canRedo, isTrue);
      undoController.redo();
      await tester.pump();
      expect(controller.text, insertedText);
    });
  }
}
