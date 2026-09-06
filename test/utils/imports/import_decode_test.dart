import 'dart:convert';
import 'dart:typed_data';

import 'package:daily_you/utils/imports/import_json.dart';
import 'package:daily_you/utils/imports/import_mybrain.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List jsonBytes(Object data) =>
    Uint8List.fromList(utf8.encode(json.encode(data)));

void main() {
  group('decodeJsonEntries', () {
    test('decodes text, mood and timestamps', () {
      final decoded = decodeJsonEntries(jsonBytes([
        {
          'text': 'a good day',
          'mood': 2,
          'timeCreated': '2026-01-02T03:04:05.000',
          'timeModified': '2026-01-03T03:04:05.000',
        }
      ]));

      expect(decoded, hasLength(1));
      expect(decoded.single.entry.text, equals('a good day'));
      expect(decoded.single.entry.mood, equals(2));
      expect(decoded.single.entry.timeCreate,
          equals(DateTime(2026, 1, 2, 3, 4, 5)));
      expect(decoded.single.entry.timeModified,
          equals(DateTime(2026, 1, 3, 3, 4, 5)));
      expect(decoded.single.images, isEmpty);
    });

    test('decodes a missing mood as null', () {
      final decoded = decodeJsonEntries(jsonBytes([
        {
          'text': '',
          'timeCreated': '2026-01-02T00:00:00.000',
          'timeModified': '2026-01-02T00:00:00.000',
        }
      ]));

      expect(decoded.single.entry.mood, isNull);
    });

    test('decodes the images list in file order', () {
      final decoded = decodeJsonEntries(jsonBytes([
        {
          'text': '',
          'timeCreated': '2026-01-02T00:00:00.000',
          'timeModified': '2026-01-02T00:00:00.000',
          'images': [
            {
              'imgPath': 'second.jpg',
              'imgRank': 1,
              'timeCreated': '2026-01-02T00:00:00.000'
            },
            {
              'imgPath': 'first.jpg',
              'imgRank': 0,
              'timeCreated': '2026-01-02T00:00:00.000'
            },
          ],
        }
      ]));

      expect(decoded.single.images.map((image) => image.imgPath),
          equals(['second.jpg', 'first.jpg']));
      expect(
          decoded.single.images.map((image) => image.imgRank), equals([1, 0]));
      expect(decoded.single.images.every((image) => image.entryId == null),
          isTrue);
    });

    test('decodes the deprecated imgPath field ahead of the images list', () {
      final decoded = decodeJsonEntries(jsonBytes([
        {
          'text': '',
          'timeCreated': '2026-01-02T00:00:00.000',
          'timeModified': '2026-01-02T00:00:00.000',
          'imgPath': 'legacy.jpg',
          'images': [
            {
              'imgPath': 'modern.jpg',
              'imgRank': 0,
              'timeCreated': '2026-01-02T00:00:00.000'
            },
          ],
        }
      ]));

      expect(decoded.single.images.map((image) => image.imgPath),
          equals(['legacy.jpg', 'modern.jpg']));
      expect(decoded.single.images.first.imgRank, equals(0));
    });
  });

  group('decodeMyBrainEntries', () {
    Uint8List diaryBytes(List<Object> entries) => jsonBytes({'diary': entries});

    test('maps mood names onto the mood scale', () {
      final decoded = decodeMyBrainEntries(diaryBytes([
        for (final mood in ['TERRIBLE', 'BAD', 'OKAY', 'GOOD', 'AWESOME'])
          {'mood': mood, 'createdDate': 0, 'updatedDate': 0}
      ]));

      expect(decoded.map((imported) => imported.entry.mood),
          equals([-2, -1, 0, 1, 2]));
    });

    test('decodes an unknown or missing mood as null', () {
      final decoded = decodeMyBrainEntries(diaryBytes([
        {'mood': 'ECSTATIC', 'createdDate': 0, 'updatedDate': 0},
        {'createdDate': 0, 'updatedDate': 0},
      ]));

      expect(
          decoded.map((imported) => imported.entry.mood), equals([null, null]));
    });

    test('joins the title and content into markdown', () {
      final decoded = decodeMyBrainEntries(diaryBytes([
        {
          'title': 'A title',
          'content': 'Some body',
          'createdDate': 0,
          'updatedDate': 0
        }
      ]));

      expect(decoded.single.entry.text, equals('# A title\n\nSome body'));
    });

    test('omits a missing title or content', () {
      final decoded = decodeMyBrainEntries(diaryBytes([
        {'content': 'Only body', 'createdDate': 0, 'updatedDate': 0},
        {'title': 'Only title', 'createdDate': 0, 'updatedDate': 0},
        {'createdDate': 0, 'updatedDate': 0},
      ]));

      expect(decoded.map((imported) => imported.entry.text),
          equals(['Only body', '# Only title', '']));
    });

    test('reads timestamps as local time', () {
      final decoded = decodeMyBrainEntries(diaryBytes([
        {'createdDate': 1767322800000, 'updatedDate': 1767409200000}
      ]));

      expect(
          decoded.single.entry.timeCreate,
          equals(DateTime.fromMillisecondsSinceEpoch(1767322800000, isUtc: true)
              .toLocal()));
      expect(decoded.single.entry.timeCreate.isUtc, isFalse);
      expect(
          decoded.single.entry.timeModified,
          equals(DateTime.fromMillisecondsSinceEpoch(1767409200000, isUtc: true)
              .toLocal()));
    });
  });
}
