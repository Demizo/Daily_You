// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:ui';

import 'package:daily_you/models/gallery_filter.dart';
import 'package:daily_you/utils/search_matcher.dart';

class TextHighlight {
  const TextHighlight({
    this.query = '',
    this.terms = const [],
    this.matchCase = false,
  });

  factory TextHighlight.fromFilter(GalleryFilter filter) => TextHighlight(
        query: filter.searchText,
        terms: filter.textTerms,
        matchCase: filter.textMatchCase,
      );

  static const none = TextHighlight();

  final String query;
  final List<String> terms;
  final bool matchCase;

  bool get isEmpty => query.isEmpty && terms.isEmpty;
  bool get isNotEmpty => !isEmpty;

  List<TextRange> findRanges(String text) {
    if (isEmpty) return const [];
    return mergeRanges([
      ...findMatches(text, query),
      for (final term in terms)
        if (term.isNotEmpty)
          for (final match in RegExp(
            RegExp.escape(term),
            caseSensitive: matchCase,
          ).allMatches(text))
            TextRange(start: match.start, end: match.end),
    ]);
  }
}
