import 'dart:math';

import 'package:daily_you/utils/color_utils.dart';
import 'package:daily_you/utils/markdown_preview_scanner.dart';
import 'package:flutter/material.dart';

/// Maps style onto the Markdown constructs
class MarkdownPreviewStyles {
  const MarkdownPreviewStyles({
    required this.marker,
    required this.link,
    required this.quote,
    required this.codeBackground,
    required this.misspelling,
    required this.highlightBackground,
  });

  factory MarkdownPreviewStyles.fromTheme(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return MarkdownPreviewStyles(
      marker: colors.outline,
      link: colors.primary,
      quote: colors.onSurfaceVariant,
      misspelling: colors.error,
      codeBackground: colors.surfaceContainerHighest,
      highlightBackground: Colors.yellow.shade700,
    );
  }

  static const double _quoteMarkerScale = 0.75;

  static double _headerScale(int level) => switch (level) {
        1 => 1.5,
        2 => 1.25,
        3 => 1.125,
        _ => 1,
      };

  final Color marker;
  final Color link;
  final Color quote;
  final Color codeBackground;
  final Color misspelling;
  final Color highlightBackground;

  TextStyle apply(TextStyle style, MarkdownSpan span) {
    final sized = span.construct == MarkdownConstruct.header
        ? style.copyWith(
            fontSize: (style.fontSize ?? 16) * _headerScale(span.headerLevel))
        : style;

    if (span.role == MarkdownSpanRole.marker) {
      final muted = sized.copyWith(color: marker);
      return switch (span.construct) {
        MarkdownConstruct.blockquote => muted.copyWith(
            fontWeight: FontWeight.normal,
            fontSize: (sized.fontSize ?? 16) * _quoteMarkerScale,
          ),
        MarkdownConstruct.bulletList =>
          muted.copyWith(fontWeight: FontWeight.bold),
        _ => muted.copyWith(fontWeight: FontWeight.normal),
      };
    }

    switch (span.construct) {
      case MarkdownConstruct.bold:
        return sized.copyWith(fontWeight: FontWeight.bold);
      case MarkdownConstruct.italic:
        return sized.copyWith(fontStyle: FontStyle.italic);
      case MarkdownConstruct.strikethrough:
        return _decorate(sized, TextDecoration.lineThrough);
      case MarkdownConstruct.highlight:
        return sized.copyWith(
          backgroundColor: highlightBackground,
          color: contrastingTextColor(highlightBackground),
        );
      case MarkdownConstruct.header:
        return sized.copyWith(fontWeight: FontWeight.bold);
      case MarkdownConstruct.link:
        return _decorate(sized.copyWith(color: link), TextDecoration.underline);
      case MarkdownConstruct.inlineCode:
        return sized.copyWith(backgroundColor: codeBackground);
      case MarkdownConstruct.blockquote:
        return sized.copyWith(color: quote);
      case MarkdownConstruct.codeBlock:
      case MarkdownConstruct.bulletList:
      case MarkdownConstruct.numberedList:
      case MarkdownConstruct.horizontalRule:
        return sized;
    }
  }
}

/// Flattens the nested [spans] into one styled span per stretch of text
TextSpan buildMarkdownPreviewSpan({
  required String text,
  required List<MarkdownSpan> spans,
  required TextStyle baseStyle,
  required MarkdownPreviewStyles styles,
  TextRange composing = TextRange.empty,
  List<TextRange> misspellings = const [],
}) {
  if (text.isEmpty) return TextSpan(style: baseStyle);

  final underlined = <TextRange>[
    if (composing.isValid && composing.end <= text.length) composing,
  ];
  final marked = [
    for (final range in misspellings)
      if (range.isValid && range.end <= text.length) range,
  ];

  final children = <TextSpan>[];
  final activeSpans = <MarkdownSpan>[];
  var cursor = 0;
  var nextSpan = 0;

  while (cursor < text.length) {
    while (nextSpan < spans.length && spans[nextSpan].start <= cursor) {
      activeSpans.add(spans[nextSpan++]);
    }

    var segmentEnd =
        nextSpan < spans.length ? spans[nextSpan].start : text.length;
    for (final span in activeSpans) {
      segmentEnd = min(segmentEnd, span.end);
    }
    for (final range in underlined.followedBy(marked)) {
      if (range.start > cursor) segmentEnd = min(segmentEnd, range.start);
      if (range.end > cursor) segmentEnd = min(segmentEnd, range.end);
    }

    var style = baseStyle;
    for (final span in activeSpans) {
      style = styles.apply(style, span);
    }
    if (_covers(underlined, cursor, segmentEnd)) {
      style = _decorate(style, TextDecoration.underline);
    }
    if (_covers(marked, cursor, segmentEnd)) {
      style = _decorate(style, TextDecoration.underline).copyWith(
        decorationColor: styles.misspelling,
        decorationStyle: TextDecorationStyle.wavy,
      );
    }

    children
        .add(TextSpan(text: text.substring(cursor, segmentEnd), style: style));
    cursor = segmentEnd;
    activeSpans.removeWhere((span) => span.end <= cursor);
  }

  return TextSpan(style: baseStyle, children: children);
}

bool _covers(List<TextRange> ranges, int start, int end) {
  for (final range in ranges) {
    if (start >= range.start && end <= range.end) return true;
  }
  return false;
}

TextStyle _decorate(TextStyle style, TextDecoration decoration) {
  final existing = style.decoration;
  return style.copyWith(
    decoration: existing == null || existing == TextDecoration.none
        ? decoration
        : TextDecoration.combine([existing, decoration]),
  );
}
