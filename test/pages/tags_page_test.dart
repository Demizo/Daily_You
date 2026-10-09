// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/database/entry_store.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/person.dart';
import 'package:daily_you/models/space.dart';
import 'package:daily_you/pages/spaces_and_people_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
import 'package:daily_you/providers/entry_locations_provider.dart';
import 'package:daily_you/providers/people_provider.dart';
import 'package:daily_you/providers/spaces_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/widgets/large_entry_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../support/config_provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  useTemporaryConfig();

  testWidgets('SpacesAndPeoplePage displays Spaces and People tabs',
      (tester) async {
    final now = DateTime(2026, 10, 9);

    final space1 = Space(
      id: 1,
      name: 'Personal',
      isDefault: true,
      timeCreate: now,
      timeModified: now,
    );
    final space2 = Space(
      id: 2,
      name: 'Work',
      isDefault: false,
      timeCreate: now,
      timeModified: now,
    );

    final person1 = Person(
      id: 1,
      name: 'Alice',
      timeCreate: now,
      timeModified: now,
    );

    SpacesProvider.instance.spaces.clear();
    SpacesProvider.instance.spaces.addAll([space1, space2]);
    PeopleProvider.instance.people.clear();
    PeopleProvider.instance.people.add(person1);

    final entry1 = Entry(
      id: 1,
      text: 'Met with @Alice for project work',
      timeCreate: now,
      timeModified: now,
    );
    EntryStore.instance.entries = [entry1];
    EntryStore.instance.notifyListeners();

    SpacesProvider.instance.entrySpaces.clear();
    SpacesProvider.instance.entrySpaces[1] = 1; // Assigned to Personal
    PeopleProvider.instance.entryPeople.clear();
    PeopleProvider.instance.entryPeople[1] = [1]; // Associated with Alice

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: SpacesProvider.instance),
          ChangeNotifierProvider.value(value: PeopleProvider.instance),
          ChangeNotifierProvider.value(value: TagsProvider.instance),
          ChangeNotifierProvider.value(value: EntriesProvider.instance),
          ChangeNotifierProvider.value(value: EntryImagesProvider.instance),
          ChangeNotifierProvider.value(value: EntryLocationsProvider.instance),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SpacesAndPeoplePage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify tabs
    expect(find.text('Spaces'), findsOneWidget);
    expect(find.text('People'), findsOneWidget);

    // Initial tab is Spaces -> should see 'Personal' and 'Work'
    expect(
        find.byWidgetPredicate((w) =>
            w is FilterChip &&
            w.label is Text &&
            (w.label as Text).data!.startsWith('Personal')),
        findsOneWidget);
    expect(
        find.byWidgetPredicate((w) =>
            w is FilterChip &&
            w.label is Text &&
            (w.label as Text).data!.startsWith('Work')),
        findsOneWidget);

    // Personal space should show entry (fixing "No Entries" bug)
    expect(find.byType(LargeEntryCardWidget), findsOneWidget);

    // Switch to People tab
    await tester.tap(find.text('People'));
    await tester.pumpAndSettle();

    // Should see '@Alice'
    expect(
        find.byWidgetPredicate((w) =>
            w is FilterChip &&
            w.label is Text &&
            (w.label as Text).data!.startsWith('@Alice')),
        findsOneWidget);
    // Alice's entry should be displayed
    expect(find.byType(LargeEntryCardWidget), findsOneWidget);
  });
}
