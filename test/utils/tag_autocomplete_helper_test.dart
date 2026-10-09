// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/utils/tag_autocomplete_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TagAutocompleteHelper (F02)', () {
    test('findTrigger detects @ and # triggers', () {
      final matchAt = TagAutocompleteHelper.findTrigger('Hello @wo', 9);
      expect(matchAt, isNotNull);
      expect(matchAt!.prefix, '@');
      expect(matchAt.query, 'wo');
      expect(matchAt.startIndex, 6);

      final matchHash = TagAutocompleteHelper.findTrigger('Coding #flutt', 13);
      expect(matchHash, isNotNull);
      expect(matchHash!.prefix, '#');
      expect(matchHash.query, 'flutt');
      expect(matchHash.startIndex, 7);
    });

    test('findTrigger returns null when not at trigger', () {
      expect(TagAutocompleteHelper.findTrigger('Hello world', 11), isNull);
      expect(TagAutocompleteHelper.findTrigger('@tag is done', 12), isNull);
      expect(TagAutocompleteHelper.findTrigger('', 0), isNull);
    });

    test('filterTags matches tags case-insensitively', () {
      final now = DateTime.now();
      final tags = [
        Tag(name: 'Work', tagType: TagType.label, timeCreate: now, timeModified: now),
        Tag(name: 'Workout', tagType: TagType.label, timeCreate: now, timeModified: now),
        Tag(name: 'Family', tagType: TagType.label, timeCreate: now, timeModified: now),
      ];

      final results = TagAutocompleteHelper.filterTags(tags, 'work');
      expect(results.length, 2);
      expect(results[0].name, 'Work');
      expect(results[1].name, 'Workout');
    });

    test('completeTag replaces trigger and positions cursor', () {
      const text = 'Met with @al in town';
      final trigger = TagAutocompleteHelper.findTrigger('Met with @al', 12)!;
      final result = TagAutocompleteHelper.completeTag(
        text: text,
        cursor: 12,
        trigger: trigger,
        tagName: 'Alice',
      );

      expect(result.newText, 'Met with @Alice  in town');
      expect(result.newCursor, 16);
    });
  });
}
