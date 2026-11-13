// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/entry_sort.dart';
import 'package:daily_you/models/gallery_filter.dart';
import 'package:daily_you/models/mood.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/utils/gallery_date_range.dart';

typedef EntryTagsLookup = List<EntryTag> Function(int entryId);
typedef EntryAttachmentTypesLookup = Set<AttachmentType> Function(int entryId);

List<Entry> filterAndSortEntries({
  required List<Entry> entries,
  required GalleryFilter filter,
  required EntryTagsLookup tagsOf,
  required EntryAttachmentTypesLookup attachmentTypesOf,
  required OrderBy orderBy,
  required SortOrder sortOrder,
  required int? trackerTagId,
  required DateTime today,
}) =>
    _sortEntries(
      _filterEntries(
        entries: entries,
        filter: filter,
        tagsOf: tagsOf,
        attachmentTypesOf: attachmentTypesOf,
        today: today,
      ),
      orderBy: orderBy,
      sortOrder: sortOrder,
      trackerTagId: trackerTagId,
      tagsOf: tagsOf,
    );

int _idOf(Entry entry) => entry.id ?? -1;

List<Entry> _filterEntries({
  required List<Entry> entries,
  required GalleryFilter filter,
  required EntryTagsLookup tagsOf,
  required EntryAttachmentTypesLookup attachmentTypesOf,
  required DateTime today,
}) {
  final matchers = <bool Function(Entry)>[
    if (filter.hasMood) _moodMatcher(filter),
    if (filter.hasTags) _tagMatcher(filter, tagsOf),
    if (filter.hasDate) _dateMatcher(filter, today),
    if (filter.hasAttachments) _attachmentMatcher(filter, attachmentTypesOf),
    if (filter.hasText) _textMatcher(filter),
  ];
  if (matchers.isEmpty) return entries.toList();
  return [
    for (final entry in entries)
      if (matchers.every((matches) => matches(entry))) entry,
  ];
}

bool Function(Entry) _moodMatcher(GalleryFilter filter) => (entry) {
      final mood = entry.mood;
      return mood == null ? filter.noMood : filter.moods.contains(mood);
    };

bool Function(Entry) _tagMatcher(
        GalleryFilter filter, EntryTagsLookup tagsOf) =>
    (entry) {
      final entryTags = tagsOf(_idOf(entry));
      if (filter.noTags) return entryTags.isEmpty;
      final entryTagIds = {for (final entryTag in entryTags) entryTag.tagId};
      return filter.tagMode == TagFilterMode.all
          ? filter.tagIds.every(entryTagIds.contains)
          : filter.tagIds.any(entryTagIds.contains);
    };

bool Function(Entry) _dateMatcher(GalleryFilter filter, DateTime today) {
  final range = dayRangeOf(filter.date, today)!;
  return (entry) =>
      !entry.timeCreate.isBefore(range.start) &&
      entry.timeCreate.isBefore(range.endExclusive);
}

bool Function(Entry) _attachmentMatcher(
  GalleryFilter filter,
  EntryAttachmentTypesLookup attachmentTypesOf,
) =>
    (entry) {
      final types = attachmentTypesOf(_idOf(entry));
      if (filter.noAttachments) return types.isEmpty;
      return types.any(filter.attachmentTypes.contains);
    };

bool Function(Entry) _textMatcher(GalleryFilter filter) {
  if (filter.noText) return (entry) => entry.text.trim().isEmpty;
  final terms = filter.textMatchCase
      ? filter.textTerms
      : [for (final term in filter.textTerms) term.toLowerCase()];
  return (entry) {
    final text = filter.textMatchCase ? entry.text : entry.text.toLowerCase();
    return filter.textJoin == TextTermJoin.all
        ? terms.every(text.contains)
        : terms.any(text.contains);
  };
}

List<Entry> _sortEntries(
  List<Entry> entries, {
  required OrderBy orderBy,
  required SortOrder sortOrder,
  required int? trackerTagId,
  required EntryTagsLookup tagsOf,
}) {
  final ascending = sortOrder == SortOrder.ascending;
  if (orderBy == OrderBy.tracker && trackerTagId != null) {
    return _sortByTracker(entries, trackerTagId, ascending, tagsOf);
  }
  var sorted =
      orderBy == OrderBy.mood ? _sortByMood(entries) : entries.toList();
  if (ascending) sorted = sorted.reversed.toList();
  return sorted;
}

List<Entry> _sortByMood(List<Entry> entries) {
  final positions = List<int>.generate(entries.length, (position) => position)
    ..sort((a, b) {
      final byMood = Mood.compare(entries[b].mood, entries[a].mood);
      return byMood != 0 ? byMood : a.compareTo(b);
    });
  return [for (final position in positions) entries[position]];
}

List<Entry> _sortByTracker(
  List<Entry> entries,
  int trackerTagId,
  bool ascending,
  EntryTagsLookup tagsOf,
) {
  double? trackerValue(Entry entry) {
    final rawValue = tagsOf(_idOf(entry))
        .where((entryTag) => entryTag.tagId == trackerTagId)
        .firstOrNull
        ?.value;
    return double.tryParse(rawValue ?? '');
  }

  final valuesByEntryId = {
    for (final entry in entries) entry.id: trackerValue(entry),
  };
  final withValue =
      entries.where((entry) => valuesByEntryId[entry.id] != null).toList();
  final withoutValue =
      entries.where((entry) => valuesByEntryId[entry.id] == null).toList();

  int byTimeCreate(Entry a, Entry b) => ascending
      ? a.timeCreate.compareTo(b.timeCreate)
      : b.timeCreate.compareTo(a.timeCreate);

  withValue.sort((a, b) {
    final comparison = ascending
        ? valuesByEntryId[a.id]!.compareTo(valuesByEntryId[b.id]!)
        : valuesByEntryId[b.id]!.compareTo(valuesByEntryId[a.id]!);
    return comparison != 0 ? comparison : byTimeCreate(a, b);
  });
  withoutValue.sort(byTimeCreate);

  return [...withValue, ...withoutValue];
}
