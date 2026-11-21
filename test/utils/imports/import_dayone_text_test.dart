// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/utils/imports/import_dayone_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('dayOneText', () {
    test('keeps plain markdown as it is', () {
      const text = '# Title\nSome **bold** and `code`\n> quote';

      expect(dayOneText(text), text);
    });

    test('drops a media reference that sits on its own line', () {
      expect(dayOneText('![](dayone-moment://AB12)\n\n# Title\nBody\n'),
          '# Title\nBody');
      expect(dayOneText('Before\n\n![](dayone-moment://AB12)\n\nAfter'),
          'Before\n\nAfter');
    });

    test('drops every kind of media reference', () {
      expect(
          dayOneText('![](dayone-moment://A)\n![](dayone-moment:/video/B)\n'
              '![](dayone-moment:/audio/C)\n[](dayone-moment:/pdfAttachment/D)\n'
              'Text'),
          'Text');
    });

    test('drops a media reference inside a sentence', () {
      expect(dayOneText('Look ![](dayone-moment://A) here'), 'Look  here');
    });

    test('keeps links that are not media references', () {
      const text =
          '[site](https://example.com) and ![alt](https://example.com/a.png)';

      expect(dayOneText(text), text);
    });

    test(
        'removes escapes that only guard against markdown in the middle of a line',
        () {
      expect(dayOneText(r'Hello\! A well\-known \(rule\) costs 3\.50, ok\?'),
          'Hello! A well-known (rule) costs 3.50, ok?');
    });

    test('keeps escapes that stop inline markup', () {
      const text = r'\*not bold\* \_not italic\_ \[not a link\] \\ \`tick\`';

      expect(dayOneText(text), text);
    });

    test('keeps escapes that stop block markup at the start of a line', () {
      const text =
          '\\# not a heading\n\\- not a list\n1\\. not a list\n\\> not a quote';

      expect(dayOneText(text), text);
    });

    test('keeps block escapes behind a quote marker', () {
      const text = '> \\# not a heading';

      expect(dayOneText(text), text);
    });

    test('removes block escapes away from the start of a line', () {
      expect(dayOneText(r'Issue \#4 is a \- b \+ c'), 'Issue #4 is a - b + c');
    });

    test('leaves code spans and fenced code untouched', () {
      const text = 'Run `a\\.b\\!` now\n\n```\nprint\\(1\\)\n```\n';

      expect(dayOneText(text), text.trim());
    });
  });
}
