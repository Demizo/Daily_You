// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/entry.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:flutter/foundation.dart';

class GallerySelection with ChangeNotifier {
  static final GallerySelection instance =
      GallerySelection(EntriesProvider.instance);

  GallerySelection(this._entriesProvider) {
    _entriesProvider.addListener(_pruneToVisible);
  }

  final EntriesProvider _entriesProvider;
  Set<int> _selectedIds = {};
  int? _anchorId;
  Set<int> _dragBaseline = {};
  int? _dragOriginId;
  bool _dragSelects = true;

  bool get active => _selectedIds.isNotEmpty;

  int get selectedCount => _selectedIds.length;

  int get selectableCount => _visibleEntries.length;

  List<Entry> get selectedEntries => [
        for (final entry in _visibleEntries)
          if (_selectedIds.contains(entry.id)) entry
      ];

  List<Entry> get _visibleEntries => _entriesProvider.getFilteredEntries();

  List<Entry> get _exactEntries =>
      _visibleEntries.take(_entriesProvider.exactMatchCount).toList();

  List<Entry> get _partialEntries =>
      _visibleEntries.skip(_entriesProvider.exactMatchCount).toList();

  bool isSelected(int entryId) => _selectedIds.contains(entryId);

  void toggle(int entryId) {
    if (_selectedIds.remove(entryId)) {
      if (_anchorId == entryId) _anchorId = null;
    } else {
      if (!_isVisible(entryId)) return;
      _selectedIds = {..._selectedIds, entryId};
      _anchorId = entryId;
    }
    _selectionChanged();
  }

  void selectRange(int entryId) {
    final range = _idsBetween(_anchorId, entryId);
    if (range == null) {
      if (!isSelected(entryId)) toggle(entryId);
      return;
    }
    _selectedIds = {..._selectedIds, ...range};
    notifyListeners();
  }

  void beginDrag(int entryId) {
    if (!_isVisible(entryId)) return;
    _dragBaseline = _selectedIds;
    _dragOriginId = entryId;
    _dragSelects = !isSelected(entryId);
    if (_dragSelects) _anchorId = entryId;
    dragTo(entryId);
  }

  void dragTo(int entryId) {
    final range = _idsBetween(_dragOriginId, entryId);
    if (range == null) return;
    _selectedIds = _dragSelects
        ? {..._dragBaseline, ...range}
        : _dragBaseline.difference(range.toSet());
    _selectionChanged();
  }

  int get partialMatchCount => _entriesProvider.partialMatchCount;

  bool get offersPartialMatches =>
      _entriesProvider.exactMatchCount > 0 &&
      _entriesProvider.partialMatchCount > 0 &&
      !_partialEntries.any((entry) => isSelected(entry.id!));

  void selectAll({bool includePartial = true}) {
    final entries = includePartial ? _visibleEntries : _exactEntries;
    final visibleIds = [for (final entry in entries) entry.id!];
    if (visibleIds.isEmpty) return;
    _selectedIds = {..._selectedIds, ...visibleIds};
    _selectionChanged();
  }

  void clear() {
    if (!active) return;
    _selectedIds = {};
    _selectionChanged();
  }

  @override
  void dispose() {
    _entriesProvider.removeListener(_pruneToVisible);
    super.dispose();
  }

  List<int>? _idsBetween(int? originId, int targetId) {
    final visibleIds = [for (final entry in _visibleEntries) entry.id!];
    final originIndex = visibleIds.indexOf(originId ?? -1);
    final targetIndex = visibleIds.indexOf(targetId);
    if (originIndex == -1 || targetIndex == -1) return null;
    final start = originIndex < targetIndex ? originIndex : targetIndex;
    final end = originIndex < targetIndex ? targetIndex : originIndex;
    return visibleIds.sublist(start, end + 1);
  }

  bool _isVisible(int entryId) =>
      _visibleEntries.any((entry) => entry.id == entryId);

  void _selectionChanged() {
    if (!active) _anchorId = null;
    notifyListeners();
  }

  void _pruneToVisible() {
    if (!active) return;
    final storedIds = {for (final entry in _entriesProvider.entries) entry.id!};
    final visibleIds = {
      for (final entry in _visibleEntries)
        if (storedIds.contains(entry.id)) entry.id!
    };
    final remaining = _selectedIds.intersection(visibleIds);
    if (remaining.length == _selectedIds.length) return;
    _selectedIds = remaining;
    _selectionChanged();
  }
}
