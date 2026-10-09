// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/person.dart';
import 'package:daily_you/models/space.dart';
import 'package:daily_you/providers/people_provider.dart';
import 'package:daily_you/providers/spaces_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpacesProvider tests', () {
    test('Spaces are user-created and do not require default Personal space', () {
      final now = DateTime(2026, 10, 9);
      final provider = SpacesProvider.instance;
      provider.spaces.clear();

      expect(provider.spaces.isEmpty, isTrue);

      final space = Space(
        id: 1,
        name: 'Work',
        timeCreate: now,
        timeModified: now,
      );
      provider.spaces.add(space);
      expect(provider.spaces.length, 1);
      expect(provider.spaces.first.name, 'Work');
    });

    test('getEntriesForSpace does not duplicate normal journals under custom space', () {
      final now = DateTime(2026, 10, 9);
      final provider = SpacesProvider.instance;
      provider.spaces.clear();
      provider.spaces.addAll([
        Space(id: 1, name: 'Work', isDefault: false, timeCreate: now, timeModified: now),
        Space(id: 2, name: 'Travel', isDefault: false, timeCreate: now, timeModified: now),
      ]);

      final entry1 = Entry(id: 1, text: 'Work meeting #work', timeCreate: now, timeModified: now);
      final entry2 = Entry(id: 2, text: 'Trip to Tokyo', timeCreate: now, timeModified: now);
      final entry3 = Entry(id: 3, text: 'Normal unassigned journal', timeCreate: now, timeModified: now);

      final allEntries = [entry1, entry2, entry3];

      provider.entrySpaces.clear();
      provider.entrySpaces[2] = 2; // Entry 2 explicitly in Travel

      // Entry 2 is in Travel
      final travelEntries = provider.getEntriesForSpace(2, allEntries);
      expect(travelEntries.length, 1);
      expect(travelEntries.first.id, 2);

      // Entry 1 has #work tag, so it matches Work space
      // Entry 3 is a Normal Journal with no space assignment, so it does NOT appear under Work
      final workEntries = provider.getEntriesForSpace(1, allEntries);
      expect(workEntries.length, 1);
      expect(workEntries.first.id, 1);
      expect(workEntries.any((e) => e.id == 3), isFalse);
    });
  });

  group('PeopleProvider tests', () {
    test('People filtering matches explicitly linked and text-tagged entries', () {
      final now = DateTime(2026, 10, 9);
      final provider = PeopleProvider.instance;
      provider.people.clear();
      provider.people.addAll([
        Person(id: 1, name: 'Alice', timeCreate: now, timeModified: now),
        Person(id: 2, name: 'Bob', timeCreate: now, timeModified: now),
      ]);

      final entry1 = Entry(id: 1, text: 'Lunch with @Alice', timeCreate: now, timeModified: now);
      final entry2 = Entry(id: 2, text: 'Call with team', timeCreate: now, timeModified: now);

      final allEntries = [entry1, entry2];

      provider.entryPeople.clear();
      provider.entryPeople[2] = [2]; // Entry 2 explicitly tagged with Bob

      final aliceEntries = provider.getEntriesForPerson(1, allEntries);
      expect(aliceEntries.length, 1);
      expect(aliceEntries.first.id, 1);

      final bobEntries = provider.getEntriesForPerson(2, allEntries);
      expect(bobEntries.length, 1);
      expect(bobEntries.first.id, 2);
    });
  });
}
