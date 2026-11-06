// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math' as math;

import 'package:daily_you/utils/word_counter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_count/word_count.dart';

void expectParity(String text) {
  expect(
    countWords(text),
    wordsCount(text),
    reason:
        'text: ${text.runes.map((rune) => rune.toRadixString(16)).toList()}',
  );
}

void main() {
  group('matches the word_count package', () {
    final corpus = <String>[
      '',
      ' ',
      '   \t\n\r\n  ',
      '　',
      '　   ﻿  ',
      'Hello',
      'Hello world',
      '  leading and trailing  ',
      'Hello, world! How are you? Fine; thanks: really.',
      "don't can't it's 'quoted' \"double\"",
      'multi-word well-known state-of-the-art -- - ---',
      'a+b = c_d | e`f ~ g',
      '+ = _ | `',
      'version 2.0.1 costs \$5.99 (approx) 100% #1 @home',
      'path/to\\file & more * stars ^ caret',
      'tab\tseparated\tvalues',
      'line one\nline two\r\nline three\rline four',
      'form\u000Cfeed and vertical\u000Btab',
      'control\u0001chars\u0000inside \u001F end',
      'Café naïve façade résumé Ünïcödé Straße',
      'Ça va très bien, merci × ÷',
      'Привет, мир! Как дела? Хорошо-хорошо.',
      'مرحبا بالعالم كيف حالك',
      'שלום עולם מה שלומך',
      'สวัสดีชาวโลก สบายดีไหม',
      'नमस्ते दुनिया आप कैसे हैं',
      'Ελληνικά κείμενο και Հայերեն տեքստ ქართული ტექსტი',
      '你好世界',
      '你好，世界！今天天气很好。',
      'こんにちは世界 カタカナ ひらがな',
      '안녕하세요 세계 한글',
      'Hello 世界 mixed こんにちは with 한글 text',
      'abc你好def',
      '【标题】《书名》「引用」、顿号',
      '，。：；！？（）［］｛｝～￥',
      'full-width ＡＢＣ １２３ ＋ － ａｂｃ',
      'a，b a＋b a．b',
      'wave 👋 hands 🙌 emoji 😀😀 end',
      'surrogate pair 𝒜𝓑𝓒 and 𠀀𠀁 ideographs',
      '\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467} family',
      'zero​width​space',
      'soft­hyphen nbsp here',
      'em—dash en–dash ellipsis… quotes “x” ‘y’',
      'tibetan་tsheg ethiopic፡space ኢትዮጵያ',
      '﻿bom prefix',
      'ends with ideograph 字',
      '字 starts with ideograph',
      '1 2 3 4 5 6 7 8 9 0',
      'ǅ ʃ ẞ ỹ',
      '̀combining á',
    ];

    for (final (index, text) in corpus.indexed) {
      test('corpus sample $index', () => expectParity(text));
    }

    test('every code unit alone and between letters and spaces', () {
      for (var unit = 0; unit <= 0xFFFF; unit++) {
        final character = String.fromCharCode(unit);
        expectParity(character);
        expectParity('a${character}b');
        expectParity('a $character b');
        expectParity('$character$character');
        expectParity('é$character\u00E9');
      }
    });

    test('seeded random strings from a mixed pool', () {
      final pool = <String>[
        ...'abcXYZ019 \t\n\r.,;:-\'"!?()[]/\\&%@#^*~\$<>{}+=_|`'.split(''),
        ...['é', 'ü', 'ß', 'Ж', 'я', 'ع', 'ب', 'ש', 'ל', 'ก', 'ข', 'न', 'म'],
        ...['你', '好', 'あ', 'ア', '한', '글', '。', '，', '、', '【', '】'],
        ...['＋', 'Ａ', '１', '！', '～', '￥', '​', ' ', '　'],
        ...['—', '’', '“', '፡', '་', '﻿'],
        ...[' ', '\u0085', ' ', '😀', '👋', '𠀀', '\u{1D49C}'],
      ];
      final random = math.Random(20260611);
      for (var iteration = 0; iteration < 5000; iteration++) {
        final length = random.nextInt(60);
        final buffer = StringBuffer();
        for (var index = 0; index < length; index++) {
          buffer.write(pool[random.nextInt(pool.length)]);
        }
        expectParity(buffer.toString());
      }
    });

    test('seeded random ascii strings', () {
      final random = math.Random(7);
      for (var iteration = 0; iteration < 3000; iteration++) {
        final length = random.nextInt(80);
        final units = List<int>.generate(length, (_) => random.nextInt(128));
        expectParity(String.fromCharCodes(units));
      }
    });
  });
}
