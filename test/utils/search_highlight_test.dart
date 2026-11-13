// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/utils/color_utils.dart';
import 'package:daily_you/utils/search_highlight.dart';
import 'package:daily_you/utils/search_matcher.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  const background = Colors.yellow;

  List<TextSpan> leaves(InlineSpan span) {
    final result = <TextSpan>[];
    span.visitChildren((child) {
      if (child is TextSpan && child.text != null) result.add(child);
      return true;
    });
    return result;
  }

  bool isHighlighted(TextSpan span) =>
      span.style?.backgroundColor == background &&
      span.style?.color == contrastingTextColor(background);

  List<String> highlightedLeafTexts(InlineSpan span) =>
      leaves(span).where(isHighlighted).map((leaf) => leaf.text!).toList();

  InlineSpan highlightQuery(InlineSpan span, String query) => highlightSpan(
        span,
        findMatches(span.toPlainText(includeSemanticsLabels: false), query),
        background,
      );

  group('highlightSpan', () {
    test('highlights a single match', () {
      const span = TextSpan(text: 'hello world');
      final result = highlightQuery(span, 'world');

      expect(leaves(result).map((leaf) => leaf.text), ['hello ', 'world']);
      expect(highlightedLeafTexts(result), ['world']);
    });

    test('highlights a match inside bold and keeps the bold', () {
      const span = TextSpan(children: [
        TextSpan(text: 'a '),
        TextSpan(
          text: 'bold word',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ]);
      final result = highlightQuery(span, 'word');

      final highlighted =
          leaves(result).singleWhere((leaf) => isHighlighted(leaf));
      expect(highlighted.text, 'word');
      expect(highlighted.style?.fontWeight, FontWeight.bold);
    });

    test('highlights a match spanning bold and plain text', () {
      const span = TextSpan(children: [
        TextSpan(text: 'hel'),
        TextSpan(
          text: 'lo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        TextSpan(text: ' there'),
      ]);
      final result = highlightQuery(span, 'hello');

      expect(highlightedLeafTexts(result), ['hel', 'lo']);
      final bold = leaves(result).singleWhere((leaf) => leaf.text == 'lo');
      expect(bold.style?.fontWeight, FontWeight.bold);
    });

    test('keeps the recognizer and mouse cursor of a matched link', () {
      final recognizer = TapGestureRecognizer();
      addTearDown(recognizer.dispose);
      final span = TextSpan(children: [
        const TextSpan(text: 'see '),
        TextSpan(
          text: 'the link here',
          style: const TextStyle(color: Colors.blue),
          recognizer: recognizer,
          mouseCursor: SystemMouseCursors.click,
        ),
      ]);
      final result = highlightQuery(span, 'link');

      final pieces =
          leaves(result).where((leaf) => leaf.recognizer != null).toList();
      expect(pieces.map((leaf) => leaf.text), ['the ', 'link', ' here']);
      for (final piece in pieces) {
        expect(piece.recognizer, same(recognizer));
        expect(piece.mouseCursor, SystemMouseCursors.click);
      }
    });

    test('counts a widget span as one unit', () {
      final widgetSpan = WidgetSpan(child: const SizedBox());
      final span = TextSpan(children: [
        const TextSpan(text: 'ab'),
        widgetSpan,
        const TextSpan(text: 'cd'),
      ]);
      final result = highlightQuery(span, 'cd');

      expect(highlightedLeafTexts(result), ['cd']);
      var foundWidgetSpan = false;
      result.visitChildren((child) {
        if (identical(child, widgetSpan)) foundWidgetSpan = true;
        return true;
      });
      expect(foundWidgetSpan, isTrue);
      expect(result.toPlainText(), span.toPlainText());
    });

    test('ignores semantics labels when locating matches', () {
      const span = TextSpan(children: [
        TextSpan(text: 'ab', semanticsLabel: 'a much longer label'),
        TextSpan(text: 'cd'),
      ]);
      final result = highlightQuery(span, 'cd');

      expect(highlightedLeafTexts(result), ['cd']);
    });

    test('keeps text before children when splitting', () {
      const span = TextSpan(
        text: 'ab',
        children: [TextSpan(text: 'cd')],
      );
      final result = highlightQuery(span, 'bc');

      expect(leaves(result).map((leaf) => leaf.text), ['a', 'b', 'c', 'd']);
      expect(highlightedLeafTexts(result), ['b', 'c']);
    });

    test('returns the same span when nothing matches', () {
      const span = TextSpan(text: 'hello');
      expect(identical(highlightQuery(span, 'zzz'), span), isTrue);
    });

    test('highlights the given ranges', () {
      const span = TextSpan(text: 'hello world');
      final result = highlightSpan(
        span,
        const [TextRange(start: 1, end: 3), TextRange(start: 6, end: 8)],
        background,
      );

      expect(leaves(result).map((leaf) => leaf.text),
          ['h', 'el', 'lo ', 'wo', 'rld']);
      expect(highlightedLeafTexts(result), ['el', 'wo']);
    });

    test('leaves the plain text unchanged', () {
      const span = TextSpan(text: 'one ', children: [
        TextSpan(text: 'two', style: TextStyle(fontStyle: FontStyle.italic)),
        TextSpan(text: ' three two'),
      ]);
      final result = highlightQuery(span, 'two');

      expect(result.toPlainText(), span.toPlainText());
    });
  });
}
