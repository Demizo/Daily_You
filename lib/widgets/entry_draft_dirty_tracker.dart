import 'package:daily_you/widgets/tag_attachment_source.dart';

/// Tracks saved vs current entry fields and attachments
class EntryDraftDirtyTracker {
  EntryDraftDirtyTracker({
    required String text,
    required int? mood,
    required DateTime date,
    required Set<int> seededTagIds,
  })  : _lastText = text,
        _lastMood = mood,
        _lastDate = date,
        _seededTagIds = seededTagIds;

  String _lastText;
  int? _lastMood;
  DateTime _lastDate;

  /// Tag ids seeded from the default template, or already on the entry
  final Set<int> _seededTagIds;

  void markSaved({
    required String text,
    required int? mood,
    required DateTime date,
  }) {
    _lastText = text;
    _lastMood = mood;
    _lastDate = date;
  }

  bool hasFieldChanges({
    required String text,
    required int? mood,
    required DateTime date,
  }) {
    return text != _lastText || mood != _lastMood || date != _lastDate;
  }

  bool hasUnsavedChanges({
    required String text,
    required int? mood,
    required DateTime date,
    required TagAttachmentSource tagSource,
    required bool hasImages,
  }) {
    return hasFieldChanges(text: text, mood: mood, date: date) ||
        _tagsExceedSeed(tagSource) ||
        hasImages;
  }

  bool _tagsExceedSeed(TagAttachmentSource tagSource) {
    for (final tagId in tagSource.attachedTagIds) {
      if (!_seededTagIds.contains(tagId)) return true;
      if (tagSource.valueFor(tagId) != null) return true;
    }
    return false;
  }
}
