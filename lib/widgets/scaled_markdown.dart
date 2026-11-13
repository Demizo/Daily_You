// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/markdown/markdown_blocks.dart';
import 'package:daily_you/utils/color_utils.dart';
import 'package:daily_you/utils/search_highlight.dart';
import 'package:daily_you/utils/search_matcher.dart';
import 'package:daily_you/widgets/markdown_highlight_syntax.dart';
import 'package:material_ui/material_ui.dart';
import 'package:markdown_widget/markdown_widget.dart';

// Fixes duplicate scaling issues with markdown_widget
// See: https://github.com/asjqkkkk/markdown_widget/issues/208
class ScaledMarkdown extends StatelessWidget {
  final String data;
  final int? maxCharacters;
  final double scaleFactor;
  final bool compact;
  final String highlightQuery;

  const ScaledMarkdown({
    super.key,
    required this.data,
    this.maxCharacters,
    this.scaleFactor = 1,
    this.compact = false,
    this.highlightQuery = '',
  });

  InlineSpan _highlighted(InlineSpan span) {
    if (highlightQuery.isEmpty) return span;
    final ranges = findMatches(
      span.toPlainText(includeSemanticsLabels: false),
      highlightQuery,
    );
    return highlightSpan(span, ranges, highlightBackgroundColor);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String text = data;

    if (maxCharacters != null && text.length > maxCharacters!) {
      text = "${text.substring(0, maxCharacters)}…";
    }

    // Get the device's current text scaling to respect user settings
    final deviceScaler = MediaQuery.textScalerOf(context);
    // Apply custom scaling to the user's text scale
    final customScaler = TextScaler.linear(deviceScaler.scale(scaleFactor));

    final baseConfig = theme.brightness == Brightness.light
        ? MarkdownConfig.defaultConfig
        : MarkdownConfig.darkConfig;
    final paragraphStyle = baseConfig.p.textStyle;
    final bulletOffset =
        (paragraphStyle.fontSize ?? 16.0) * (paragraphStyle.height ?? 1.2) / 2;
    final config = baseConfig.copy(configs: [
      ListConfig(
        marker: (isOrdered, depth, index) => isOrdered
            ? null
            : getDefaultMarker(false, depth, theme.colorScheme.onSurface, index,
                bulletOffset, baseConfig),
      ),
    ]);

    return MarkdownBlocks(
      data: text,
      config: config,
      inlineSyntaxes: [HighlightSyntax()],
      generators: [highlightGenerator(highlightBackgroundColor)],
      richTextBuilder: (span) =>
          Text.rich(_highlighted(span), textScaler: customScaler),
      linesMargin:
          compact ? EdgeInsets.zero : const EdgeInsets.only(bottom: 8, top: 2),
    );
  }
}
