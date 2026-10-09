// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/database/entry_store.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/pages/tags_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
import 'package:daily_you/providers/entry_locations_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/widgets/large_entry_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../support/config_provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  useTemporaryConfig();

  testWidgets('TagsPage displays Spaces, People, and Topics tabs',
      (tester) async {
    final now = DateTime(2026, 10, 9);
    final tag1 = Tag(
      id: 1,
      name: 'Work',
      tagType: TagType.label,
      timeCreate: now,
      timeModified: now,
    );
    final tag2 = Tag(
      id: 2,
      name: '@Alice',
      tagType: TagType.label,
      timeCreate: now,
      timeModified: now,
    );
    final tag3 = Tag(
      id: 3,
      name: '#Vacation',
      tagType: TagType.label,
      timeCreate: now,
      timeModified: now,
    );

    TagsProvider.instance.tags = [tag1, tag2, tag3];
    EntryStore.instance.entries = [
      Entry(id: 1, text: 'Met with @Alice', timeCreate: now, timeModified: now),
    ];
    EntryStore.instance.notifyListeners();
    TagsProvider.instance.applyEntryTags(1, [
      EntryTag(id: 1, entryId: 1, tagId: 2, timeCreate: now),
    ]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: TagsProvider.instance),
          ChangeNotifierProvider.value(value: EntriesProvider.instance),
          ChangeNotifierProvider.value(value: EntryImagesProvider.instance),
          ChangeNotifierProvider.value(value: EntryLocationsProvider.instance),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TagsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Spaces'), findsOneWidget);
    expect(find.text('People'), findsOneWidget);
    expect(find.text('Topics'), findsOneWidget);

    // Initial tab is Spaces -> should see 'Work'
    expect(
        find.byWidgetPredicate(
            (w) => w is FilterChip && w.label is Text && (w.label as Text).data == 'Work'),
        findsOneWidget);

    // Switch to People tab
    await tester.tap(find.text('People'));
    await tester.pumpAndSettle();

    expect(
        find.byWidgetPredicate(
            (w) => w is FilterChip && w.label is Text && (w.label as Text).data == '@Alice (1)'),
        findsOneWidget);
    expect(find.byType(LargeEntryCardWidget), findsOneWidget);

    // Switch to Topics tab
    await tester.tap(find.text('Topics'));
    await tester.pumpAndSettle();

    expect(
        find.byWidgetPredicate(
            (w) => w is FilterChip && w.label is Text && (w.label as Text).data == '#Vacation'),
        findsOneWidget);
  });
}
