// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/entry_sort.dart';
import 'package:daily_you/models/gallery_filter.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/utils/gallery_filtering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 11, 8, 15, 30);

  Entry entry(
    int id,
    DateTime timeCreate, {
    String text = '',
    int? mood,
  }) =>
      Entry(
        id: id,
        text: text,
        mood: mood,
        timeCreate: timeCreate,
        timeModified: timeCreate,
      );

  EntryTag entryTag(int entryId, int tagId, {String? value}) => EntryTag(
        entryId: entryId,
        tagId: tagId,
        value: value,
        timeCreate: DateTime(2026),
      );

  List<int> run(
    List<Entry> entries,
    GalleryFilter filter, {
    Map<int, List<EntryTag>> tags = const {},
    Map<int, Set<AttachmentType>> attachments = const {},
    OrderBy orderBy = OrderBy.date,
    SortOrder sortOrder = SortOrder.descending,
    int? trackerTagId,
    DateTime? now,
  }) =>
      [
        for (final result in filterAndSortEntries(
          entries: entries,
          filter: filter,
          tagsOf: (entryId) => tags[entryId] ?? const [],
          attachmentTypesOf: (entryId) => attachments[entryId] ?? const {},
          orderBy: orderBy,
          sortOrder: sortOrder,
          trackerTagId: trackerTagId,
          today: now ?? today,
        ))
          result.id!,
      ];

  final byDay = [
    entry(1, DateTime(2026, 11, 8, 9), mood: 5, text: 'Sunny Beach day'),
    entry(2, DateTime(2026, 11, 7, 9), mood: 3, text: 'beach and rain'),
    entry(3, DateTime(2026, 11, 6, 9), text: 'Quiet'),
    entry(4, DateTime(2026, 11, 5, 9), mood: 1, text: 'Rain'),
    entry(5, DateTime(2026, 11, 4, 9), mood: 5, text: 'Beach'),
  ];

  group('defaults', () {
    test('an empty filter returns every entry in the chosen order', () {
      expect(run(byDay, const GalleryFilter()), [1, 2, 3, 4, 5]);
      expect(
        run(byDay, const GalleryFilter(), sortOrder: SortOrder.ascending),
        [5, 4, 3, 2, 1],
      );
    });

    test('an empty list stays empty', () {
      expect(run(const [], const GalleryFilter(moods: {3})), isEmpty);
    });
  });

  group('mood', () {
    test('keeps entries with any selected mood', () {
      expect(run(byDay, const GalleryFilter(moods: {5})), [1, 5]);
      expect(run(byDay, const GalleryFilter(moods: {1, 3})), [2, 4]);
    });

    test('leaves out entries without a mood unless No mood is selected', () {
      expect(run(byDay, const GalleryFilter(moods: {5})), isNot(contains(3)));
      expect(run(byDay, const GalleryFilter(noMood: true)), [3]);
      expect(run(byDay, const GalleryFilter(moods: {1}, noMood: true)), [3, 4]);
    });
  });

  group('tags', () {
    final tags = {
      1: [entryTag(1, 10), entryTag(1, 20)],
      2: [entryTag(2, 10)],
      4: [entryTag(4, 20)],
    };

    test('any keeps entries with at least one selected tag', () {
      expect(run(byDay, const GalleryFilter(tagIds: {10, 20}), tags: tags),
          [1, 2, 4]);
    });

    test('all keeps entries with every selected tag', () {
      expect(
        run(
          byDay,
          const GalleryFilter(tagIds: {10, 20}, tagMode: TagFilterMode.all),
          tags: tags,
        ),
        [1],
      );
    });

    test('No tags keeps entries without any tag', () {
      expect(run(byDay, const GalleryFilter(noTags: true), tags: tags), [3, 5]);
    });
  });

  group('date', () {
    final entries = [
      entry(1, DateTime(2026, 11, 8, 23, 59)),
      entry(2, DateTime(2026, 11, 9)),
      entry(3, DateTime(2026, 10, 8)),
      entry(4, DateTime(2026, 10, 7, 23, 59)),
    ];

    test('keeps entries inside the selected day range', () {
      expect(
        run(
          entries,
          const GalleryFilter(date: LastMonthsSelection(1, isJalali: false)),
        ),
        [1, 3],
      );
    });
  });

  group('attachments', () {
    final attachments = {
      1: {AttachmentType.image},
      2: {AttachmentType.audio},
      3: {AttachmentType.image, AttachmentType.video},
    };

    test('keeps entries with any selected type', () {
      expect(
        run(
          byDay,
          const GalleryFilter(attachmentTypes: {AttachmentType.image}),
          attachments: attachments,
        ),
        [1, 3],
      );
      expect(
        run(
          byDay,
          const GalleryFilter(
            attachmentTypes: {AttachmentType.audio, AttachmentType.video},
          ),
          attachments: attachments,
        ),
        [2, 3],
      );
    });

    test('No attachments keeps entries without any', () {
      expect(
        run(
          byDay,
          const GalleryFilter(noAttachments: true),
          attachments: attachments,
        ),
        [4, 5],
      );
    });
  });

  group('text', () {
    test('no text keeps only blank entries', () {
      final entries = [
        entry(1, DateTime(2026, 11, 8), text: 'sun'),
        entry(2, DateTime(2026, 11, 7)),
        entry(3, DateTime(2026, 11, 6), text: '  \n'),
      ];
      expect(run(entries, const GalleryFilter(noText: true)), [2, 3]);
    });

    test('and requires every term', () {
      expect(
        run(byDay, const GalleryFilter(textTerms: ['beach', 'rain'])),
        [2],
      );
    });

    test('or accepts any term', () {
      expect(
        run(
          byDay,
          const GalleryFilter(
            textTerms: ['quiet', 'rain'],
            textJoin: TextTermJoin.any,
          ),
        ),
        [2, 3, 4],
      );
    });

    test('ignores case by default', () {
      expect(run(byDay, const GalleryFilter(textTerms: ['BEACH'])), [1, 2, 5]);
    });

    test('matches exact case when asked', () {
      expect(
        run(
          byDay,
          const GalleryFilter(textTerms: ['Beach'], textMatchCase: true),
        ),
        [1, 5],
      );
    });

    test('is a plain substring match', () {
      expect(run(byDay, const GalleryFilter(textTerms: ['eac'])), [1, 2, 5]);
    });

    test('no terms restricts nothing', () {
      expect(
        run(byDay, const GalleryFilter(textTerms: [], textMatchCase: true)),
        [1, 2, 3, 4, 5],
      );
    });
  });

  group('combined filters', () {
    test('narrow with and across filters', () {
      final tags = {
        1: [entryTag(1, 10)],
        5: [entryTag(5, 10)],
        4: [entryTag(4, 10)],
      };
      const filter = GalleryFilter(
        moods: {5},
        tagIds: {10},
        textTerms: ['beach'],
        date: LastMonthsSelection(1, isJalali: false),
      );
      expect(run(byDay, filter, tags: tags), [1, 5]);
      expect(
        run(byDay, filter.copyWith(moods: {1}), tags: tags),
        isEmpty,
      );
    });

    test('ignores the search text, which is tiered elsewhere', () {
      expect(
        run(byDay, const GalleryFilter(searchText: 'zeppelin')),
        [1, 2, 3, 4, 5],
      );
    });
  });

  group('sort', () {
    test('mood sorts best first and keeps the date order between ties', () {
      expect(
        run(byDay, const GalleryFilter(), orderBy: OrderBy.mood),
        [1, 5, 2, 4, 3],
      );
    });

    test('ascending mood reverses the whole order', () {
      expect(
        run(
          byDay,
          const GalleryFilter(),
          orderBy: OrderBy.mood,
          sortOrder: SortOrder.ascending,
        ),
        [3, 4, 2, 5, 1],
      );
    });

    test('tracker sorts by value with valueless entries last', () {
      final tags = {
        1: [entryTag(1, 7, value: '2')],
        2: [entryTag(2, 7, value: '9')],
        4: [entryTag(4, 7, value: '2')],
        5: [entryTag(5, 7, value: 'many')],
      };
      expect(
        run(
          byDay,
          const GalleryFilter(),
          tags: tags,
          orderBy: OrderBy.tracker,
          trackerTagId: 7,
        ),
        [2, 1, 4, 3, 5],
      );
      expect(
        run(
          byDay,
          const GalleryFilter(),
          tags: tags,
          orderBy: OrderBy.tracker,
          sortOrder: SortOrder.ascending,
          trackerTagId: 7,
        ),
        [4, 1, 2, 5, 3],
      );
    });

    test('tracker sort without a chosen tag falls back to date', () {
      expect(
        run(byDay, const GalleryFilter(), orderBy: OrderBy.tracker),
        [1, 2, 3, 4, 5],
      );
    });

    test('sorting applies after filtering', () {
      expect(
        run(
          byDay,
          const GalleryFilter(moods: {5, 1}),
          orderBy: OrderBy.mood,
          sortOrder: SortOrder.ascending,
        ),
        [4, 5, 1],
      );
    });
  });
}
