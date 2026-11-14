// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/custom_locale_delegates.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/utils/bulk_tag_editor.dart';
import 'package:daily_you/utils/gallery_entry_actions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../support/export_harness.dart';

void main() {
  final harness = ExportHarness();
  useExportHarness(harness);

  late Tag walk;
  late Entry first;
  late Entry second;

  Future<void> pumpEditButton(WidgetTester tester, TagChange change) async {
    await tester.runAsync(() async {
      walk = await harness.addTag('Walk', TagType.label);
      first = await harness.addEntry(DateTime(2026, 3, 1),
          tags: [if (change == TagChange.remove) SeededTag(walk)]);
      second = await harness.addEntry(DateTime(2026, 3, 2),
          tags: [if (change == TagChange.remove) SeededTag(walk)]);
    });
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: TagsProvider.instance,
      child: MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...appLocalizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => editEntryTags(context, [first, second], change),
            child: const Text('edit'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Walk'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
  }

  Set<int> tagIdsOf(Entry entry) => {
        for (final entryTag
            in TagsProvider.instance.getEntryTagsForEntry(entry.id!))
          entryTag.tagId
      };

  testWidgets('adding tags asks for confirmation and then applies them',
      (tester) async {
    await pumpEditButton(tester, TagChange.add);

    expect(find.text('Add the chosen tags to 2 logs?'), findsOneWidget);
    expect(find.text('Walk'), findsNWidgets(2));
    await tester.tap(find.text('Apply').last);
    await tester
        .runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();

    expect(tagIdsOf(first), {walk.id});
    expect(tagIdsOf(second), {walk.id});
  });

  testWidgets('cancelling the confirmation changes nothing', (tester) async {
    await pumpEditButton(tester, TagChange.add);

    await tester.tap(find.text('Cancel').last);
    await tester.pumpAndSettle();

    expect(find.text('Add the chosen tags to 2 logs?'), findsNothing);
    expect(find.text('Apply'), findsOneWidget);
    expect(tagIdsOf(first), isEmpty);
    expect(tagIdsOf(second), isEmpty);
  });

  testWidgets('removing tags asks for confirmation first', (tester) async {
    await pumpEditButton(tester, TagChange.remove);

    expect(find.text('Remove the chosen tags from 2 logs?'), findsOneWidget);
    await tester.tap(find.text('Cancel').last);
    await tester.pumpAndSettle();

    expect(tagIdsOf(first), {walk.id});
  });
}
