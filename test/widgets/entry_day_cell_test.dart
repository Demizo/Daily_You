// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/l10n/generated/app_localizations_en.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/mood_scale_preset.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/mood_scale_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/widgets/entry_day_cell.dart';
import 'package:flutter/semantics.dart' show SemanticsNode;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../support/config_provider_harness.dart';

void main() {
  useTemporaryConfig();

  final date = DateTime(2026, 3, 4);

  Entry entry({int? mood}) =>
      Entry(text: '', timeCreate: date, timeModified: date, mood: mood);

  Future<void> pumpCell(WidgetTester tester, List<Entry> entries) {
    MoodScaleProvider.instance.levels = MoodScalePreset.emoji.levels;
    return tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: EntriesProvider.instance),
          ChangeNotifierProvider.value(value: TagsProvider.instance),
          ChangeNotifierProvider.value(value: MoodScaleProvider.instance),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: EntryDayCell(
                date: date,
                today: DateTime(2026, 3, 10),
                dayNumber: null,
                cellSize: 60,
                entries: entries,
                coverCandidates: const [],
              ),
            ),
          ),
        ),
      ),
    );
  }

  SemanticsNode cellNode(WidgetTester tester) =>
      tester.getSemantics(find.byType(EntryDayCell));

  testWidgets('announces the date and mood as one node without children',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCell(tester, [entry(mood: 4)]);

    final mood =
        MoodScaleProvider.instance.moodPrefixOf(4, AppLocalizationsEn()).trim();
    expect(cellNode(tester).label, 'Mar 4, 2026. $mood');
    expect(cellNode(tester).childrenCount, 0);
    handle.dispose();
  });

  testWidgets('announces how many logs a day has', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCell(tester, [entry(mood: 4), entry(mood: 2)]);

    expect(cellNode(tester).label, 'Mar 4, 2026. 2 logs');
    handle.dispose();
  });

  testWidgets('announces only the date for a day without logs', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCell(tester, const []);

    expect(cellNode(tester).label, 'Mar 4, 2026');
    expect(cellNode(tester).childrenCount, 0);
    handle.dispose();
  });
}
