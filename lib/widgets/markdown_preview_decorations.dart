import 'dart:math';
import 'dart:ui' show BoxHeightStyle;

import 'package:daily_you/utils/markdown_preview_scanner.dart';
import 'package:daily_you/widgets/markdown_preview_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class MarkdownPreviewDecorations extends SingleChildRenderObjectWidget {
  const MarkdownPreviewDecorations({
    super.key,
    required this.controller,
    required this.scrollController,
    required this.barColor,
    required this.panelColor,
    required super.child,
  });

  static const BoxHeightStyle heightStyle = BoxHeightStyle.max;

  final MarkdownPreviewController controller;
  final ScrollController scrollController;
  final Color barColor;
  final Color panelColor;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderMarkdownPreviewDecorations(
        controller: controller,
        scrollController: scrollController,
        barColor: barColor,
        panelColor: panelColor,
      );

  @override
  void updateRenderObject(
      BuildContext context, RenderMarkdownPreviewDecorations renderObject) {
    renderObject
      ..controller = controller
      ..scrollController = scrollController
      ..barColor = barColor
      ..panelColor = panelColor;
  }
}

class RenderMarkdownPreviewDecorations extends RenderProxyBox {
  RenderMarkdownPreviewDecorations({
    required MarkdownPreviewController controller,
    required ScrollController scrollController,
    required Color barColor,
    required Color panelColor,
  })  : _controller = controller,
        _scrollController = scrollController,
        _barColor = barColor,
        _panelColor = panelColor;

  static const double _barWidth = 3;
  static const double _barGap = 4;
  static const double _blockMargin = 4;
  static const Radius _panelRadius = Radius.circular(8);

  MarkdownPreviewController _controller;
  ScrollController _scrollController;
  Color _barColor;
  Color _panelColor;

  set controller(MarkdownPreviewController value) {
    if (_controller == value) return;
    if (attached) _controller.removeListener(markNeedsPaint);
    _controller = value;
    if (attached) _controller.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  set scrollController(ScrollController value) {
    if (_scrollController == value) return;
    if (attached) _scrollController.removeListener(markNeedsPaint);
    _scrollController = value;
    if (attached) _scrollController.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  set barColor(Color value) {
    if (_barColor == value) return;
    _barColor = value;
    markNeedsPaint();
  }

  set panelColor(Color value) {
    if (_panelColor == value) return;
    _panelColor = value;
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _controller.addListener(markNeedsPaint);
    _scrollController.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _controller.removeListener(markNeedsPaint);
    _scrollController.removeListener(markNeedsPaint);
    super.detach();
  }

  RenderEditable? _editableChild() {
    RenderEditable? found;
    void visit(RenderObject node) {
      if (found != null) return;
      if (node is RenderEditable) {
        found = node;
        return;
      }
      node.visitChildren(visit);
    }

    visitChildren(visit);
    return found;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final blocks = _controller.scan.blocks;
    final editable = blocks.isEmpty ? null : _editableChild();
    if (editable != null) {
      final textOrigin =
          offset + editable.localToGlobal(Offset.zero, ancestor: this);
      final canvas = context.canvas;
      canvas.save();
      canvas.clipRect(Rect.fromLTRB(offset.dx, textOrigin.dy,
          offset.dx + size.width, textOrigin.dy + editable.size.height));
      for (final block in blocks) {
        _paintBlock(canvas, editable, block, offset, textOrigin);
      }
      canvas.restore();
    }
    super.paint(context, offset);
  }

  void _paintBlock(Canvas canvas, RenderEditable editable, MarkdownBlock block,
      Offset offset, Offset textOrigin) {
    final boxes = editable.getBoxesForSelection(
      TextSelection(baseOffset: block.start, extentOffset: block.end),
    );
    if (boxes.isEmpty) return;

    var top = double.infinity;
    var bottom = double.negativeInfinity;
    for (final box in boxes) {
      top = min(top, box.top);
      bottom = max(bottom, box.bottom);
    }
    top += textOrigin.dy;
    bottom += textOrigin.dy;

    final edge = offset.dx + _blockMargin;

    if (block.kind == MarkdownBlockKind.codeBlock) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
              edge, top, offset.dx + size.width - _blockMargin, bottom),
          _panelRadius,
        ),
        Paint()..color = _panelColor,
      );
      return;
    }

    final marker = editable.getBoxesForSelection(
      TextSelection(baseOffset: block.start, extentOffset: block.markerEnd),
    );
    final markerLeft = marker.isEmpty ? 0.0 : textOrigin.dx + marker.first.left;
    final left = max(edge, markerLeft - _barGap - _barWidth);
    canvas.drawRect(
      Rect.fromLTRB(left, top, left + _barWidth, bottom),
      Paint()..color = _barColor,
    );
  }
}
