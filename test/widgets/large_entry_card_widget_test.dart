// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/providers/mood_scale_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/widgets/large_entry_card_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../support/config_provider_harness.dart';
import '../support/highlighted_texts.dart';

void main() {
  useTemporaryConfig();

  final entry = Entry(
    text: 'first line\nsecond line has a needle in it',
    timeCreate: DateTime(2025, 1, 2),
    timeModified: DateTime(2025, 1, 2),
  );

  Future<void> pumpCard(WidgetTester tester, {String searchQuery = ''}) {
    return tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: TagsProvider.instance),
          ChangeNotifierProvider.value(value: MoodScaleProvider.instance),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 500,
                height: 250,
                child: LargeEntryCardWidget(
                  entry: entry,
                  attachments: const [],
                  searchQuery: searchQuery,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows the whole text without highlights when not searching',
      (tester) async {
    await pumpCard(tester);

    expect(
        find.textContaining('first line', findRichText: true), findsOneWidget);
    expect(highlightedTexts(tester), isEmpty);
  });

  testWidgets('starts at the matching line and highlights the match',
      (tester) async {
    await pumpCard(tester, searchQuery: 'needle');

    expect(find.textContaining('first line', findRichText: true), findsNothing);
    expect(highlightedTexts(tester), ['needle']);
  });
}
