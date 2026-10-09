// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/models/entry.dart';

class MarkdownIoHelper {
  /// Formats a single entry as a Markdown document with YAML frontmatter.
  static String formatEntryAsMarkdown(Entry entry) {
    final buffer = StringBuffer();
    buffer.writeln('---');
    buffer.writeln('date: ${entry.timeCreate.toIso8601String()}');
    if (entry.mood != null) {
      buffer.writeln('mood: ${entry.mood}');
    }
    buffer.writeln('---');
    buffer.writeln();
    buffer.write(entry.text);
    return buffer.toString();
  }

  /// Parses a Markdown document with optional YAML frontmatter into an [Entry].
  static Entry parseMarkdownEntry(String markdown, {DateTime? fallbackDate}) {
    DateTime date = fallbackDate ?? DateTime.now();
    int? mood;
    String body = markdown.trim();

    if (markdown.startsWith('---')) {
      final secondDivider = markdown.indexOf('---', 3);
      if (secondDivider != -1) {
        final frontmatter = markdown.substring(3, secondDivider);
        body = markdown.substring(secondDivider + 3).trim();
        final lines = frontmatter.split('\n');
        for (final line in lines) {
          final parts = line.split(':');
          if (parts.length >= 2) {
            final key = parts[0].trim().toLowerCase();
            final val = parts.sublist(1).join(':').trim();
            if (key == 'date') {
              final parsedDate = DateTime.tryParse(val);
              if (parsedDate != null) date = parsedDate;
            } else if (key == 'mood') {
              mood = int.tryParse(val);
            }
          }
        }
      }
    }

    return Entry(
      text: body,
      mood: mood,
      timeCreate: date,
      timeModified: DateTime.now(),
    );
  }
}
