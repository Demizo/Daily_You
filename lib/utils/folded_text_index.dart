// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/utils/text_folding.dart';

class FoldedTextIndex {
  const FoldedTextIndex._(this._foldedByText);

  static const FoldedTextIndex empty = FoldedTextIndex._({});

  final Map<String, String> _foldedByText;

  FoldedTextIndex patched(Iterable<String> texts) => FoldedTextIndex._({
        for (final text in texts) text: _foldedByText[text] ?? foldText(text),
      });

  List<String> foldedTexts(Iterable<String> texts) => [
        for (final text in texts) _foldedByText[text]!,
      ];
}
