import 'package:daily_you/models/tag.dart';
import 'package:daily_you/widgets/entry_draft_dirty_tracker.dart';
import 'package:daily_you/widgets/tag_attachment_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final date = DateTime(2025, 6, 2, 9, 30);

  EntryDraftDirtyTracker tracker({Set<int> seededTagIds = const {}}) =>
      EntryDraftDirtyTracker(
        text: 'draft',
        mood: null,
        date: date,
        seededTagIds: seededTagIds,
      );

  test('has no field changes until a field diverges from the last save', () {
    final draft = tracker();

    expect(
        draft.hasFieldChanges(text: 'draft', mood: null, date: date), isFalse);
    expect(
        draft.hasFieldChanges(text: 'edited', mood: null, date: date), isTrue);
    expect(draft.hasFieldChanges(text: 'draft', mood: 1, date: date), isTrue);
    expect(
        draft.hasFieldChanges(
            text: 'draft', mood: null, date: date.add(const Duration(days: 1))),
        isTrue);
  });

  test('markSaved resets the comparison point', () {
    final draft = tracker();

    draft.markSaved(text: 'edited', mood: 2, date: date);

    expect(draft.hasFieldChanges(text: 'edited', mood: 2, date: date), isFalse);
    expect(
        draft.hasFieldChanges(text: 'draft', mood: null, date: date), isTrue);
  });

  test('a new entry with only seeded tags has no unsaved changes', () {
    final draft = tracker(seededTagIds: {1, 2});
    final tagSource = TagAttachmentSource(initialTagIds: [1, 2]);
    addTearDown(tagSource.dispose);

    expect(
        draft.hasUnsavedChanges(
          text: 'draft',
          mood: null,
          date: date,
          tagSource: tagSource,
          hasImages: false,
        ),
        isFalse);
  });

  test('attaching a tag beyond the seed counts as an unsaved change', () {
    final draft = tracker(seededTagIds: {1});
    final tagSource = TagAttachmentSource(initialTagIds: [1, 2]);
    addTearDown(tagSource.dispose);

    expect(
        draft.hasUnsavedChanges(
          text: 'draft',
          mood: null,
          date: date,
          tagSource: tagSource,
          hasImages: false,
        ),
        isTrue);
  });

  test('a seeded tracker tag that already carries a value counts as unsaved',
      () {
    final draft = tracker(seededTagIds: {1});
    final tagSource = TagAttachmentSource.fromEntryTags([
      EntryTag(entryId: 1, tagId: 1, value: '3', timeCreate: date),
    ]);
    addTearDown(tagSource.dispose);

    expect(
        draft.hasUnsavedChanges(
          text: 'draft',
          mood: null,
          date: date,
          tagSource: tagSource,
          hasImages: false,
        ),
        isTrue);
  });

  test('a pending image counts as an unsaved change', () {
    final draft = tracker();
    final tagSource = TagAttachmentSource();
    addTearDown(tagSource.dispose);

    expect(
        draft.hasUnsavedChanges(
          text: 'draft',
          mood: null,
          date: date,
          tagSource: tagSource,
          hasImages: true,
        ),
        isTrue);
  });
}
