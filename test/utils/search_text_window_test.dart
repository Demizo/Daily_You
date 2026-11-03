// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/utils/search_text_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('searchTextWindow', () {
    test('returns the text when nothing matches', () {
      expect(searchTextWindow('first\nsecond', 'zzz'), 'first\nsecond');
    });

    test('returns the text when the match is on the first line', () {
      expect(searchTextWindow('first needle\nsecond', 'needle'),
          'first needle\nsecond');
    });

    test('starts at the line of a later match', () {
      expect(searchTextWindow('first\nsecond needle\nthird', 'needle'),
          'second needle\nthird');
    });

    test('starts at the line containing the first of several matches', () {
      expect(searchTextWindow('one\ntwo x\nthree x', 'x'), 'two x\nthree x');
    });

    test('starts at the opening fence for a match inside a code block', () {
      const text = 'intro\n```dart\nline\nneedle here\n```\nafter';
      expect(searchTextWindow(text, 'needle'),
          '```dart\nline\nneedle here\n```\nafter');
    });

    test('starts at the opening fence of an unclosed code block', () {
      const text = 'intro\n```\nline\nneedle';
      expect(searchTextWindow(text, 'needle'), '```\nline\nneedle');
    });

    test('keeps the match line when it is the opening fence', () {
      const text = 'intro\n```needle\ncode\n```';
      expect(searchTextWindow(text, 'needle'), '```needle\ncode\n```');
    });

    test('prefixes an ellipsis and cuts at whitespace for a far match', () {
      final text = '${'aaaa ' * 20}needle tail';
      expect(searchTextWindow(text, 'needle'), '…${'aaaa ' * 4}needle tail');
    });

    test('cuts a far match on a later line from that line', () {
      final text = 'intro\n${'aaaa ' * 20}needle';
      expect(searchTextWindow(text, 'needle'), '…${'aaaa ' * 4}needle');
    });

    test('keeps the line start when a far match has no whitespace before it',
        () {
      final text = 'intro\n${'a' * 60}needle';
      expect(searchTextWindow(text, 'needle'), '${'a' * 60}needle');
    });

    test('does not cut a code block for a far match inside it', () {
      final text = 'intro\n```\n${'aaaa ' * 20}\nneedle\n```';
      expect(searchTextWindow(text, 'needle'),
          '```\n${'aaaa ' * 20}\nneedle\n```');
    });

    test('keeps the list marker for a match in a list item', () {
      const text = 'intro\n- one\n- two needle\n- three';
      expect(searchTextWindow(text, 'needle'), '- two needle\n- three');
    });
  });
}
