// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math';
import 'dart:ui';

import 'package:daily_you/utils/bitap_pattern.dart';
import 'package:daily_you/utils/text_folding.dart';

const int _maxApproximateLength = 32;

final RegExp _whitespace = RegExp(r'\s+');

List<String> _searchWords(String query) => [
      for (final word in foldText(query).split(_whitespace))
        if (word.isNotEmpty) word,
    ];

bool _isWide(int unit) =>
    (unit >= 0x3040 && unit <= 0x30ff) ||
    (unit >= 0x3400 && unit <= 0x9fff) ||
    (unit >= 0xac00 && unit <= 0xd7af);

bool _hasWideCharacters(String word) => word.codeUnits.any(_isWide);

bool _isWordUnit(int unit) =>
    (unit >= 0x30 && unit <= 0x39) ||
    (unit >= 0x61 && unit <= 0x7a) ||
    (unit >= 0xc0 && unit < 0x3000 && unit != 0xd7 && unit != 0xf7);

int editBudget(String word) {
  if (word.length > _maxApproximateLength) return 0;
  final wideCount = word.codeUnits.where(_isWide).length;
  final weightedLength = word.length + wideCount;
  final edits = weightedLength >= 7 ? 2 : (weightedLength >= 5 ? 1 : 0);
  if (wideCount == 0) return edits;
  return min(edits, word.length ~/ 4);
}

class _RankedWord {
  _RankedWord._(this.text, this.budget)
      : pattern = budget > 0 ? BitapPattern(text, budget) : null;

  factory _RankedWord(String text) => _RankedWord._(text, editBudget(text));

  final String text;
  final int budget;
  final BitapPattern? pattern;
}

typedef SearchTiers = ({List<int> exact, List<int> partial});

SearchTiers tierByMatch(List<String> foldedTexts, String query) {
  final words = [for (final word in _searchWords(query)) _RankedWord(word)];
  if (words.isEmpty) {
    return (
      exact: List<int>.generate(foldedTexts.length, (position) => position),
      partial: const [],
    );
  }

  final exact = <int>[];
  final partial = <int>[];
  for (var position = 0; position < foldedTexts.length; position++) {
    final text = foldedTexts[position];
    if (words.every((word) => text.contains(word.text))) {
      exact.add(position);
    } else if (_matchesApproximately(text, words)) {
      partial.add(position);
    }
  }
  return (exact: exact, partial: partial);
}

bool _matchesApproximately(String text, List<_RankedWord> words) {
  for (final word in words) {
    if (text.contains(word.text)) continue;
    final pattern = word.pattern;
    if (pattern == null) return false;
    if (pattern.errorsIn(text, stopAtErrors: 1) > word.budget) return false;
  }
  return true;
}

List<TextRange> findMatches(String text, String query) {
  final words = _searchWords(query);
  if (words.isEmpty) return const [];

  final foldedText = foldText(text);
  final ranges = [for (final word in words) ..._rangesOfWord(foldedText, word)]
    ..sort((a, b) => a.start.compareTo(b.start));

  final merged = <TextRange>[];
  for (final range in ranges) {
    if (merged.isNotEmpty && range.start < merged.last.end) {
      final last = merged.removeLast();
      merged.add(
        TextRange(
          start: last.start,
          end: max(range.end, last.end),
        ),
      );
    } else {
      merged.add(range);
    }
  }
  return merged;
}

List<TextRange> _rangesOfWord(String foldedText, String word) {
  final exact = _exactRanges(foldedText, word);
  final budget = editBudget(word);
  if (exact.isNotEmpty || budget == 0) return exact;
  return _approximateRanges(foldedText, word, budget);
}

List<TextRange> _exactRanges(String foldedText, String word) {
  final ranges = <TextRange>[];
  var searchStart = 0;
  while (true) {
    final index = foldedText.indexOf(word, searchStart);
    if (index < 0) return ranges;
    searchStart = index + word.length;
    ranges.add(TextRange(start: index, end: searchStart));
  }
}

List<TextRange> _approximateRanges(String foldedText, String word, int budget) {
  final ranges = <TextRange>[];
  final snapToWord = !_hasWideCharacters(word);
  var clusterEnd = -1;
  var clusterErrors = budget + 1;

  void flushCluster() {
    if (clusterEnd < 0) return;
    ranges.add(
      snapToWord
          ? _surroundingWord(foldedText, clusterEnd)
          : TextRange(
              start: max(0, clusterEnd + 1 - word.length),
              end: clusterEnd + 1,
            ),
    );
    clusterEnd = -1;
    clusterErrors = budget + 1;
  }

  BitapPattern(word, budget).forEachMatchEnd(foldedText, (endIndex, errors) {
    if (clusterEnd >= 0 && endIndex - clusterEnd > word.length) flushCluster();
    if (errors <= clusterErrors) {
      clusterErrors = errors;
      clusterEnd = endIndex;
    }
  });
  flushCluster();
  return ranges;
}

TextRange _surroundingWord(String foldedText, int index) {
  var start = index;
  while (start > 0 && _isWordUnit(foldedText.codeUnitAt(start - 1))) {
    start--;
  }
  var end = index + 1;
  while (end < foldedText.length && _isWordUnit(foldedText.codeUnitAt(end))) {
    end++;
  }
  return TextRange(start: start, end: end);
}
