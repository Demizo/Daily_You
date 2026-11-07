// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/utils/markdown_formatting.dart';
import 'package:daily_you/utils/markdown_preview_scanner.dart';
import 'package:daily_you/widgets/markdown_preview_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

TextEditingController controllerFor(String text, int start, [int? end]) {
  final controller = TextEditingController(text: text);
  controller.selection =
      TextSelection(baseOffset: start, extentOffset: end ?? start);
  addTearDown(controller.dispose);
  return controller;
}

void main() {
  const inlineCases = {
    MarkdownConstruct.bold: '**',
    MarkdownConstruct.italic: '_',
    MarkdownConstruct.highlight: '==',
    MarkdownConstruct.strikethrough: '~~',
  };

  for (final MapEntry(key: construct, value: marker) in inlineCases.entries) {
    group(construct.name, () {
      final formatted = 'a $marker' 'word$marker b';
      final contentStart = 2 + marker.length;
      final contentEnd = contentStart + 4;
      final groupEnd = contentEnd + marker.length;

      test('is active with the cursor inside the content', () {
        final controller = controllerFor(formatted, contentStart + 2);
        expect(isMarkdownActive(controller, construct), isTrue);
      });

      test('is active with the cursor at either end of the content', () {
        expect(
            isMarkdownActive(controllerFor(formatted, contentStart), construct),
            isTrue);
        expect(
            isMarkdownActive(controllerFor(formatted, contentEnd), construct),
            isTrue);
      });

      test('is active at the end boundary but not before the opening marker',
          () {
        expect(isMarkdownActive(controllerFor(formatted, groupEnd), construct),
            isTrue);
        expect(
            isMarkdownActive(controllerFor(formatted, 2), construct), isFalse);
      });

      test('is inactive outside the construct', () {
        expect(
            isMarkdownActive(controllerFor(formatted, 0), construct), isFalse);
        expect(
            isMarkdownActive(
                controllerFor(formatted, formatted.length), construct),
            isFalse);
      });

      test('is active for a selection within the construct', () {
        final controller =
            controllerFor(formatted, contentStart + 1, contentEnd);
        expect(isMarkdownActive(controller, construct), isTrue);
      });

      test('is inactive for a selection that leaves the construct', () {
        final controller = controllerFor(formatted, 0, contentStart + 2);
        expect(isMarkdownActive(controller, construct), isFalse);
      });

      test('removing keeps the text and shifts the cursor', () {
        final controller = controllerFor(formatted, contentStart + 2);
        expect(removeMarkdown(controller, construct), isTrue);
        expect(controller.text, 'a word b');
        expect(controller.selection, const TextSelection.collapsed(offset: 4));
      });

      test('removing shifts a selection past the closing marker', () {
        final controller =
            controllerFor(formatted, contentStart, formatted.length);
        controller.selection =
            TextSelection(baseOffset: contentStart + 1, extentOffset: groupEnd);
        removeMarkdown(controller, construct);
        expect(controller.selection,
            const TextSelection(baseOffset: 3, extentOffset: 6));
      });

      test('removing does nothing when inactive', () {
        final controller = controllerFor(formatted, 0);
        expect(removeMarkdown(controller, construct), isFalse);
        expect(controller.text, formatted);
      });

      test('toggling wraps then unwraps a selection', () {
        final controller = controllerFor('word', 0, 4);
        toggleMarkdown(controller, construct);
        expect(controller.text, '${marker}word$marker');
        expect(isMarkdownActive(controller, construct), isTrue);
        toggleMarkdown(controller, construct);
        expect(controller.text, 'word');
        expect(controller.selection, const TextSelection.collapsed(offset: 4));
      });

      test('an empty pair around the cursor is active and removed', () {
        final controller =
            controllerFor('a $marker$marker b', 2 + marker.length);
        expect(isMarkdownActive(controller, construct), isTrue);
        toggleMarkdown(controller, construct);
        expect(controller.text, 'a  b');
        expect(controller.selection, const TextSelection.collapsed(offset: 2));
      });

      test('toggling in entirely empty text round trips', () {
        final controller = TextEditingController();
        addTearDown(controller.dispose);
        expect(isMarkdownActive(controller, construct), isFalse);
        toggleMarkdown(controller, construct);
        expect(controller.text, '$marker$marker');
        expect(controller.selection,
            TextSelection.collapsed(offset: marker.length));
        expect(isMarkdownActive(controller, construct), isTrue);
        toggleMarkdown(controller, construct);
        expect(controller.text, '');
        expect(controller.selection, const TextSelection.collapsed(offset: 0));
        expect(isMarkdownActive(controller, construct), isFalse);
      });

      test('a cursor beside an unpaired marker is inactive', () {
        final controller = controllerFor('a $marker b', 2 + marker.length);
        expect(isMarkdownActive(controller, construct), isFalse);
      });
    });
  }

  group('bold and italic', () {
    test('only the construct under the cursor is active', () {
      final controller = controllerFor('**bold** and _soft_', 4);
      expect(isMarkdownActive(controller, MarkdownConstruct.bold), isTrue);
      expect(isMarkdownActive(controller, MarkdownConstruct.italic), isFalse);
    });

    test('nested formatting reports both and removes one', () {
      final controller = controllerFor('**a _b_ c**', 6);
      expect(isMarkdownActive(controller, MarkdownConstruct.bold), isTrue);
      expect(isMarkdownActive(controller, MarkdownConstruct.italic), isTrue);
      removeMarkdown(controller, MarkdownConstruct.italic);
      expect(controller.text, '**a b c**');
      expect(isMarkdownActive(controller, MarkdownConstruct.bold), isTrue);
    });

    test('star italics are recognised', () {
      final controller = controllerFor('*lean*', 3);
      expect(isMarkdownActive(controller, MarkdownConstruct.italic), isTrue);
      removeMarkdown(controller, MarkdownConstruct.italic);
      expect(controller.text, 'lean');
    });
  });

  group('link', () {
    test('removing keeps the label and drops the destination', () {
      final controller = controllerFor('see [docs](https://a.b/c) now', 7);
      expect(isMarkdownActive(controller, MarkdownConstruct.link), isTrue);
      removeMarkdown(controller, MarkdownConstruct.link);
      expect(controller.text, 'see docs now');
      expect(controller.selection, const TextSelection.collapsed(offset: 6));
    });

    test('a cursor inside the destination counts as inside', () {
      final controller = controllerFor('[docs](https://a.b)', 10);
      expect(isMarkdownActive(controller, MarkdownConstruct.link), isTrue);
    });

    test('toggling in empty text round trips', () {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      toggleMarkdown(controller, MarkdownConstruct.link);
      expect(controller.text, '[]()');
      expect(isMarkdownActive(controller, MarkdownConstruct.link), isTrue);
      toggleMarkdown(controller, MarkdownConstruct.link);
      expect(controller.text, '');
    });

    test('is inactive outside', () {
      final controller = controllerFor('x [docs](https://a.b) y', 0);
      expect(isMarkdownActive(controller, MarkdownConstruct.link), isFalse);
    });
  });

  group('line constructs', () {
    test('bullet is active anywhere on its line', () {
      expect(
          isMarkdownActive(
              controllerFor('- one\ntwo', 0), MarkdownConstruct.bulletList),
          isTrue);
      expect(
          isMarkdownActive(
              controllerFor('- one\ntwo', 5), MarkdownConstruct.bulletList),
          isTrue);
      expect(
          isMarkdownActive(
              controllerFor('- one\ntwo', 6), MarkdownConstruct.bulletList),
          isFalse);
    });

    test('removing a bullet drops the marker and its space', () {
      final controller = controllerFor('- one\n- two', 9);
      removeMarkdown(controller, MarkdownConstruct.bulletList);
      expect(controller.text, '- one\ntwo');
      expect(controller.selection, const TextSelection.collapsed(offset: 7));
    });

    test('removing from the marker position collapses to the line start', () {
      final controller = controllerFor('- one', 1);
      removeMarkdown(controller, MarkdownConstruct.bulletList);
      expect(controller.text, 'one');
      expect(controller.selection, const TextSelection.collapsed(offset: 0));
    });

    test('toggling a bullet on then off round trips', () {
      final controller = controllerFor('one', 3);
      toggleMarkdown(controller, MarkdownConstruct.bulletList);
      expect(controller.text, '- one');
      toggleMarkdown(controller, MarkdownConstruct.bulletList);
      expect(controller.text, 'one');
      expect(controller.selection, const TextSelection.collapsed(offset: 3));
    });

    test('toggling a bullet in empty text round trips', () {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      toggleMarkdown(controller, MarkdownConstruct.bulletList);
      expect(controller.text, '- ');
      expect(
          isMarkdownActive(controller, MarkdownConstruct.bulletList), isTrue);
      toggleMarkdown(controller, MarkdownConstruct.bulletList);
      expect(controller.text, '');
    });

    test('quote toggles', () {
      final controller = controllerFor('> said', 4);
      expect(
          isMarkdownActive(controller, MarkdownConstruct.blockquote), isTrue);
      toggleMarkdown(controller, MarkdownConstruct.blockquote);
      expect(controller.text, 'said');
      toggleMarkdown(controller, MarkdownConstruct.blockquote);
      expect(controller.text, '> said');
    });

    test('quote and bullet are independent', () {
      final controller = controllerFor('> - item', 6);
      expect(
          isMarkdownActive(controller, MarkdownConstruct.blockquote), isTrue);
      expect(
          isMarkdownActive(controller, MarkdownConstruct.bulletList), isTrue);
      removeMarkdown(controller, MarkdownConstruct.bulletList);
      expect(controller.text, '> item');
    });

    test('header is active at any level and removed', () {
      for (final level in [1, 3, 6]) {
        final hashes = '#' * level;
        final controller = controllerFor('$hashes title\nbody', 5);
        expect(isMarkdownActive(controller, MarkdownConstruct.header), isTrue);
        removeMarkdown(controller, MarkdownConstruct.header);
        expect(controller.text, 'title\nbody');
      }
    });

    test('header is inactive on a plain line', () {
      final controller = controllerFor('# title\nbody', 10);
      expect(isMarkdownActive(controller, MarkdownConstruct.header), isFalse);
      expect(removeMarkdown(controller, MarkdownConstruct.header), isFalse);
    });
  });

  test('a MarkdownPreviewController is read through its cached scan', () {
    final controller = MarkdownPreviewController(text: '**bold**');
    addTearDown(controller.dispose);
    controller.selection = const TextSelection.collapsed(offset: 4);
    expect(isMarkdownActive(controller, MarkdownConstruct.bold), isTrue);
    controller.text = 'plain';
    controller.selection = const TextSelection.collapsed(offset: 2);
    expect(isMarkdownActive(controller, MarkdownConstruct.bold), isFalse);
  });
}
