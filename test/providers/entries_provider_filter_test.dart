// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/database/entry_store.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EntriesProvider Filter & Search (F03)', () {
    final provider = EntriesProvider.instance;

    setUp(() {
      provider.clearFilters();
    });

    test('filters entries by search text', () {
      final now = DateTime.now();
      EntryStore.instance.entries = [
        Entry(id: 1, text: 'Went to the grocery store', timeCreate: now, timeModified: now),
        Entry(id: 2, text: 'Coding Flutter all day', timeCreate: now, timeModified: now),
        Entry(id: 3, text: 'Read a great book', timeCreate: now, timeModified: now),
      ];

      provider.searchText = 'flutter';
      final filtered = provider.getFilteredEntries();
      expect(filtered.length, 1);
      expect(filtered.first.id, 2);

      provider.clearFilters();
      expect(provider.getFilteredEntries().length, 3);
    });

    test('filters entries by date range', () {
      final day1 = DateTime(2025, 1, 1);
      final day2 = DateTime(2025, 2, 1);
      final day3 = DateTime(2025, 3, 1);

      EntryStore.instance.entries = [
        Entry(id: 1, text: 'Jan', timeCreate: day1, timeModified: day1),
        Entry(id: 2, text: 'Feb', timeCreate: day2, timeModified: day2),
        Entry(id: 3, text: 'Mar', timeCreate: day3, timeModified: day3),
      ];

      provider.startDate = DateTime(2025, 1, 15);
      provider.endDate = DateTime(2025, 2, 15);

      final filtered = provider.getFilteredEntries();
      expect(filtered.length, 1);
      expect(filtered.first.text, 'Feb');
    });

    test('filters entries by multi-tag selection', () {
      final now = DateTime.now();
      EntryStore.instance.entries = [
        Entry(id: 1, text: 'Work note', timeCreate: now, timeModified: now),
        Entry(id: 2, text: 'Personal note', timeCreate: now, timeModified: now),
        Entry(id: 3, text: 'Un-tagged note', timeCreate: now, timeModified: now),
      ];

      TagsProvider.instance.applyEntryTags(1, [
        EntryTag(id: 1, entryId: 1, tagId: 10, timeCreate: now),
      ]);
      TagsProvider.instance.applyEntryTags(2, [
        EntryTag(id: 2, entryId: 2, tagId: 20, timeCreate: now),
      ]);
      TagsProvider.instance.applyEntryTags(3, const []);

      provider.filterTagIds = {10, 20};
      expect(provider.getFilteredEntries().length, 2);

      provider.filterTagIds = {20};
      final filtered2 = provider.getFilteredEntries();
      expect(filtered2.length, 1);
      expect(filtered2.first.id, 2);
    });
  });
}
