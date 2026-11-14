// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:async';
import 'dart:isolate';

import 'package:daily_you/database/entry_store.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/entry_sort.dart';
import 'package:daily_you/models/gallery_filter.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/utils/folded_text_index.dart';
import 'package:daily_you/utils/gallery_filtering.dart';
import 'package:daily_you/utils/search_matcher.dart';
import 'package:material_ui/material_ui.dart';

class EntriesProvider with ChangeNotifier {
  static final EntriesProvider instance = EntriesProvider._init();

  EntriesProvider._init() {
    _store.addListener(_refresh);
    TagsProvider.instance.addListener(_onTagsChanged);
    EntryAttachmentsProvider.instance.addListener(_onAttachmentsChanged);
  }

  final EntryStore _store = EntryStore.instance;

  List<Entry> get entries => _store.entries;

  List<Entry> _filteredEntries = [];
  int _exactMatchCount = 0;
  FoldedTextIndex _foldedTextIndex = FoldedTextIndex.empty;
  int _searchSequence = 0;

  GalleryFilter _filter = const GalleryFilter();
  GalleryFilter get filter => _filter;

  set filter(GalleryFilter newFilter) {
    _filter = newFilter;
    _refresh();
  }

  String get searchText => _filter.searchText;

  set searchText(String newSearchText) {
    if (_filter.searchText == newSearchText) return;
    filter = _filter.copyWith(searchText: newSearchText);
  }

  OrderBy _orderBy = OrderBy.date;
  OrderBy get orderBy => _orderBy;

  set orderBy(OrderBy newOrderBy) {
    if (_orderBy == newOrderBy) return;
    _orderBy = newOrderBy;
    _refresh();
  }

  int? _trackerSortTagId;
  int? get trackerSortTagId => _trackerSortTagId;

  set trackerSortTagId(int? id) {
    if (_trackerSortTagId == id) return;
    _trackerSortTagId = id;
    _refresh();
  }

  SortOrder _sortOrder = SortOrder.descending;
  SortOrder get sortOrder => _sortOrder;

  set sortOrder(SortOrder newSortOrder) {
    if (_sortOrder == newSortOrder) return;
    _sortOrder = newSortOrder;
    _refresh();
  }

  Future<void> load() => _store.load();

  Future<Entry> add(Entry entry, {bool skipUpdate = false}) =>
      _store.add(entry, skipUpdate: skipUpdate);

  Future<void> deleteMany(List<Entry> entriesToDelete) =>
      _store.deleteMany(entriesToDelete);

  Future<void> deleteAll(Function(String) updateStatus) =>
      _store.deleteAll(updateStatus);

  int getIndexOfEntry(int entryId) => _store.getIndexOfEntry(entryId);

  Entry? getEntryForToday() => _store.getEntryForToday();

  Entry? getEntryForDate(DateTime date) => _store.getEntryForDate(date);

  List<Entry> getEntriesForDate(DateTime date) =>
      _store.getEntriesForDate(date);

  List<Entry> getFilteredEntries() => _filteredEntries;

  int get exactMatchCount => _exactMatchCount;

  int get partialMatchCount =>
      searchText.isNotEmpty ? _filteredEntries.length - _exactMatchCount : 0;

  void _onTagsChanged() {
    if (_filter.hasTags || _orderBy == OrderBy.tracker) _refresh();
  }

  void _onAttachmentsChanged() {
    if (_filter.hasAttachments) _refresh();
  }

  void _refresh() {
    _calculateFilteredEntries();
    notifyListeners();
  }

  void _calculateFilteredEntries() {
    final matchingEntries = filterAndSortEntries(
      entries: entries,
      filter: _filter,
      tagsOf: TagsProvider.instance.getEntryTagsForEntry,
      attachmentTypesOf: EntryAttachmentsProvider.instance.getTypesForEntry,
      orderBy: _orderBy,
      sortOrder: _sortOrder,
      trackerTagId: _trackerSortTagId,
      today: DateTime.now(),
    );

    final sequence = ++_searchSequence;
    if (_filter.hasSearchText) {
      unawaited(_tierEntries(matchingEntries, _filter.searchText, sequence));
    } else {
      _foldedTextIndex = FoldedTextIndex.empty;
      _filteredEntries = matchingEntries;
      _exactMatchCount = matchingEntries.length;
    }
  }

  Future<void> _tierEntries(
      List<Entry> matchingEntries, String query, int sequence) async {
    final texts = [for (final entry in matchingEntries) entry.text];
    final index = _foldedTextIndex;
    final (patchedIndex, tiers) = await Isolate.run(() {
      final patchedIndex = index.patched(texts);
      return (
        patchedIndex,
        tierByMatch(patchedIndex.foldedTexts(texts), query),
      );
    });
    if (sequence != _searchSequence) return;
    _foldedTextIndex = patchedIndex;
    _filteredEntries = [
      for (final position in [...tiers.exact, ...tiers.partial])
        matchingEntries[position],
    ];
    _exactMatchCount = tiers.exact.length;
    notifyListeners();
  }
}
