// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/person.dart';
import 'package:daily_you/models/space.dart';
import 'package:daily_you/providers/people_provider.dart';
import 'package:daily_you/providers/spaces_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpacesProvider tests', () {
    test('Default spaces is at most 1-2', () {
      final now = DateTime(2026, 10, 9);
      final provider = SpacesProvider.instance;
      provider.spaces.clear();
      provider.spaces.add(Space(
        id: 1,
        name: 'Personal',
        isDefault: true,
        timeCreate: now,
        timeModified: now,
      ));

      expect(provider.spaces.length, lessThanOrEqualTo(2));
      expect(provider.defaultSpace.name, 'Personal');
    });

    test('getEntriesForSpace retrieves default and custom space entries properly', () {
      final now = DateTime(2026, 10, 9);
      final provider = SpacesProvider.instance;
      provider.spaces.clear();
      provider.spaces.addAll([
        Space(id: 1, name: 'Personal', isDefault: true, timeCreate: now, timeModified: now),
        Space(id: 2, name: 'Work', isDefault: false, timeCreate: now, timeModified: now),
      ]);

      final entry1 = Entry(id: 1, text: 'Personal diary note', timeCreate: now, timeModified: now);
      final entry2 = Entry(id: 2, text: 'Work meeting #work', timeCreate: now, timeModified: now);
      final entry3 = Entry(id: 3, text: 'Another entry', timeCreate: now, timeModified: now);

      final allEntries = [entry1, entry2, entry3];

      provider.entrySpaces.clear();
      provider.entrySpaces[2] = 2; // Entry 2 explicitly in Work

      // Entry 2 is in Work
      final workEntries = provider.getEntriesForSpace(2, allEntries);
      expect(workEntries.length, 1);
      expect(workEntries.first.id, 2);

      // Default space (Personal) gets unassigned entries (Entry 1 and Entry 3)
      final personalEntries = provider.getEntriesForSpace(1, allEntries);
      expect(personalEntries.length, 2);
      expect(personalEntries.map((e) => e.id).toSet(), {1, 3});
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
