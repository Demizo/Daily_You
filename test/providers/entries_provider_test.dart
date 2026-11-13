// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:async';

import 'package:daily_you/database/entry_store.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/entry_sort.dart';
import 'package:daily_you/models/gallery_filter.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final provider = EntriesProvider.instance;

  Entry entry(int id, String text, {int? mood}) => Entry(
        id: id,
        text: text,
        mood: mood,
        timeCreate: DateTime(2026, 1, 31 - id),
        timeModified: DateTime(2026, 1, 31 - id),
      );

  void useEntries(List<Entry> entries) {
    EntryStore.instance.entries = entries;
    provider.sortOrder = SortOrder.ascending;
    provider.sortOrder = SortOrder.descending;
  }

  Future<void> nextNotification() {
    final completer = Completer<void>();
    void listener() => completer.complete();
    provider.addListener(listener);
    return completer.future
        .whenComplete(() => provider.removeListener(listener));
  }

  Future<List<int>> search(String query) async {
    provider.searchText = query;
    if (query.isNotEmpty) await nextNotification();
    return [for (final result in provider.getFilteredEntries()) result.id!];
  }

  setUp(() {
    provider.filter = const GalleryFilter();
    provider.orderBy = OrderBy.date;
    provider.sortOrder = SortOrder.descending;
  });

  tearDown(() {
    provider.filter = const GalleryFilter();
    provider.trackerSortTagId = null;
    for (final id in [1, 2, 3]) {
      TagsProvider.instance.applyEntryTags(id, []);
    }
    EntryStore.instance.entries = [];
  });

  group('EntriesProvider search', () {
    test('returns every entry in the chosen order without search text', () {
      useEntries([entry(1, 'a'), entry(2, 'b'), entry(3, 'c')]);
      expect([for (final result in provider.getFilteredEntries()) result.id],
          [1, 2, 3]);
    });

    test('drops entries that do not match', () async {
      useEntries([entry(1, 'sunny day'), entry(2, 'rainy day')]);
      expect(await search('rainy'), [2]);
    });

    test('finds typo and accent matches', () async {
      useEntries(
          [entry(1, 'a cold day'), entry(2, 'I will receive it at the Café')]);
      expect(await search('recieve'), [2]);
      expect(await search('cafe'), [2]);
    });

    test('lists matches before partial matches', () async {
      useEntries([
        entry(1, 'will recve it'),
        entry(2, 'will receive it'),
        entry(3, 'will recive it'),
        entry(4, 'receive again'),
      ]);
      expect(await search('receive'), [2, 4, 1, 3]);
      expect(provider.exactMatchCount, 2);
    });

    test('counts every entry as a match without search text', () {
      useEntries([entry(1, 'a'), entry(2, 'b'), entry(3, 'c')]);
      expect(provider.exactMatchCount, 3);
    });

    test('sorts each tier by the chosen order', () async {
      useEntries([
        entry(1, 'will recive it', mood: 5),
        entry(2, 'will receive it', mood: 2),
        entry(3, 'will recive it', mood: 3),
        entry(4, 'receive again', mood: 4),
      ]);
      expect(await search('receive'), [2, 4, 1, 3]);

      provider.sortOrder = SortOrder.ascending;
      await nextNotification();
      expect([for (final result in provider.getFilteredEntries()) result.id],
          [4, 2, 3, 1]);

      provider.orderBy = OrderBy.mood;
      await nextNotification();
      expect([for (final result in provider.getFilteredEntries()) result.id],
          [2, 4, 3, 1]);
      expect(provider.exactMatchCount, 2);
    });

    test('keeps the chosen order between equal matches', () async {
      useEntries([
        entry(1, 'receive a', mood: 2),
        entry(2, 'receive b', mood: 5),
        entry(3, 'receive c', mood: 3),
      ]);
      expect(await search('receive'), [1, 2, 3]);

      provider.orderBy = OrderBy.mood;
      await nextNotification();
      expect([for (final result in provider.getFilteredEntries()) result.id],
          [2, 3, 1]);

      provider.sortOrder = SortOrder.ascending;
      await nextNotification();
      expect([for (final result in provider.getFilteredEntries()) result.id],
          [1, 3, 2]);
    });

    test('restores the chosen order when the search text is cleared', () async {
      useEntries([entry(1, 'a day'), entry(2, 'a zeppelin day')]);
      expect(await search('zeppelin'), [2]);
      expect(await search(''), [1, 2]);
    });

    test('keeps the previous results while searching', () async {
      useEntries([entry(1, 'a day'), entry(2, 'a zeppelin day')]);
      provider.searchText = 'zeppelin';
      expect([for (final result in provider.getFilteredEntries()) result.id],
          [1, 2]);
      await nextNotification();
      expect(
          [for (final result in provider.getFilteredEntries()) result.id], [2]);
    });

    test('drops the results of a superseded search', () async {
      useEntries([entry(1, 'a zeppelin day'), entry(2, 'a rainy day')]);
      provider.searchText = 'zeppelin';
      provider.searchText = 'rainy';
      await nextNotification();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(
          [for (final result in provider.getFilteredEntries()) result.id], [2]);
    });

    test('picks up edited and added entries on the next search', () async {
      useEntries([entry(1, 'a day'), entry(2, 'another day')]);
      expect(await search('zeppelin'), isEmpty);

      useEntries([entry(1, 'a zeppelin day'), entry(2, 'another day')]);
      expect(await search('zeppelin'), [1]);

      useEntries([
        entry(1, 'a zeppelin day'),
        entry(2, 'another day'),
        entry(3, 'zeppelin again'),
      ]);
      expect(await search('zeppelin'), [1, 3]);
    });
  });

  group('EntriesProvider filters', () {
    List<int> ids() =>
        [for (final result in provider.getFilteredEntries()) result.id!];

    EntryTag trackerValue(int entryId, int tagId, String value) => EntryTag(
          entryId: entryId,
          tagId: tagId,
          value: value,
          timeCreate: DateTime(2026),
        );

    test('applies a filter right away', () {
      useEntries([
        entry(1, 'a', mood: 5),
        entry(2, 'b', mood: 2),
        entry(3, 'c', mood: 5),
      ]);
      provider.filter = const GalleryFilter(moods: {5});
      expect(ids(), [1, 3]);
      provider.filter = const GalleryFilter();
      expect(ids(), [1, 2, 3]);
    });

    test('stacks the search text with the other filters', () async {
      useEntries([
        entry(1, 'sunny day', mood: 5),
        entry(2, 'sunny walk', mood: 2),
        entry(3, 'rainy day', mood: 5),
      ]);
      provider.filter = const GalleryFilter(moods: {5});
      expect(await search('sunny'), [1]);
      expect(await search('day'), [1, 3]);
      expect(provider.filter.moods, {5});
    });

    test('keeps the other filters when the search text is cleared', () async {
      useEntries([entry(1, 'sunny', mood: 5), entry(2, 'sunny', mood: 2)]);
      provider.filter = const GalleryFilter(moods: {2});
      expect(await search('sunny'), [2]);
      expect(await search(''), [2]);
    });

    test('follows tag changes when filtering by tag', () {
      useEntries([entry(1, 'a'), entry(2, 'b')]);
      provider.filter = const GalleryFilter(tagIds: {7});
      expect(ids(), isEmpty);
      TagsProvider.instance.applyEntryTags(2, [trackerValue(2, 7, '1')]);
      expect(ids(), [2]);
    });

    test('keeps the tracker sort while searching', () async {
      useEntries([entry(1, 'sun'), entry(2, 'sun'), entry(3, 'sun')]);
      TagsProvider.instance.applyEntryTags(1, [trackerValue(1, 7, '1')]);
      TagsProvider.instance.applyEntryTags(2, [trackerValue(2, 7, '5')]);
      TagsProvider.instance.applyEntryTags(3, [trackerValue(3, 7, '3')]);
      provider.orderBy = OrderBy.tracker;
      provider.trackerSortTagId = 7;
      expect(ids(), [2, 3, 1]);

      expect(await search('sun'), [2, 3, 1]);
      expect(await search(''), [2, 3, 1]);
    });
  });
}
