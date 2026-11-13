// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:ui';

import 'package:daily_you/utils/search_matcher.dart';
import 'package:daily_you/utils/text_folding.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  SearchTiers tiers(List<String> texts, String query) =>
      tierByMatch([for (final text in texts) foldText(text)], query);

  bool matches(String text, String query) {
    final result = tiers([text], query);
    return result.exact.isNotEmpty || result.partial.isNotEmpty;
  }

  group('editBudget', () {
    test('allows no edits up to four characters', () {
      expect(editBudget('a'), 0);
      expect(editBudget('cafe'), 0);
    });

    test('allows one edit for five and six characters', () {
      expect(editBudget('beach'), 1);
      expect(editBudget('friend'), 1);
    });

    test('allows two edits from seven characters', () {
      expect(editBudget('receive'), 2);
      expect(editBudget('zeppelin'), 2);
    });

    test('counts wide characters double and caps edits per four characters',
        () {
      expect(editBudget('咖啡'), 0);
      expect(editBudget('公園散'), 0);
      expect(editBudget('公園散歩'), 1);
      expect(editBudget('公園に散歩公園に散歩'), 2);
    });

    test('allows no edits above thirty-two characters', () {
      expect(editBudget('a' * 32), 2);
      expect(editBudget('a' * 33), 0);
    });
  });

  group('tierByMatch typo tolerance', () {
    test('finds one-edit typos in five and six character words', () {
      expect(matches('a day at the beach', 'beech'), isTrue);
      expect(matches('my friend came', 'frend'), isTrue);
    });

    test('does not find two-edit typos in five and six character words', () {
      expect(matches('a day at the beach', 'bunch'), isFalse);
      expect(matches('my friend came', 'frnd'), isFalse);
    });

    test('finds up to two edits in words of seven or more characters', () {
      expect(matches('will receive it', 'recive'), isTrue);
      expect(matches('will receive it', 'recve'), isTrue);
      expect(matches('will receive it', 'reve'), isFalse);
      expect(matches('a zeppelin ride', 'zepelin'), isTrue);
    });

    test('does not tolerate typos in words of four characters or fewer', () {
      expect(matches('a cave tour', 'cafe'), isFalse);
      expect(matches('the cat', 'cot'), isFalse);
    });

    test('finds adjacent swaps', () {
      expect(matches('my friend came', 'freind'), isTrue);
      expect(matches('such a weird day', 'wierd'), isTrue);
      expect(matches('I will receive it', 'recieve'), isTrue);
    });

    test('does not tolerate a swap in a three character word', () {
      expect(matches('the cat', 'teh'), isFalse);
      expect(matches('teh cat', 'teh'), isTrue);
    });

    test('finds a match late in a long entry', () {
      final text = '${'lorem ipsum ' * 400}and a zeppelin appeared';
      expect(text.indexOf('zeppelin'), greaterThan(2000));
      expect(matches(text, 'zeppelin'), isTrue);
      expect(matches(text, 'zepelin'), isTrue);
      expect(matches(text, 'zepplein'), isTrue);
    });
  });

  group('tierByMatch words', () {
    test('requires every word', () {
      const text = 'we walked on the beach.\n\nlater the sunset was lovely';
      expect(matches(text, 'beach sunset'), isTrue);
      expect(matches(text, 'sunset beach'), isTrue);
      expect(matches(text, 'beach moon'), isFalse);
    });

    test('requires every word with typos', () {
      const text = 'we walked on the beach.\n\nlater the sunset was lovely';
      expect(matches(text, 'beech sunset'), isTrue);
      expect(matches(text, 'beech sunsat moon'), isFalse);
    });

    test('returns every position for a query without words', () {
      final result = tiers(['a', 'b', 'c'], ' ');
      expect(result.exact, [0, 1, 2]);
      expect(result.partial, isEmpty);
    });

    test('splits on any whitespace', () {
      expect(matches('beach\tsunset', 'beach\n sunset'), isTrue);
    });

    test('matches words longer than thirty-two characters exactly', () {
      final word = 'abcdefghij' * 4;
      expect(matches('before $word after', word), isTrue);
      expect(
          matches('before $word after', word.replaceFirst('e', 'x')), isFalse);
    });
  });

  group('tierByMatch accents', () {
    test('matches unaccented queries against accented text', () {
      expect(matches('We met at the Café.', 'cafe'), isTrue);
      expect(matches('A trip to Zürich', 'zurich'), isTrue);
    });

    test('matches accented queries against unaccented text', () {
      expect(matches('We met at the cafe.', 'café'), isTrue);
      expect(matches('A trip to zurich', 'ZÜRICH'), isTrue);
    });

    test('matches Vietnamese text typed without marks', () {
      expect(matches('Hôm nay ở Việt Nam', 'viet nam'), isTrue);
    });
  });

  group('tierByMatch without spaces', () {
    test('finds a fuzzy substring', () {
      expect(matches('昨日は公園に散歩しました', '公園散歩'), isTrue);
      expect(matches('昨日は公園に散歩しました', '公園に散步'), isTrue);
    });

    test('matches two character queries exactly', () {
      expect(matches('コーヒーと咖啡', '咖啡'), isTrue);
      expect(matches('コーヒーと咖非', '咖啡'), isFalse);
    });

    test('does not flood on an unrelated query', () {
      expect(matches('昨日は公園に散歩しました', '宇宙旅行'), isFalse);
    });
  });

  group('tierByMatch tiers', () {
    test('puts exact matches in the exact tier and typos in the partial tier',
        () {
      final texts = ['will recve it', 'will receive it', 'will recive it'];
      final result = tiers(texts, 'receive');
      expect(result.exact, [1]);
      expect(result.partial, [0, 2]);
    });

    test('keeps input order inside each tier', () {
      final texts = ['a recive', 'b receive', 'c recive', 'd receive'];
      final result = tiers(texts, 'receive');
      expect(result.exact, [1, 3]);
      expect(result.partial, [0, 2]);
    });

    test('needs every word exact for the exact tier', () {
      final texts = [
        'the beach and sunset',
        'the beach and sunsat',
        'the beech and sunsat',
      ];
      final result = tiers(texts, 'beach sunset');
      expect(result.exact, [0]);
      expect(result.partial, [1, 2]);
    });

    test('leaves out entries that do not match', () {
      final result = tiers(['nothing', 'beach', 'more nothing'], 'beach');
      expect(result.exact, [1]);
      expect(result.partial, isEmpty);
    });
  });

  group('findMatches', () {
    List<String> highlighted(String text, String query) => [
          for (final range in findMatches(text, query))
            text.substring(range.start, range.end),
        ];

    test('ignores case', () {
      expect(findMatches('Hello HELLO hello', 'HeLLo'), [
        const TextRange(start: 0, end: 5),
        const TextRange(start: 6, end: 11),
        const TextRange(start: 12, end: 17),
      ]);
    });

    test('ignores surrounding whitespace', () {
      expect(findMatches('a b', ' b '), [const TextRange(start: 2, end: 3)]);
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

    test('returns nothing for an empty or blank query', () {
      expect(findMatches('abc', ''), isEmpty);
      expect(findMatches('a b c', ' '), isEmpty);
    });

    test('keeps ranges aligned for İ and ß', () {
      expect(findMatches('İß x', 'x'), [const TextRange(start: 3, end: 4)]);
      expect(findMatches('ßß', 'ß'), [
        const TextRange(start: 0, end: 1),
        const TextRange(start: 1, end: 2),
      ]);
    });

    test('highlights each query word separately', () {
      expect(highlighted('The beach at sunset', 'sunset beach'),
          ['beach', 'sunset']);
    });

    test('merges overlapping ranges from different words', () {
      expect(findMatches('sunset', 'sun sunset'),
          [const TextRange(start: 0, end: 6)]);
    });

    test('highlights the whole word for a typo', () {
      expect(highlighted('I will receive it', 'recieve'), ['receive']);
      expect(highlighted('I will receive it', 'recive'), ['receive']);
      expect(highlighted('a zeppelin and zeppelins', 'zepelin'),
          ['zeppelin', 'zeppelins']);
    });

    test('highlights accented text for an unaccented query and back', () {
      expect(highlighted('at the Café and the cafe', 'cafe'), ['Café', 'cafe']);
      expect(highlighted('at the cafe', 'CAFÉ'), ['cafe']);
      expect(highlighted('Visit Zürich', 'zurich'), ['Zürich']);
    });

    test('highlights only exact occurrences when the word appears exactly', () {
      expect(highlighted('beach and beech', 'beach'), ['beach']);
    });

    test('highlights two typos in different words', () {
      expect(highlighted('the beach at sunset', 'beech sunsat'),
          ['beach', 'sunset']);
    });

    test('highlights a fuzzy wide-character match', () {
      expect(highlighted('昨日は公園に散歩しました', '公園に散步'), ['公園に散歩']);
    });

    test('returns nothing when no word matches', () {
      expect(findMatches('hello world', 'zzzzzz'), isEmpty);
    });
  });
}
