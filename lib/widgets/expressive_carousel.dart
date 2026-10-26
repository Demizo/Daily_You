// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:daily_you/utils/carousel_fling.dart';
import 'package:daily_you/utils/carousel_layout.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

const _cardShape =
    RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12)));
final _showArrows = Platform.isLinux || Platform.isWindows || Platform.isMacOS;

const _mediumLowStiffness = 400.0;
const _noBounceDampingRatio = 1.0;
const _carouselSettleDuration = Duration(milliseconds: 500);
const _fadeStartVisibleFraction = 0.6;
const _fadeVisibleFractionRange = 0.3;
const _interactionOverlayOpacity = 0.1;

final _carouselSpring = SpringDescription.withDampingRatio(
  mass: 1,
  stiffness: _mediumLowStiffness,
  ratio: _noBounceDampingRatio,
);

class _SpringCurve extends Curve {
  _SpringCurve() : _simulation = SpringSimulation(_carouselSpring, 0, 1, 0);

  final SpringSimulation _simulation;

  @override
  double transformInternal(double t) =>
      _simulation.x(t * _carouselSettleDuration.inMilliseconds / 1000);
}

class _CarouselViewport extends MultiChildRenderObjectWidget {
  const _CarouselViewport({
    required this.offset,
    required this.layout,
    required super.children,
  });

  final ViewportOffset offset;
  final CarouselLayout layout;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderCarouselViewport(
        offset: offset,
        carouselLayout: layout,
        textDirection: Directionality.of(context),
      );

  @override
  void updateRenderObject(
      BuildContext context, _RenderCarouselViewport renderObject) {
    renderObject
      ..offset = offset
      ..carouselLayout = layout
      ..textDirection = Directionality.of(context);
  }
}

class _CarouselParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderCarouselViewport extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox,
            ContainerBoxParentData<RenderBox>>,
        RenderBoxContainerDefaultsMixin<RenderBox,
            ContainerBoxParentData<RenderBox>> {
  _RenderCarouselViewport({
    required ViewportOffset offset,
    required CarouselLayout carouselLayout,
    required TextDirection textDirection,
  })  : _offset = offset,
        _carouselLayout = carouselLayout,
        _textDirection = textDirection;

  ViewportOffset _offset;
  set offset(ViewportOffset value) {
    if (_offset == value) return;
    if (attached) _offset.removeListener(markNeedsLayout);
    _offset = value;
    if (attached) _offset.addListener(markNeedsLayout);
    markNeedsLayout();
  }

  CarouselLayout _carouselLayout;
  set carouselLayout(CarouselLayout value) {
    _carouselLayout = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! ContainerBoxParentData<RenderBox>) {
      child.parentData = _CarouselParentData();
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _offset.addListener(markNeedsLayout);
  }

  @override
  void detach() {
    _offset.removeListener(markNeedsLayout);
    super.detach();
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void performLayout() {
    size = constraints.biggest;
    _offset.applyViewportDimension(size.width);
    _offset.applyContentDimensions(0, _carouselLayout.maxPixels);
    final widths = _carouselLayout
        .itemWidths(_carouselLayout.scrolledItems(_offset.pixels));
    var start = 0.0;
    var child = firstChild;
    for (final width in widths) {
      child!.layout(BoxConstraints.tightFor(width: width, height: size.height));
      (child.parentData! as ContainerBoxParentData<RenderBox>).offset = Offset(
          _textDirection == TextDirection.rtl
              ? size.width - start - width
              : start,
          0);
      start += width;
      child = childAfter(child);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

class _CarouselScrollPhysics extends ScrollPhysics {
  const _CarouselScrollPhysics({required this.itemExtent, super.parent});

  final ValueGetter<double> itemExtent;

  @override
  SpringDescription get spring => _carouselSpring;

  @override
  _CarouselScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      _CarouselScrollPhysics(
          itemExtent: itemExtent, parent: buildParent(ancestor));

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    final extent = itemExtent();
    if (extent <= 0 ||
        (velocity <= 0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final tolerance = toleranceFor(position);
    final targetItem = CarouselLayout.flingTargetItem(
      scrolledItems: position.pixels / extent,
      projectedItems:
          (position.pixels + carouselCoastingDistance(velocity, tolerance)) /
              extent,
      direction: velocity.abs() > tolerance.velocity ? velocity : 0,
      maxScrolledItems: (position.maxScrollExtent / extent).round(),
    );
    final targetPixels = targetItem * extent;
    if ((targetPixels - position.pixels).abs() < tolerance.distance) {
      return null;
    }
    return carouselSnapSimulation(
      position: position.pixels,
      velocity: velocity,
      target: targetPixels,
      spring: spring,
      tolerance: tolerance,
    );
  }
}

class _CarouselItemScope extends InheritedWidget {
  const _CarouselItemScope({
    required this.visibleFraction,
    required super.child,
  });

  final double visibleFraction;

  @override
  bool updateShouldNotify(_CarouselItemScope oldWidget) =>
      visibleFraction != oldWidget.visibleFraction;
}

class CarouselItemFade extends StatelessWidget {
  const CarouselItemFade({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final visibleFraction = context
            .dependOnInheritedWidgetOfExactType<_CarouselItemScope>()
            ?.visibleFraction ??
        1;
    return Opacity(
      opacity: ((visibleFraction - _fadeStartVisibleFraction) /
              _fadeVisibleFractionRange)
          .clamp(0.0, 1.0),
      child: child,
    );
  }
}

class ExpressiveCarousel extends StatefulWidget {
  const ExpressiveCarousel({
    super.key,
    required this.heightForItemWidth,
    required this.itemCount,
    required this.itemMinWidth,
    required this.itemMaxWidth,
    required this.itemBuilder,
    required this.onTap,
    this.backgroundColor,
    this.alignment = AlignmentDirectional.center,
  });

  final double Function(double largeItemWidth) heightForItemWidth;
  final int itemCount;
  final double itemMinWidth;
  final double itemMaxWidth;
  final IndexedWidgetBuilder itemBuilder;
  final ValueChanged<int> onTap;
  final Color? backgroundColor;
  final AlignmentDirectional alignment;

  @override
  State<ExpressiveCarousel> createState() => _ExpressiveCarouselState();
}

class _ExpressiveCarouselState extends State<ExpressiveCarousel> {
  final ScrollController _controller = ScrollController();
  CarouselLayout? _layout;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _arrow({required bool forward, required int targetItem}) {
    final isRightToLeft = Directionality.of(context) == TextDirection.rtl;
    return Positioned.fill(
      child: Align(
        alignment: forward
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: IconButton.filledTonal(
            icon: Icon(forward != isRightToLeft
                ? Icons.chevron_right_rounded
                : Icons.chevron_left_rounded),
            onPressed: () => _controller.animateTo(
              targetItem * _layout!.largeItemWidth,
              duration: _carouselSettleDuration,
              curve: _SpringCurve(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _arrows(CarouselLayout layout) {
    return Positioned.fill(
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final scrolledItems = _controller.hasClients
              ? layout.scrolledItems(_controller.offset).round()
              : 0;
          return Stack(
            fit: StackFit.expand,
            children: [
              if (scrolledItems > 0)
                _arrow(forward: false, targetItem: scrolledItems - 1),
              if (scrolledItems < layout.maxScrolledItems)
                _arrow(forward: true, targetItem: scrolledItems + 1),
            ],
          );
        },
      ),
    );
  }

  Widget _item(CarouselLayout layout, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final content = OverflowBox(
      minWidth: layout.contentWidth,
      maxWidth: layout.contentWidth,
      alignment: widget.alignment,
      child: widget.itemBuilder(context, index),
    );
    return RepaintBoundary(
        child: Padding(
      padding: const EdgeInsets.all(carouselItemInset),
      child: Material(
        clipBehavior: Clip.antiAlias,
        color: widget.backgroundColor ?? colorScheme.surface,
        shape: CardTheme.of(context).shape ?? _cardShape,
        child: Stack(
          fit: StackFit.expand,
          children: [
            LayoutBuilder(
              builder: (context, constraints) => _CarouselItemScope(
                visibleFraction: constraints.maxWidth / layout.contentWidth,
                child: content,
              ),
            ),
            InkWell(
              onTap: () => widget.onTap(index),
              hoverColor: Colors.transparent,
              overlayColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.pressed) ||
                        states.contains(WidgetState.focused)
                    ? colorScheme.onSurface
                        .withValues(alpha: _interactionOverlayOpacity)
                    : null,
              ),
            ),
          ],
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isRightToLeft = Directionality.of(context) == TextDirection.rtl;
    return LayoutBuilder(builder: (context, constraints) {
      final layout = _layout = CarouselLayout(
        availableWidth: constraints.maxWidth,
        itemCount: widget.itemCount,
        itemMinWidth: widget.itemMinWidth,
        itemMaxWidth: widget.itemMaxWidth,
      );
      return Align(
        alignment: widget.alignment,
        heightFactor: 1,
        child: SizedBox(
          width: layout.viewportWidth,
          height: widget.heightForItemWidth(layout.largeItemWidth),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Scrollable(
                axisDirection:
                    isRightToLeft ? AxisDirection.left : AxisDirection.right,
                controller: _controller,
                physics: _CarouselScrollPhysics(
                    itemExtent: () => _layout!.largeItemWidth),
                viewportBuilder: (context, offset) => _CarouselViewport(
                  offset: offset,
                  layout: layout,
                  children: [
                    for (var index = 0; index < widget.itemCount; index++)
                      _item(layout, index),
                  ],
                ),
              ),
              if (_showArrows && layout.scrolls) _arrows(layout),
            ],
          ),
        ),
      );
    });
  }
}
