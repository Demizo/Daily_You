import 'package:daily_you/models/image.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EntryImage.appendRanked', () {
    test('assigns descending ranks so newest share sorts first', () {
      final result =
          EntryImage.appendRanked(const [], ['a.jpg', 'b.jpg'], entryId: 1);

      expect(result.map((e) => e.imgPath), ['a.jpg', 'b.jpg']);
      expect(result.map((e) => e.imgRank), [1, 0]);
    });

    test('shifts existing images up without mutating the input list', () {
      final existing = [
        EntryImage(
            id: 1,
            entryId: 1,
            imgPath: 'existing.jpg',
            imgRank: 0,
            timeCreate: DateTime(2025)),
      ];

      final result = EntryImage.appendRanked(existing, ['new.jpg'], entryId: 1);

      expect(existing.single.imgRank, 0);
      expect(result.map((e) => e.imgPath), ['existing.jpg', 'new.jpg']);
      expect(result.map((e) => e.imgRank), [1, 0]);
    });

    test('returns a copy of the input when there is nothing to add', () {
      final existing = [
        EntryImage(
            entryId: 1,
            imgPath: 'existing.jpg',
            imgRank: 0,
            timeCreate: DateTime(2025)),
      ];

      final result = EntryImage.appendRanked(existing, const [], entryId: 1);

      expect(result, isNot(same(existing)));
      expect(result.map((e) => e.imgPath), ['existing.jpg']);
    });
  });
}
