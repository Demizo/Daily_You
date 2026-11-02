// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/markdown/block_nodes.dart';
import 'package:daily_you/markdown/markdown_parser.dart';
import 'package:markdown/markdown.dart' as m;
import 'package:markdown_widget/markdown_widget.dart';
import 'package:material_ui/material_ui.dart';

class MarkdownBlocks extends StatelessWidget {
  const MarkdownBlocks({
    super.key,
    required this.data,
    required this.config,
    required this.richTextBuilder,
    this.inlineSyntaxes = const [],
    this.generators = const [],
    this.linesMargin = const EdgeInsets.symmetric(vertical: 8),
  });

  final String data;
  final MarkdownConfig config;
  final RichTextBuilder richTextBuilder;
  final List<m.InlineSyntax> inlineSyntaxes;
  final List<SpanNodeGeneratorWithTag> generators;
  final EdgeInsets linesMargin;

  List<SpanNodeGeneratorWithTag> get _blockGenerators => [
        SpanNodeGeneratorWithTag(
          tag: MarkdownTag.ul.name,
          generator: (element, config, visitor) => BlockUlOrOlNode(
              element.tag, element.attributes, config.li, visitor),
        ),
        SpanNodeGeneratorWithTag(
          tag: MarkdownTag.ol.name,
          generator: (element, config, visitor) => BlockUlOrOlNode(
              element.tag, element.attributes, config.li, visitor),
        ),
        SpanNodeGeneratorWithTag(
          tag: MarkdownTag.li.name,
          generator: (element, config, visitor) =>
              BlockListNode(config, visitor),
        ),
        SpanNodeGeneratorWithTag(
          tag: MarkdownTag.blockquote.name,
          generator: (element, config, visitor) =>
              BlockBlockquoteNode(config.blockquote, visitor),
        ),
        ...generators,
      ];

  @override
  Widget build(BuildContext context) {
    final splitRegExp = WidgetVisitor.defaultSplitRegExp;
    final nodes = MarkdownParser(
      inlineSyntaxes: inlineSyntaxes,
      splitRegExp: splitRegExp,
    ).parse(data);
    final visitor = WidgetVisitor(
      config: config,
      generators: _blockGenerators,
      richTextBuilder: richTextBuilder,
      splitRegExp: splitRegExp,
    );
    final blocks = <Widget>[];
    for (final span in visitor.visit(nodes)) {
      final children = span is ElementNode ? span.children : const <SpanNode>[];
      final Widget content;
      if (children.length == 1 && isBlockNode(children.first)) {
        content = blockWidgetOf(children.first);
      } else {
        content = richTextBuilder(span.build());
      }
      blocks.add(Padding(padding: linesMargin, child: content));
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }
}
