// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:markdown_widget/markdown_widget.dart';
import 'package:material_ui/material_ui.dart';

bool isBlockNode(SpanNode node) =>
    node is UlOrOLNode ||
    node is BlockquoteNode ||
    node is CodeBlockNode ||
    node is HrNode ||
    node is TableNode ||
    (node is HeadingNode && node.headingConfig.divider != null);

Widget blockWidgetOf(SpanNode node) => (node.build() as WidgetSpan).child;

Widget childrenWidget(
  List<SpanNode> nodes,
  RichTextBuilder? richTextBuilder,
) {
  final runs = <Widget>[];
  var inline = <InlineSpan>[];

  void flush() {
    if (inline.isEmpty) return;
    final span = TextSpan(children: inline);
    runs.add(richTextBuilder?.call(span) ?? Text.rich(span));
    inline = <InlineSpan>[];
  }

  for (final node in nodes) {
    if (isBlockNode(node)) {
      flush();
      runs.add(blockWidgetOf(node));
    } else {
      inline.add(node.build());
    }
  }
  flush();
  if (runs.length == 1) return runs.first;
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: runs,
  );
}

class BlockUlOrOlNode extends UlOrOLNode {
  BlockUlOrOlNode(super.tag, super.attribute, super.config, super.visitor);

  @override
  InlineSpan build() {
    return WidgetSpan(
      child: Padding(
        padding: EdgeInsets.only(top: parent == null ? 0 : config.marginBottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [for (final child in children) blockWidgetOf(child)],
        ),
      ),
    );
  }
}

class BlockListNode extends ListNode {
  BlockListNode(super.config, super.visitor);

  @override
  InlineSpan build() {
    final parentStyleHeight =
        (parentStyle?.fontSize ?? config.p.textStyle.fontSize ?? 16.0) *
            (parentStyle?.height ?? config.p.textStyle.height ?? 1.2);
    final Widget marker;
    if (isCheckbox) {
      marker = ProxyRichText(
        children.removeAt(0).build(),
        richTextBuilder: visitor.richTextBuilder,
      );
    } else {
      marker = config.li.marker?.call(isOrdered, depth, index) ??
          getDefaultMarker(isOrdered, depth, parentStyle?.color, index,
              parentStyleHeight / 2, config);
    }
    return WidgetSpan(
      child: Padding(
        padding: EdgeInsets.only(bottom: config.li.marginBottom),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: config.li.marginLeft, child: marker),
            Flexible(child: childrenWidget(children, visitor.richTextBuilder)),
          ],
        ),
      ),
    );
  }
}

class BlockBlockquoteNode extends BlockquoteNode {
  BlockBlockquoteNode(super.config, super.visitor);

  @override
  InlineSpan build() {
    return WidgetSpan(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: config.sideColor, width: config.sideWith),
          ),
        ),
        padding: config.padding,
        margin: config.margin,
        child: childrenWidget(children, visitor.richTextBuilder),
      ),
    );
  }
}
