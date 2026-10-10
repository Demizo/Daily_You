// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/utils/color_utils.dart';
import 'package:material_ui/material_ui.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:markdown_widget/markdown_widget.dart';

const _highlightTag = 'mark';

class HighlightSyntax extends md.DelimiterSyntax {
  HighlightSyntax()
      : super(
          r'==+',
          requiresDelimiterRun: true,
          allowIntraWord: true,
          tags: [md.DelimiterTag(_highlightTag, 2)],
        );
}

SpanNodeGeneratorWithTag highlightGenerator(Color backgroundColor) =>
    SpanNodeGeneratorWithTag(
      tag: _highlightTag,
      generator: (element, config, visitor) => _MarkNode(backgroundColor),
    );

class _MarkNode extends ElementNode {
  _MarkNode(this.backgroundColor);

  final Color backgroundColor;

  @override
  TextStyle get style {
    final highlighted = TextStyle(
      backgroundColor: backgroundColor,
      color: contrastingTextColor(backgroundColor),
    );
    return parentStyle?.merge(highlighted) ?? highlighted;
  }
}
