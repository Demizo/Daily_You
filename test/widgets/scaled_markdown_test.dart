// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/custom_locale_delegates.dart';
import 'package:daily_you/widgets/scaled_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/highlighted_texts.dart';

void main() {
  Future<void> pumpMarkdown(WidgetTester tester, String data, String query) {
    return tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: sdkLocalizationsDelegates,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ScaledMarkdown(data: data, highlightQuery: query),
          ),
        ),
      ),
    );
  }

  testWidgets('highlights matches in plain, bold, inline code and code blocks',
      (tester) async {
    await pumpMarkdown(
      tester,
      'a needle\n\n**bold needle**\n\n`code needle`\n\n```\nblock needle\n```',
      'needle',
    );

    expect(highlightedTexts(tester), ['needle', 'needle', 'needle', 'needle']);
  });

  testWidgets('highlights a match split across styled nodes', (tester) async {
    await pumpMarkdown(tester, 'hel**lo** there', 'hello');

    expect(highlightedTexts(tester), ['hel', 'lo']);
  });

  testWidgets('does not highlight without a query', (tester) async {
    await pumpMarkdown(tester, 'a needle', '');

    expect(highlightedTexts(tester), isEmpty);
  });

  testWidgets('does not highlight text hidden in link syntax', (tester) async {
    await pumpMarkdown(tester, '[label](https://needle.example)', 'needle');

    expect(highlightedTexts(tester), isEmpty);
  });
}
