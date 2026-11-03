// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:ui';

import 'package:daily_you/utils/search_matcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('lowercasing', () {
    test('never changes string length for any code point', () {
      for (var codePoint = 0; codePoint <= 0x10FFFF; codePoint++) {
        if (codePoint >= 0xD800 && codePoint <= 0xDFFF) continue;
        final character = String.fromCharCode(codePoint);
        expect(
          character.toLowerCase().length,
          character.length,
          reason: 'U+${codePoint.toRadixString(16)}',
        );
      }
    });

    test('keeps ranges aligned for İ and ß', () {
      expect(findMatches('İß x', 'x'), [const TextRange(start: 3, end: 4)]);
      expect(findMatches('ßß', 'ß'), [
        const TextRange(start: 0, end: 1),
        const TextRange(start: 1, end: 2),
      ]);
    });
  });

  group('findMatches', () {
    test('ignores case', () {
      expect(findMatches('Hello HELLO hello', 'HeLLo'), [
        const TextRange(start: 0, end: 5),
        const TextRange(start: 6, end: 11),
        const TextRange(start: 12, end: 17),
      ]);
    });

    test('does not trim the query', () {
      expect(findMatches('a b', ' b'), [const TextRange(start: 1, end: 3)]);
      expect(findMatches('ab', ' b'), isEmpty);
    });

    test('matches a single space', () {
      expect(findMatches('a b c', ' '), [
        const TextRange(start: 1, end: 2),
        const TextRange(start: 3, end: 4),
      ]);
    });

    test('returns non-overlapping ranges for overlapping occurrences', () {
      expect(findMatches('aaaaa', 'aa'), [
        const TextRange(start: 0, end: 2),
        const TextRange(start: 2, end: 4),
      ]);
    });

    test('returns nothing when the query is longer than the text', () {
      expect(findMatches('ab', 'abc'), isEmpty);
    });

    test('returns nothing for an empty query', () {
      expect(findMatches('abc', ''), isEmpty);
    });
  });

  group('textMatchesQuery', () {
    test('is case-insensitive and untrimmed', () {
      expect(textMatchesQuery('Hello World', 'o w'), isTrue);
      expect(textMatchesQuery('Hello', 'hello '), isFalse);
    });

    test('agrees with findMatches', () {
      const texts = ['', 'abc', 'Hello  World', 'İß', 'aaa', ' '];
      const queries = ['a', 'A', 'aa', ' ', 'o w', 'ß', 'İ', 'abcd'];
      for (final text in texts) {
        for (final query in queries) {
          expect(
            textMatchesQuery(text, query),
            findMatches(text, query).isNotEmpty,
            reason: '"$text" / "$query"',
          );
        }
      }
    });
  });
}
