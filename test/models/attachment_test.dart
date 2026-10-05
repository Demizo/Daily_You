// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/attachment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only audio has no visual preview', () {
    expect({
      for (final type in AttachmentType.values) type: type.isVisual
    }, {
      AttachmentType.image: true,
      AttachmentType.video: true,
      AttachmentType.audio: false,
    });
  });

  group('EntryAttachment.appendRanked', () {
    test('assigns descending ranks so newest share sorts first', () {
      final result = EntryAttachment.appendRanked(
        const [],
        [
          NewAttachment(type: AttachmentType.image, filePath: 'a.jpg'),
          NewAttachment(type: AttachmentType.image, filePath: 'b.jpg'),
        ],
        entryId: 1,
      );

      expect(result.map((e) => e.filePath), ['a.jpg', 'b.jpg']);
      expect(result.map((e) => e.rank), [1, 0]);
    });

    test('shifts existing attachments up without mutating the input list', () {
      final existing = [
        EntryAttachment(
            id: 1,
            entryId: 1,
            type: AttachmentType.image,
            filePath: 'existing.jpg',
            rank: 0,
            timeCreate: DateTime(2025)),
      ];

      final result = EntryAttachment.appendRanked(
        existing,
        [NewAttachment(type: AttachmentType.image, filePath: 'new.jpg')],
        entryId: 1,
      );

      expect(existing.single.rank, 0);
      expect(result.map((e) => e.filePath), ['existing.jpg', 'new.jpg']);
      expect(result.map((e) => e.rank), [1, 0]);
    });

    test('returns a copy of the input when there is nothing to add', () {
      final existing = [
        EntryAttachment(
            entryId: 1,
            type: AttachmentType.image,
            filePath: 'existing.jpg',
            rank: 0,
            timeCreate: DateTime(2025)),
      ];

      final result =
          EntryAttachment.appendRanked(existing, const [], entryId: 1);

      expect(result, isNot(same(existing)));
      expect(result.map((e) => e.filePath), ['existing.jpg']);
    });
  });

  group('AttachmentType', () {
    test('tryFromValue finds a known type and rejects an unknown one', () {
      expect(AttachmentType.tryFromValue('video'), AttachmentType.video);
      expect(AttachmentType.tryFromValue('hologram'), isNull);
      expect(AttachmentType.tryFromValue(null), isNull);
    });

    test('fromValue throws a FormatException for an unknown type', () {
      expect(() => AttachmentType.fromValue('hologram'),
          throwsA(isA<FormatException>()));
    });
  });

  group('EntryAttachment.tryFromJson', () {
    Map<String, Object?> row(String type) => {
          'id': 1,
          'entry_id': 2,
          'type': type,
          'file_path': 'a.m4a',
          'rank': 0,
          'time_create': '2025-01-01T00:00:00.000',
        };

    test('reads a known row', () {
      final attachment = EntryAttachment.tryFromJson(row('audio'))!;

      expect(attachment.type, AttachmentType.audio);
    });

    test('returns null for a row of an unknown type', () {
      expect(EntryAttachment.tryFromJson(row('hologram')), isNull);
    });
  });
}
