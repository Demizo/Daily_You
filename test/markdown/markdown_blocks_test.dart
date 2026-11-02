// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/custom_locale_delegates.dart';
import 'package:daily_you/widgets/scaled_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Future<void> pumpMarkdown(WidgetTester tester, String data) {
    return tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        home: Scaffold(
          body: SingleChildScrollView(child: ScaledMarkdown(data: data)),
        ),
      ),
    );
  }

  int paragraphCount(WidgetTester tester) =>
      tester.widgetList<RichText>(find.byType(RichText)).length;

  testWidgets('a list item is a paragraph of its own, not an inline widget',
      (tester) async {
    await pumpMarkdown(tester, '- one\n- two\n- three');

    expect(find.text('one', findRichText: true), findsOneWidget);
    expect(find.text('two', findRichText: true), findsOneWidget);
    expect(find.text('three', findRichText: true), findsOneWidget);
    expect(find.byType(WidgetSpan), findsNothing);
  });

  testWidgets('nested lists and quotes lay out as blocks', (tester) async {
    await pumpMarkdown(
      tester,
      '- parent\n  - child\n\n> quoted words\n\n# Title\n\n---',
    );

    expect(find.text('parent', findRichText: true), findsOneWidget);
    expect(find.text('child', findRichText: true), findsOneWidget);
    expect(find.text('quoted words', findRichText: true), findsOneWidget);
    expect(find.text('Title', findRichText: true), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a paragraph is one rich text', (tester) async {
    await pumpMarkdown(tester, 'one **two** three');

    expect(paragraphCount(tester), 1);
  });

  testWidgets('keeps a task list marker beside its text', (tester) async {
    await pumpMarkdown(tester, '- [x] done\n- [ ] todo');

    expect(find.text('done', findRichText: true), findsOneWidget);
    expect(find.text('todo', findRichText: true), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
