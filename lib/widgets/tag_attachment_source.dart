import 'package:daily_you/models/tag.dart';
import 'package:daily_you/widgets/tracker_value_dialog.dart';
import 'package:flutter/widgets.dart';

/// In-memory working set of attached tags. Holds tag ids and (optionally) tracker values
class TagAttachmentSource extends ChangeNotifier {
  /// Whether tracker values are prompted for and stored
  final bool supportsValues;

  final List<int> _tagIds;
  final Map<int, String?> _values;

  TagAttachmentSource({
    this.supportsValues = false,
    List<int> initialTagIds = const [],
  })  : _tagIds = List.of(initialTagIds),
        _values = {};

  TagAttachmentSource.fromEntryTags(
    List<EntryTag> entryTags, {
    this.supportsValues = true,
  })  : _tagIds = entryTags.map((entryTag) => entryTag.tagId).toList(),
        _values = {
          for (final entryTag in entryTags) entryTag.tagId: entryTag.value
        };

  List<int> get attachedTagIds => List.unmodifiable(_tagIds);

  bool contains(int tagId) => _tagIds.contains(tagId);

  /// Tracker value for [tagId], or null when unset or unsupported.
  String? valueFor(int tagId) => supportsValues ? _values[tagId] : null;

  /// Snapshots the working set as [EntryTag]s for [entryId], ready to persist.
  List<EntryTag> toEntryTags(int entryId) => [
        for (final tagId in _tagIds)
          EntryTag(
            entryId: entryId,
            tagId: tagId,
            value: supportsValues ? _values[tagId] : null,
            timeCreate: DateTime.now(),
          )
      ];

  /// Stages [tagId] directly without a value prompt
  void addTagId(int tagId) {
    if (_tagIds.contains(tagId)) return;
    _tagIds.add(tagId);
    notifyListeners();
  }

  /// Attaches [tag]. When [supportsValues] and the tag is a tracker, prompts for
  /// a value; a cancelled prompt leaves the tag unattached.
  Future<void> attach(BuildContext context, Tag tag) async {
    if (_tagIds.contains(tag.id!)) return;
    String? value;
    if (supportsValues && tag.tagType == TagType.tracker) {
      value = await showTrackerValueDialog(context, tag);
      if (value == null) return;
    }
    _tagIds.add(tag.id!);
    if (value != null) _values[tag.id!] = value;
    notifyListeners();
  }

  /// Edits the tracker value of an already-attached [tag].
  Future<void> editValue(BuildContext context, Tag tag) async {
    if (!supportsValues) return;
    final value = await showTrackerValueDialog(context, tag,
        initialValue: _values[tag.id!]);
    if (value == null) return;
    _values[tag.id!] = value;
    notifyListeners();
  }

  /// Removes the tag with [tagId].
  Future<void> detach(int tagId) async {
    _tagIds.remove(tagId);
    _values.remove(tagId);
    notifyListeners();
  }
}
