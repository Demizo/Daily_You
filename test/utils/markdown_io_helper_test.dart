// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/utils/markdown_io_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MarkdownIoHelper (F07)', () {
    test('formats entry as markdown with frontmatter', () {
      final date = DateTime(2026, 10, 9, 14, 30);
      final entry = Entry(
        id: 1,
        text: 'Went for a nice run today.',
        mood: 2,
        timeCreate: date,
        timeModified: date,
      );

      final md = MarkdownIoHelper.formatEntryAsMarkdown(entry);
      expect(md, contains('date: 2026-10-09T14:30:00.000'));
      expect(md, contains('mood: 2'));
      expect(md, contains('Went for a nice run today.'));
    });

    test('parses markdown with frontmatter into entry', () {
      const md = '''---
date: 2026-05-15T10:00:00.000
mood: 1
---

Enjoyed some tea this morning.''';

      final entry = MarkdownIoHelper.parseMarkdownEntry(md);
      expect(entry.timeCreate, DateTime(2026, 5, 15, 10, 0));
      expect(entry.mood, 1);
      expect(entry.text, 'Enjoyed some tea this morning.');
    });

    test('parses plain markdown without frontmatter', () {
      const md = 'Just a simple log entry with no header.';
      final fallbackDate = DateTime(2026, 1, 1);
      final entry = MarkdownIoHelper.parseMarkdownEntry(
        md,
        fallbackDate: fallbackDate,
      );

      expect(entry.text, 'Just a simple log entry with no header.');
      expect(entry.timeCreate, fallbackDate);
      expect(entry.mood, isNull);
    });

    test('round-trips entry formatting and parsing', () {
      final date = DateTime(2026, 3, 20, 8, 0);
      final original = Entry(
        text: 'Roundtrip test notes',
        mood: -1,
        timeCreate: date,
        timeModified: date,
      );

      final md = MarkdownIoHelper.formatEntryAsMarkdown(original);
      final parsed = MarkdownIoHelper.parseMarkdownEntry(md);

      expect(parsed.text, original.text);
      expect(parsed.mood, original.mood);
      expect(parsed.timeCreate, original.timeCreate);
    });
  });
}
