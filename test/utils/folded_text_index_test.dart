// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/utils/folded_text_index.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FoldedTextIndex', () {
    test('returns folded texts in the order requested', () {
      final index = FoldedTextIndex.empty.patched(['Café', 'Zürich']);
      expect(index.foldedTexts(['Zürich', 'Café']), ['zurich', 'cafe']);
    });

    test('keeps folded texts of unchanged entries and adds new ones', () {
      final first = FoldedTextIndex.empty.patched(['Café']);
      final second = first.patched(['Café', 'Zürich']);
      expect(second.foldedTexts(['Café', 'Zürich']), ['cafe', 'zurich']);
    });
  });
}
