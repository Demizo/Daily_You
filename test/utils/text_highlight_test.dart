// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/gallery_filter.dart';
import 'package:daily_you/utils/text_highlight.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<String> matched(String text, TextHighlight highlight) => [
        for (final range in highlight.findRanges(text))
          text.substring(range.start, range.end),
      ];

  group('TextHighlight', () {
    test('is empty without a query or terms', () {
      expect(TextHighlight.none.isEmpty, isTrue);
      expect(TextHighlight.none.findRanges('anything'), isEmpty);
    });

    test('is built from the filter', () {
      final highlight = TextHighlight.fromFilter(
        const GalleryFilter(
          searchText: 'beach',
          textTerms: ['sun'],
          textMatchCase: true,
        ),
      );

      expect(highlight.query, 'beach');
      expect(highlight.terms, ['sun']);
      expect(highlight.matchCase, isTrue);
      expect(highlight.isNotEmpty, isTrue);
    });

    test('ignores filters without search text or keywords', () {
      expect(
        TextHighlight.fromFilter(const GalleryFilter(noText: true)).isEmpty,
        isTrue,
      );
    });

    test('highlights every occurrence of a keyword', () {
      const highlight = TextHighlight(terms: ['sun']);

      expect(matched('sun and Sun and sunset', highlight), [
        'sun',
        'Sun',
        'sun',
      ]);
    });

    test('respects match case for keywords', () {
      const highlight = TextHighlight(terms: ['Sun'], matchCase: true);

      expect(matched('sun and Sun', highlight), ['Sun']);
    });

    test('matches keywords literally', () {
      const highlight = TextHighlight(terms: ['a.b', '(x)']);

      expect(matched('a.b axb (x)', highlight), ['a.b', '(x)']);
    });

    test('merges overlapping keyword and search matches', () {
      const highlight = TextHighlight(query: 'sunset', terms: ['set b']);

      expect(matched('sunset beach', highlight), ['sunset b']);
    });

    test('combines search and keyword matches', () {
      const highlight = TextHighlight(query: 'beach', terms: ['sun']);

      expect(matched('sun on the beach', highlight), ['sun', 'beach']);
    });

    test('skips empty keywords', () {
      const highlight = TextHighlight(terms: ['']);

      expect(highlight.findRanges('text'), isEmpty);
    });
  });
}
