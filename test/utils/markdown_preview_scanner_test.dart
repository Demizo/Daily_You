import 'package:daily_you/utils/markdown_preview_scanner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<MarkdownSpan> spansOf(String text) => scanMarkdown(text).spans;

  MarkdownSpan marker(int start, int end, MarkdownConstruct construct,
          [int headerLevel = 0]) =>
      MarkdownSpan(
        start: start,
        end: end,
        construct: construct,
        role: MarkdownSpanRole.marker,
        headerLevel: headerLevel,
      );

  MarkdownSpan content(int start, int end, MarkdownConstruct construct,
          [int headerLevel = 0]) =>
      MarkdownSpan(
        start: start,
        end: end,
        construct: construct,
        role: MarkdownSpanRole.content,
        headerLevel: headerLevel,
      );

  group('inline constructs', () {
    test('bold with asterisks', () {
      expect(spansOf('**loud**'), [
        marker(0, 2, MarkdownConstruct.bold),
        content(2, 6, MarkdownConstruct.bold),
        marker(6, 8, MarkdownConstruct.bold),
      ]);
    });

    test('bold with underscores', () {
      expect(spansOf('__loud__'), [
        marker(0, 2, MarkdownConstruct.bold),
        content(2, 6, MarkdownConstruct.bold),
        marker(6, 8, MarkdownConstruct.bold),
      ]);
    });

    test('italic', () {
      expect(spansOf('*soft*'), [
        marker(0, 1, MarkdownConstruct.italic),
        content(1, 5, MarkdownConstruct.italic),
        marker(5, 6, MarkdownConstruct.italic),
      ]);
    });

    test('strikethrough', () {
      expect(spansOf('~~gone~~'), [
        marker(0, 2, MarkdownConstruct.strikethrough),
        content(2, 6, MarkdownConstruct.strikethrough),
        marker(6, 8, MarkdownConstruct.strikethrough),
      ]);
    });

    test('a triple run keeps every asterisk in the marker', () {
      expect(spansOf('***both***'), [
        marker(0, 3, MarkdownConstruct.bold),
        content(3, 7, MarkdownConstruct.bold),
        marker(7, 10, MarkdownConstruct.bold),
      ]);
    });

    test('inline code', () {
      expect(spansOf('`x`'), [
        marker(0, 1, MarkdownConstruct.inlineCode),
        content(1, 2, MarkdownConstruct.inlineCode),
        marker(2, 3, MarkdownConstruct.inlineCode),
      ]);
    });

    test('link splits brackets, label and target', () {
      expect(spansOf('[home](https://a.b)'), [
        marker(0, 1, MarkdownConstruct.link),
        content(1, 5, MarkdownConstruct.link),
        marker(5, 19, MarkdownConstruct.link),
      ]);
    });

    test('markup inside inline code is left alone', () {
      expect(spansOf('`**x**`'), [
        marker(0, 1, MarkdownConstruct.inlineCode),
        content(1, 6, MarkdownConstruct.inlineCode),
        marker(6, 7, MarkdownConstruct.inlineCode),
      ]);
    });
  });

  group('block constructs', () {
    test('header keeps its level', () {
      expect(spansOf('### Title'), [
        marker(0, 3, MarkdownConstruct.header, 3),
        content(4, 9, MarkdownConstruct.header, 3),
      ]);
    });

    test('every header level is recognized', () {
      for (var level = 1; level <= 6; level++) {
        final hashes = '#' * level;
        expect(spansOf('$hashes T'), [
          marker(0, level, MarkdownConstruct.header, level),
          content(level + 1, level + 2, MarkdownConstruct.header, level),
        ]);
      }
    });

    test('seven hashes are not a header', () {
      expect(spansOf('####### T'), isEmpty);
    });

    test('bullet list marks only the bullet', () {
      expect(spansOf('- milk'), [
        marker(0, 1, MarkdownConstruct.bulletList),
      ]);
    });

    test('numbered list marks only the number', () {
      expect(spansOf('1. milk'), [
        marker(0, 2, MarkdownConstruct.numberedList),
      ]);
    });

    test('blockquote marks the arrow and the quoted text', () {
      expect(spansOf('> quoted'), [
        marker(0, 1, MarkdownConstruct.blockquote),
        content(2, 8, MarkdownConstruct.blockquote),
      ]);
    });

    test('fenced code block covers the fences and the lines between', () {
      expect(spansOf('```\nx\n```'), [
        marker(0, 3, MarkdownConstruct.codeBlock),
        content(4, 5, MarkdownConstruct.codeBlock),
        marker(6, 9, MarkdownConstruct.codeBlock),
      ]);
    });

    test('fenced code block styles its language tag as content', () {
      expect(spansOf('```dart\n```'), [
        marker(0, 3, MarkdownConstruct.codeBlock),
        content(3, 7, MarkdownConstruct.codeBlock),
        marker(8, 11, MarkdownConstruct.codeBlock),
      ]);
    });

    test('markup inside a fenced code block is left alone', () {
      expect(spansOf('```\n# not a header\n```'), [
        marker(0, 3, MarkdownConstruct.codeBlock),
        content(4, 18, MarkdownConstruct.codeBlock),
        marker(19, 22, MarkdownConstruct.codeBlock),
      ]);
    });

    test('an unterminated fence still styles the rest as code', () {
      expect(spansOf('```\nx'), [
        marker(0, 3, MarkdownConstruct.codeBlock),
        content(4, 5, MarkdownConstruct.codeBlock),
      ]);
    });
  });

  group('blocks to paint behind', () {
    List<MarkdownBlock> blocksOf(String text) => scanMarkdown(text).blocks;

    test('plain text has none', () {
      expect(blocksOf('Woke up late.\n- milk'), isEmpty);
    });

    test('a fenced block runs fence to fence', () {
      expect(blocksOf('```\nx\n```'), [
        const MarkdownBlock(
            start: 0, end: 9, markerEnd: 0, kind: MarkdownBlockKind.codeBlock),
      ]);
    });

    test('an unterminated fence runs to the end of the text', () {
      expect(blocksOf('a\n```\nx'), [
        const MarkdownBlock(
            start: 2, end: 7, markerEnd: 2, kind: MarkdownBlockKind.codeBlock),
      ]);
    });

    test('two fenced blocks stay separate', () {
      final blocks = blocksOf('```\na\n```\n\n```\nb\n```');

      expect(blocks, hasLength(2));
      expect(blocks.first.end, 9);
      expect(blocks.last.start, 11);
    });

    test('stacked quote lines become one block', () {
      expect(blocksOf('> one\n> two'), [
        const MarkdownBlock(
            start: 0,
            end: 11,
            markerEnd: 1,
            kind: MarkdownBlockKind.blockquote),
      ]);
    });

    test('a gap splits quotes into separate blocks', () {
      final blocks = blocksOf('> one\n\n> two');

      expect(blocks, hasLength(2));
      expect(blocks.first.end, 5);
      expect(blocks.last.start, 7);
    });

    test('a quote block ends where the quoting stops', () {
      expect(blocksOf('> one\nplain'), [
        const MarkdownBlock(
            start: 0, end: 5, markerEnd: 1, kind: MarkdownBlockKind.blockquote),
      ]);
    });

    test('a nested quote marker is measured whole', () {
      expect(blocksOf('>> deep'), [
        const MarkdownBlock(
            start: 0, end: 7, markerEnd: 2, kind: MarkdownBlockKind.blockquote),
      ]);
    });
  });

  group('combinations', () {
    test('bold inside a list item', () {
      expect(spansOf('- **milk**'), [
        marker(0, 1, MarkdownConstruct.bulletList),
        marker(2, 4, MarkdownConstruct.bold),
        content(4, 8, MarkdownConstruct.bold),
        marker(8, 10, MarkdownConstruct.bold),
      ]);
    });

    test('link inside a blockquote', () {
      expect(spansOf('> [a](b)'), [
        marker(0, 1, MarkdownConstruct.blockquote),
        content(2, 8, MarkdownConstruct.blockquote),
        marker(2, 3, MarkdownConstruct.link),
        content(3, 4, MarkdownConstruct.link),
        marker(4, 8, MarkdownConstruct.link),
      ]);
    });

    test('header inside a blockquote', () {
      expect(spansOf('> # T'), [
        marker(0, 1, MarkdownConstruct.blockquote),
        content(2, 5, MarkdownConstruct.blockquote),
        marker(2, 3, MarkdownConstruct.header, 1),
        content(4, 5, MarkdownConstruct.header, 1),
      ]);
    });

    test('italic nested inside bold', () {
      expect(spansOf('**a *b* c**'), [
        marker(0, 2, MarkdownConstruct.bold),
        content(2, 9, MarkdownConstruct.bold),
        marker(4, 5, MarkdownConstruct.italic),
        content(5, 6, MarkdownConstruct.italic),
        marker(6, 7, MarkdownConstruct.italic),
        marker(9, 11, MarkdownConstruct.bold),
      ]);
    });

    test('spans are ordered outermost first', () {
      final spans = spansOf('# **T**');
      expect(spans.map((span) => span.start).toList(), [0, 2, 2, 4, 5]);
      expect(spans[1].construct, MarkdownConstruct.header);
      expect(spans[2].construct, MarkdownConstruct.bold);
    });
  });

  group('input that must not be styled', () {
    test('underscores inside a word', () {
      expect(spansOf('snake_case_name'), isEmpty);
    });

    test('unterminated bold', () {
      expect(spansOf('**loud'), isEmpty);
    });

    test('emphasis markers around whitespace', () {
      expect(spansOf('a * b * c'), isEmpty);
    });

    test('a run of asterisks in prose', () {
      expect(spansOf('a **** b'), isEmpty);
    });

    test('a bracket without a target', () {
      expect(spansOf('[label] text'), isEmpty);
    });

    test('a hash without a space', () {
      expect(spansOf('#hashtag'), isEmpty);
    });

    test('tables stay completely plain', () {
      expect(spansOf('| **a** | b |\n| --- | --- |\n| 1 | 2 |'), isEmpty);
    });

    test('a lone pipe line is not a table', () {
      expect(spansOf('a | b\nc **d**'), [
        marker(8, 10, MarkdownConstruct.bold),
        content(10, 11, MarkdownConstruct.bold),
        marker(11, 13, MarkdownConstruct.bold),
      ]);
    });
  });

  group('horizontal rules', () {
    test('dashes are marked but carry no content', () {
      expect(spansOf('---'), [
        marker(0, 3, MarkdownConstruct.horizontalRule),
      ]);
    });

    test('asterisk and underscore rules are recognized', () {
      expect(spansOf('***'), [marker(0, 3, MarkdownConstruct.horizontalRule)]);
      expect(spansOf('___'), [marker(0, 3, MarkdownConstruct.horizontalRule)]);
    });

    test('trailing whitespace is not part of the marker', () {
      expect(spansOf('---  '), [
        marker(0, 3, MarkdownConstruct.horizontalRule),
      ]);
    });
  });

  group('graceful degradation', () {
    test('empty text produces no spans', () {
      expect(spansOf(''), isEmpty);
    });

    test('plain prose produces no spans', () {
      expect(spansOf('Woke up late. Coffee helped.'), isEmpty);
    });

    test('garbage input never throws and stays in bounds', () {
      const garbage = '*`~~[](#>_ \n]]**__``` >>> ###### -*-*-\n|--|\n\n[[[';
      final spans = spansOf(garbage);
      for (final span in spans) {
        expect(span.start, greaterThanOrEqualTo(0));
        expect(span.end, greaterThan(span.start));
        expect(span.end, lessThanOrEqualTo(garbage.length));
      }
    });
  });
}
