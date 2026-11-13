// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/utils/text_folding.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('foldText', () {
    test('lowercases', () {
      expect(foldText('Hello WORLD'), 'hello world');
    });

    test('removes Latin-1 and Latin Extended-A accents', () {
      expect(foldText('Café'), 'cafe');
      expect(foldText('Zürich'), 'zurich');
      expect(foldText('Łódź'), 'lodz');
      expect(foldText('Århus Øst'), 'arhus ost');
      expect(foldText('ÇĞİŞ'), 'cgis');
    });

    test('removes Vietnamese stacked marks', () {
      expect(foldText('Việt Nam'), 'viet nam');
      expect(foldText('Hà Nội'), 'ha noi');
      expect(foldText('Ngô Đình Diệm'), 'ngo dinh diem');
      expect(foldText('ướt ổ ếch'), 'uot o ech');
    });

    test('leaves characters that would change length untouched', () {
      expect(foldText('Straße'), 'straße');
      expect(foldText('Æsop œuvre'), 'æsop œuvre');
    });

    test('does not transliterate other scripts', () {
      expect(foldText('Жизнь'), 'жизнь');
      expect(foldText('Ελλάδα'), 'ελλάδα');
      expect(foldText('公園に散歩'), '公園に散歩');
    });

    test('keeps combining marks in place', () {
      const decomposed = 'café';
      expect(foldText(decomposed), decomposed);
    });

    test('preserves string length for every mapped character', () {
      expect(latinAccentedCharacters.length, latinBaseCharacters.length);
      for (var index = 0; index < latinAccentedCharacters.length; index++) {
        final accented = latinAccentedCharacters[index];
        final base = latinBaseCharacters[index];
        expect(accented.length, 1, reason: accented);
        expect(base, matches(RegExp(r'^[a-z]$')), reason: accented);
        expect(foldText(accented), base, reason: accented);
        expect(foldText(accented.toUpperCase()).length,
            accented.toUpperCase().length,
            reason: accented);
      }
    });
  });
}
