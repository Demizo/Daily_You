// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:ui';

bool textMatchesQuery(String text, String query) =>
    text.toLowerCase().contains(query.toLowerCase());

List<TextRange> findMatches(String text, String query) {
  if (query.isEmpty) return const [];

  final lowerText = text.toLowerCase();
  final lowerQuery = query.toLowerCase();
  final matches = <TextRange>[];
  var searchStart = 0;
  while (true) {
    final index = lowerText.indexOf(lowerQuery, searchStart);
    if (index < 0) return matches;
    final end = index + lowerQuery.length;
    matches.add(TextRange(start: index, end: end));
    searchStart = end;
  }
}
