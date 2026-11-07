// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/utils/markdown_preview_scanner.dart';
import 'package:daily_you/utils/text_editing.dart';
import 'package:daily_you/widgets/markdown_preview_controller.dart';
import 'package:flutter/widgets.dart';

const Map<MarkdownConstruct, (String, String)> _inlineDelimiters = {
  MarkdownConstruct.bold: ('**', '**'),
  MarkdownConstruct.italic: ('_', '_'),
  MarkdownConstruct.highlight: ('==', '=='),
  MarkdownConstruct.strikethrough: ('~~', '~~'),
  MarkdownConstruct.link: ('[', ']()'),
};

const Map<MarkdownConstruct, String> _linePrefixes = {
  MarkdownConstruct.bulletList: '-',
  MarkdownConstruct.blockquote: '>',
};

bool isMarkdownActive(
    TextEditingController controller, MarkdownConstruct construct) {
  return _findRemovals(controller, construct) != null;
}

bool removeMarkdown(
    TextEditingController controller, MarkdownConstruct construct) {
  final removals = _findRemovals(controller, construct);
  if (removals == null) return false;

  final text = controller.text;
  final selection = controller.selection;
  var removed = text;
  for (final range in removals.reversed) {
    removed = removed.replaceRange(range.start, range.end, '');
  }

  int shift(int offset) {
    var shifted = offset;
    for (final range in removals) {
      if (offset >= range.end) {
        shifted -= range.end - range.start;
      } else if (offset > range.start) {
        shifted -= offset - range.start;
      }
    }
    return shifted;
  }

  final offset = selection.isValid ? selection.baseOffset : text.length;
  final extent = selection.isValid ? selection.extentOffset : text.length;
  controller.value = TextEditingValue(
    text: removed,
    selection:
        TextSelection(baseOffset: shift(offset), extentOffset: shift(extent)),
  );
  return true;
}

void toggleMarkdown(
    TextEditingController controller, MarkdownConstruct construct) {
  if (removeMarkdown(controller, construct)) return;

  final delimiters = _inlineDelimiters[construct];
  if (delimiters != null) {
    wrapSelection(controller, delimiters.$1, delimiters.$2);
  } else {
    insertLinePrefix(controller, _linePrefixes[construct]!);
  }
}

List<TextRange>? _findRemovals(
    TextEditingController controller, MarkdownConstruct construct) {
  final text = controller.text;
  final selection = controller.selection;
  final start = selection.isValid ? selection.start : text.length;
  final end = selection.isValid ? selection.end : text.length;

  if (_inlineDelimiters.containsKey(construct)) {
    return _findWrapping(controller, construct, start, end);
  }
  return _findLineMarker(controller, construct, start);
}

MarkdownScan _scanOf(TextEditingController controller) =>
    controller is MarkdownPreviewController
        ? controller.scan
        : scanMarkdown(controller.text);

List<TextRange>? _findWrapping(TextEditingController controller,
    MarkdownConstruct construct, int start, int end) {
  final spans = _scanOf(controller)
      .spans
      .where((span) => span.construct == construct)
      .toList();

  List<TextRange>? innermost;
  for (final content
      in spans.where((span) => span.role == MarkdownSpanRole.content)) {
    final open = spans.where((span) =>
        span.role == MarkdownSpanRole.marker && span.end == content.start);
    final close = spans.where((span) =>
        span.role == MarkdownSpanRole.marker && span.start == content.end);
    if (open.isEmpty || close.isEmpty) continue;

    final groupStart = open.first.start;
    final groupEnd = close.first.end;
    final contains = start == end
        ? groupStart < start && start <= groupEnd
        : groupStart <= start && end <= groupEnd;
    if (!contains) continue;

    innermost = [
      TextRange(start: open.first.start, end: open.first.end),
      TextRange(start: close.first.start, end: close.first.end),
    ];
  }
  if (innermost != null) return innermost;

  if (start != end) return null;
  final (left, right) = _inlineDelimiters[construct]!;
  final text = controller.text;
  if (start < left.length || start + right.length > text.length) return null;
  final pairs = text.substring(start - left.length, start) == left &&
      text.substring(start, start + right.length) == right;
  return pairs
      ? [
          TextRange(start: start - left.length, end: start),
          TextRange(start: start, end: start + right.length),
        ]
      : null;
}

List<TextRange>? _findLineMarker(
    TextEditingController controller, MarkdownConstruct construct, int offset) {
  final text = controller.text;
  final lineStart = offset == 0 ? 0 : text.lastIndexOf('\n', offset - 1) + 1;
  final lineBreak = text.indexOf('\n', offset);
  final lineEnd = lineBreak < 0 ? text.length : lineBreak;

  for (final span in _scanOf(controller).spans) {
    if (span.construct != construct || span.role != MarkdownSpanRole.marker) {
      continue;
    }
    if (span.start < lineStart || span.start >= lineEnd) continue;

    final followedBySpace = span.end < text.length && text[span.end] == ' ';
    return [
      TextRange(start: span.start, end: span.end + (followedBySpace ? 1 : 0)),
    ];
  }
  return null;
}
