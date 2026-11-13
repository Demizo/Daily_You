// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math';

import 'package:daily_you/utils/bitap_pattern.dart';
import 'package:flutter_test/flutter_test.dart';

int referenceErrors(String text, String pattern) {
  final rows = pattern.length;
  final columns = text.length;
  final table = List.generate(rows + 1, (_) => List.filled(columns + 1, 0));
  for (var row = 1; row <= rows; row++) {
    table[row][0] = row;
  }
  for (var row = 1; row <= rows; row++) {
    for (var column = 1; column <= columns; column++) {
      final substitution = table[row - 1][column - 1] +
          (pattern[row - 1] == text[column - 1] ? 0 : 1);
      var best = min(
        substitution,
        min(table[row - 1][column] + 1, table[row][column - 1] + 1),
      );
      if (row > 1 &&
          column > 1 &&
          pattern[row - 1] == text[column - 2] &&
          pattern[row - 2] == text[column - 1]) {
        best = min(best, table[row - 2][column - 2] + 1);
      }
      table[row][column] = best;
    }
  }
  return table[rows].reduce(min);
}

void main() {
  int errors(String text, String pattern, int maxErrors) =>
      BitapPattern(pattern, maxErrors).errorsIn(text);

  group('BitapPattern', () {
    test('finds an exact substring with zero errors', () {
      expect(errors('a friend of mine', 'friend', 2), 0);
    });

    test('counts one insertion, deletion or substitution', () {
      expect(errors('a friend', 'frend', 2), 1);
      expect(errors('a friend', 'frieend', 2), 1);
      expect(errors('a friend', 'fraend', 2), 1);
    });

    test('counts an adjacent transposition as one error', () {
      expect(errors('my friend', 'freind', 1), 1);
      expect(errors('a weird day', 'wierd', 1), 1);
      expect(errors('to receive it', 'recieve', 1), 1);
      expect(errors('the cat', 'teh', 1), 1);
    });

    test('reports no match as one more than the budget', () {
      expect(errors('zzzz', 'friend', 2), 3);
      expect(errors('my friend', 'freind', 0), 1);
    });

    test('stops early once the requested error count is reached', () {
      final pattern = BitapPattern('friend', 2);
      expect(pattern.errorsIn('freind and frend', stopAtErrors: 1), 1);
    });

    test('reports every match end with its error count', () {
      final ends = <(int, int)>[];
      BitapPattern('cat', 1)
          .forEachMatchEnd('cat cut', (end, errors) => ends.add((end, errors)));
      expect(ends, contains((2, 0)));
      expect(ends, contains((6, 1)));
    });

    test('matches non-Latin pattern characters', () {
      expect(errors('公園に散歩', '公園散歩', 1), 1);
      expect(errors('公園に散歩', '公園に散步', 1), 1);
    });

    test('agrees with a brute-force reference on random strings', () {
      final random = Random(20260101);
      const alphabet = 'abcd';
      String randomString(int maximumLength) => String.fromCharCodes([
            for (var index = 0;
                index < random.nextInt(maximumLength + 1);
                index++)
              alphabet.codeUnitAt(random.nextInt(alphabet.length)),
          ]);

      for (var trial = 0; trial < 8000; trial++) {
        final pattern = randomString(8);
        if (pattern.isEmpty) continue;
        final text = randomString(20);
        final maxErrors = 1 + random.nextInt(2);
        if (pattern.length <= maxErrors) continue;
        final expected = min(referenceErrors(text, pattern), maxErrors + 1);
        expect(
          errors(text, pattern, maxErrors),
          expected,
          reason: 'text "$text" pattern "$pattern" budget $maxErrors',
        );
      }
    });
  });
}
