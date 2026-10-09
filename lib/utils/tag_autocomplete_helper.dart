// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/models/tag.dart';

class TagTriggerMatch {
  final String prefix;
  final String query;
  final int startIndex;

  const TagTriggerMatch({
    required this.prefix,
    required this.query,
    required this.startIndex,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TagTriggerMatch &&
          prefix == other.prefix &&
          query == other.query &&
          startIndex == other.startIndex;

  @override
  int get hashCode => prefix.hashCode ^ query.hashCode ^ startIndex.hashCode;
}

class TagAutocompleteHelper {
  static final RegExp _triggerPattern =
      RegExp(r'([@#])([a-zA-Z0-9_\-\u00A0-\uFFFF]*)$');

  /// Detects whether the text before [cursor] ends with an active @ or # trigger.
  static TagTriggerMatch? findTrigger(String text, int cursor) {
    if (cursor <= 0 || cursor > text.length) return null;
    final beforeCursor = text.substring(0, cursor);
    final match = _triggerPattern.firstMatch(beforeCursor);
    if (match != null) {
      return TagTriggerMatch(
        prefix: match.group(1)!,
        query: match.group(2)!,
        startIndex: match.start,
      );
    }
    return null;
  }

  /// Filters [allTags] by [query] case-insensitively, limited to [limit].
  static List<Tag> filterTags(List<Tag> allTags, String query,
      {int limit = 5}) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      return allTags.take(limit).toList();
    }
    return allTags
        .where((t) => t.name.toLowerCase().contains(cleanQuery))
        .take(limit)
        .toList();
  }

  /// Replaces the typed trigger with the selected tag name followed by a space.
  static ({String newText, int newCursor}) completeTag({
    required String text,
    required int cursor,
    required TagTriggerMatch trigger,
    required String tagName,
  }) {
    final before = text.substring(0, trigger.startIndex);
    final after = text.substring(cursor);
    final replacement = '${trigger.prefix}$tagName ';
    final newText = '$before$replacement$after';
    final newCursor = before.length + replacement.length;
    return (newText: newText, newCursor: newCursor);
  }
}
