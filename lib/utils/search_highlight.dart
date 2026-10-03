// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/utils/color_utils.dart';
import 'package:daily_you/utils/search_matcher.dart';
import 'package:material_ui/material_ui.dart';

InlineSpan highlightSpan(InlineSpan span, String query, Color background) {
  if (query.isEmpty) return span;

  final matches =
      findMatches(span.toPlainText(includeSemanticsLabels: false), query);
  if (matches.isEmpty) return span;

  return _SpanHighlighter(
    matches,
    TextStyle(
      backgroundColor: background,
      color: contrastingTextColor(background),
    ),
  ).highlight(span);
}

class _SpanHighlighter {
  _SpanHighlighter(this.matches, this.highlightStyle);

  final List<TextRange> matches;
  final TextStyle highlightStyle;

  int _offset = 0;
  int _matchIndex = 0;

  InlineSpan highlight(InlineSpan span) {
    if (span is! TextSpan) {
      _offset += span.toPlainText(includeSemanticsLabels: false).length;
      return span;
    }

    final text = span.text;
    final segments = text == null ? null : _splitAtMatches(span, text);
    final children = span.children?.map(highlight).toList();

    if (segments == null) {
      return _copy(span, text: text, children: children, style: span.style);
    }

    return TextSpan(
      children: [...segments, ...?children],
      style: span.style,
    );
  }

  List<TextSpan>? _splitAtMatches(TextSpan span, String text) {
    final start = _offset;
    final end = start + text.length;
    _offset = end;

    while (_matchIndex < matches.length && matches[_matchIndex].end <= start) {
      _matchIndex++;
    }
    if (_matchIndex == matches.length || matches[_matchIndex].start >= end) {
      return null;
    }

    final highlighted = (span.style ?? const TextStyle()).merge(highlightStyle);
    final segments = <TextSpan>[];
    var position = start;

    void addSegment(int segmentEnd, bool isMatch) {
      if (segmentEnd <= position) return;
      segments.add(_copy(
        span,
        text: text.substring(position - start, segmentEnd - start),
        style: isMatch ? highlighted : null,
      ));
      position = segmentEnd;
    }

    var index = _matchIndex;
    while (index < matches.length && matches[index].start < end) {
      final match = matches[index];
      addSegment(match.start, false);
      addSegment(match.end < end ? match.end : end, true);
      if (match.end > end) break;
      index++;
    }
    addSegment(end, false);
    _matchIndex = index;
    return segments;
  }

  TextSpan _copy(
    TextSpan source, {
    String? text,
    List<InlineSpan>? children,
    TextStyle? style,
  }) =>
      TextSpan(
        text: text,
        children: children,
        style: style,
        recognizer: source.recognizer,
        mouseCursor: source.mouseCursor,
        onEnter: source.onEnter,
        onExit: source.onExit,
      );
}
