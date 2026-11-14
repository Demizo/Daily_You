// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:async';

import 'package:daily_you/database/entry_store.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/entry_sort.dart';
import 'package:daily_you/models/gallery_filter.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/gallery_selection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final entriesProvider = EntriesProvider.instance;
  late GallerySelection selection;

  Entry entry(int id, String text) => Entry(
        id: id,
        text: text,
        timeCreate: DateTime(2026, 1, 31 - id),
        timeModified: DateTime(2026, 1, 31 - id),
      );

  void useEntries(List<Entry> entries) {
    EntryStore.instance.entries = entries;
    entriesProvider.filter = const GalleryFilter();
  }

  Future<void> search(String query) {
    entriesProvider.searchText = query;
    final completer = Completer<void>();
    void listener() => completer.complete();
    entriesProvider.addListener(listener);
    return completer.future
        .whenComplete(() => entriesProvider.removeListener(listener));
  }

  List<int> selectedIds() =>
      [for (final selected in selection.selectedEntries) selected.id!];

  setUp(() {
    selection = GallerySelection(entriesProvider);
    useEntries([for (var id = 1; id <= 5; id++) entry(id, 'log $id')]);
  });

  tearDown(() {
    selection.dispose();
    entriesProvider.filter = const GalleryFilter();
    EntryStore.instance.entries = [];
  });

  test('toggling the first log starts selecting and the last one ends it', () {
    expect(selection.active, isFalse);
    selection.toggle(2);
    expect(selection.active, isTrue);
    selection.toggle(3);
    expect(selection.selectedCount, 2);
    selection.toggle(2);
    selection.toggle(3);
    expect(selection.active, isFalse);
  });

  test('counts the selected and selectable logs', () {
    selection.toggle(1);
    expect(selection.selectedCount, 1);
    expect(selection.selectableCount, 5);
  });

  test('ignores a log that is not on screen', () {
    selection.toggle(99);
    expect(selection.active, isFalse);
  });

  test('selects a range in visible order from the first selected log', () {
    selection.toggle(2);
    selection.selectRange(4);
    expect(selectedIds(), [2, 3, 4]);
  });

  test('selects a range backwards', () {
    selection.toggle(4);
    selection.selectRange(2);
    expect(selectedIds(), [2, 3, 4]);
  });

  test('follows the sort order when selecting a range', () {
    entriesProvider.sortOrder = SortOrder.ascending;
    selection.toggle(4);
    selection.selectRange(2);
    expect(selectedIds(), [4, 3, 2]);
    entriesProvider.sortOrder = SortOrder.descending;
  });

  test('a range without an anchor selects the log alone', () {
    selection.selectRange(3);
    expect(selectedIds(), [3]);
  });

  test('select all takes every log when not searching', () {
    selection.selectAll();
    expect(selection.selectedCount, 5);
  });

  test('select all takes exact and partial matches', () async {
    useEntries([
      entry(1, 'will recve it'),
      entry(2, 'will receive it'),
      entry(3, 'will recive it'),
      entry(4, 'receive again'),
    ]);
    await search('receive');

    selection.selectAll();
    expect(selectedIds(), [2, 4, 1, 3]);
    expect(selection.selectedCount, selection.selectableCount);
  });

  test('partial matches are offered once exact and partial both exist',
      () async {
    expect(selection.offersPartialMatches, isFalse);

    useEntries([
      entry(1, 'will recve it'),
      entry(2, 'will receive it'),
      entry(3, 'will recive it'),
      entry(4, 'receive again'),
    ]);
    await search('receive');

    expect(selection.offersPartialMatches, isTrue);
    expect(selection.partialMatchCount, 2);
  });

  test('partial matches are not offered when one is already selected',
      () async {
    useEntries([
      entry(1, 'will recve it'),
      entry(2, 'will receive it'),
    ]);
    await search('receive');

    selection.toggle(1);

    expect(selection.offersPartialMatches, isFalse);
  });

  test('select all can leave the partial matches out', () async {
    useEntries([
      entry(1, 'will recve it'),
      entry(2, 'will receive it'),
      entry(3, 'will recive it'),
      entry(4, 'receive again'),
    ]);
    await search('receive');

    selection.selectAll(includePartial: false);

    expect(selectedIds(), [2, 4]);
  });

  test('dragging selects the logs between the origin and the pointer', () {
    selection.beginDrag(2);
    selection.dragTo(4);
    expect(selectedIds(), [2, 3, 4]);

    selection.dragTo(3);
    expect(selectedIds(), [2, 3]);
  });

  test('dragging keeps logs that were selected before it began', () {
    selection.toggle(5);
    selection.beginDrag(2);
    selection.dragTo(3);
    expect(selectedIds(), [2, 3, 5]);
  });

  test('dragging from a selected log deselects the logs it passes', () {
    for (final id in [1, 2, 3, 4]) {
      selection.toggle(id);
    }
    selection.beginDrag(3);
    selection.dragTo(2);
    expect(selectedIds(), [1, 4]);

    selection.dragTo(3);
    expect(selectedIds(), [1, 2, 4]);
  });

  test('clearing ends selecting', () {
    selection.selectAll();
    selection.clear();
    expect(selection.active, isFalse);
    expect(selection.selectedCount, 0);
  });

  test('drops selected logs that leave the results', () async {
    useEntries([
      entry(1, 'sunny day'),
      entry(2, 'rainy day'),
      entry(3, 'rainy night'),
    ]);
    selection.toggle(1);
    selection.toggle(2);
    selection.toggle(3);

    await search('rainy');

    expect(selectedIds(), [2, 3]);
  });

  test('ends selecting when every selected log leaves the results', () async {
    useEntries([entry(1, 'sunny day'), entry(2, 'rainy day')]);
    selection.toggle(1);

    await search('rainy');

    expect(selection.active, isFalse);
  });

  test('drops a log that is deleted', () {
    selection.toggle(1);
    selection.toggle(2);

    EntryStore.instance.entries =
        EntryStore.instance.entries.where((entry) => entry.id != 1).toList();
    entriesProvider.sortOrder = SortOrder.ascending;
    entriesProvider.sortOrder = SortOrder.descending;

    expect(selectedIds(), [2]);
  });

  test('notifies listeners only when the selection changes', () {
    selection.toggle(1);
    var notifications = 0;
    selection.addListener(() => notifications += 1);

    entriesProvider.sortOrder = SortOrder.ascending;
    expect(notifications, 0);

    selection.toggle(2);
    expect(notifications, 1);
    entriesProvider.sortOrder = SortOrder.descending;
  });
}
