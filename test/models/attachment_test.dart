// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/attachment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EntryAttachment.appendRanked', () {
    test('assigns descending ranks so newest share sorts first', () {
      final result = EntryAttachment.appendRanked(const [], ['a.jpg', 'b.jpg'],
          entryId: 1);

      expect(result.map((e) => e.filePath), ['a.jpg', 'b.jpg']);
      expect(result.map((e) => e.rank), [1, 0]);
    });

    test('shifts existing attachments up without mutating the input list', () {
      final existing = [
        EntryAttachment(
            id: 1,
            entryId: 1,
            filePath: 'existing.jpg',
            rank: 0,
            timeCreate: DateTime(2025)),
      ];

      final result =
          EntryAttachment.appendRanked(existing, ['new.jpg'], entryId: 1);

      expect(existing.single.rank, 0);
      expect(result.map((e) => e.filePath), ['existing.jpg', 'new.jpg']);
      expect(result.map((e) => e.rank), [1, 0]);
    });

    test('returns a copy of the input when there is nothing to add', () {
      final existing = [
        EntryAttachment(
            entryId: 1,
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
}
