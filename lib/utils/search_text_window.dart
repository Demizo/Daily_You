// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/utils/markdown_preview_scanner.dart';
import 'package:daily_you/utils/search_matcher.dart';

const _longLineThreshold = 40;
const _contextBeforeMatch = 20;

String searchTextWindow(String text, String query) {
  final matches = findMatches(text, query);
  if (matches.isEmpty) return text;

  final matchStart = matches.first.start;
  final lineStart =
      matchStart == 0 ? 0 : text.lastIndexOf('\n', matchStart - 1) + 1;

  for (final block in scanMarkdown(text).blocks) {
    if (block.kind == MarkdownBlockKind.codeBlock &&
        block.start <= lineStart &&
        lineStart < block.end) {
      return text.substring(block.start);
    }
  }

  if (matchStart - lineStart <= _longLineThreshold) {
    return text.substring(lineStart);
  }

  for (var index = matchStart - _contextBeforeMatch;
      index >= lineStart;
      index--) {
    if (text[index].trim().isEmpty) {
      return '…${text.substring(index + 1)}';
    }
  }
  return text.substring(lineStart);
}
