// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as m;
import 'package:daily_you/markdown/markdown_parser.dart';
import 'package:markdown_widget/markdown_widget.dart';

void main() {
  final splitRegExp = WidgetVisitor.defaultSplitRegExp;

  String reference(String data) {
    final document = m.Document(
      extensionSet: m.ExtensionSet.gitHubFlavored,
      encodeHtml: false,
    );
    return m.renderToHtml(document.parseLines(data.split(splitRegExp)));
  }

  String parsed(String data) => m.renderToHtml(
        MarkdownParser(splitRegExp: splitRegExp).parse(data),
      );

  test('parses exactly like the stock document', () {
    const samples = [
      'plain words only',
      'It\'s a day, isn\'t it? Yes - 3 of them (maybe).',
      'two\nlines of plain text',
      'trailing space  \nhard break',
      '**bold** and _italic_ and ~~gone~~',
      'a `code` span and a [link](https://example.com)',
      'https://example.com and www.example.com and me@example.com',
      'Smile :smile: here, and a colon: only one',
      'Escaped \\* star and &amp; entity and <b>tag</b>',
      '![alt](image.png) inline image',
      '# Heading\n\ntext\n\n- one\n- two\n\n1. first\n2. second',
      '- [ ] open task\n- [x] done task',
      '> quote\n\n```\ncode block\n```\n\n| a | b |\n|---|---|\n| 1 | 2 |',
    ];

    for (final sample in samples) {
      expect(parsed(sample), reference(sample), reason: sample);
    }
  });

  test('returns the cached document for repeated text', () {
    final parser = MarkdownParser(splitRegExp: splitRegExp);

    expect(identical(parser.parse('cached text'), parser.parse('cached text')),
        isTrue);
  });

  test('does not reuse a document parsed with different syntaxes', () {
    final plain = MarkdownParser(splitRegExp: splitRegExp);
    final custom = MarkdownParser(
      splitRegExp: splitRegExp,
      inlineSyntaxes: [m.StrikethroughSyntax()],
    );

    expect(identical(plain.parse('same text'), custom.parse('same text')),
        isFalse);
  });
}
