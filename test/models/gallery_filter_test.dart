// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/models/gallery_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GalleryFilter', () {
    test('the default filter restricts nothing', () {
      const filter = GalleryFilter();
      expect(filter.isActive, isFalse);
      expect(filter.hasMood, isFalse);
      expect(filter.hasTags, isFalse);
      expect(filter.hasDate, isFalse);
      expect(filter.hasAttachments, isFalse);
      expect(filter.hasText, isFalse);
      expect(filter.hasSearchText, isFalse);
    });

    test('each restriction makes the filter active on its own', () {
      expect(const GalleryFilter(moods: {3}).hasMood, isTrue);
      expect(const GalleryFilter(noMood: true).hasMood, isTrue);
      expect(const GalleryFilter(tagIds: {1}).hasTags, isTrue);
      expect(const GalleryFilter(noTags: true).hasTags, isTrue);
      expect(
          const GalleryFilter(date: LastMonthsSelection(3, isJalali: false))
              .hasDate,
          isTrue);
      expect(
        const GalleryFilter(attachmentTypes: {AttachmentType.audio})
            .hasAttachments,
        isTrue,
      );
      expect(const GalleryFilter(noAttachments: true).hasAttachments, isTrue);
      expect(const GalleryFilter(noText: true).hasText, isTrue);
      expect(const GalleryFilter(textTerms: ['sun']).hasText, isTrue);
      expect(const GalleryFilter(searchText: 'sun').hasSearchText, isTrue);
      expect(const GalleryFilter(searchText: 'sun').isActive, isTrue);
    });

    test('clearing one restriction leaves the others', () {
      const filter = GalleryFilter(
        moods: {1},
        noMood: true,
        tagIds: {2},
        tagMode: TagFilterMode.all,
        date: CalendarYearSelection(2025, isJalali: false),
        attachmentTypes: {AttachmentType.image},
        textTerms: ['sun'],
        textJoin: TextTermJoin.any,
        textMatchCase: true,
        searchText: 'beach',
      );

      final withoutMood = filter.withoutMood();
      expect(withoutMood.hasMood, isFalse);
      expect(withoutMood.hasTags, isTrue);

      final withoutTags = filter.withoutTags();
      expect(withoutTags.hasTags, isFalse);
      expect(withoutTags.tagMode, TagFilterMode.any);
      expect(withoutTags.hasMood, isTrue);

      expect(filter.withoutDate().hasDate, isFalse);
      expect(filter.withoutAttachments().hasAttachments, isFalse);

      final withoutText = filter.withoutText();
      expect(withoutText.hasText, isFalse);
      expect(withoutText.textJoin, TextTermJoin.all);
      expect(withoutText.textMatchCase, isFalse);

      final withoutSearch = filter.withoutSearchText();
      expect(withoutSearch.hasSearchText, isFalse);
      expect(withoutSearch.hasText, isTrue);
    });
  });
}
