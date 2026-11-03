// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math';
import 'dart:ui';

const carouselItemInset = 4.0;
const _minimumPillWidth = 56.0;
const _widthTolerance = 0.95;
const _itemPositionTolerance = 1e-9;

class CarouselLayout {
  CarouselLayout._({
    required this.itemCount,
    required this.viewportWidth,
    required this.largeCount,
    required this.largeItemWidth,
    required this.pillWidth,
  });

  factory CarouselLayout({
    required double availableWidth,
    required int itemCount,
    required double itemMinWidth,
    required double itemMaxWidth,
  }) {
    if (itemCount <= 1 || itemCount * itemMinWidth <= availableWidth) {
      final viewportWidth = min(availableWidth, itemCount * itemMaxWidth);
      return CarouselLayout._(
        itemCount: itemCount,
        viewportWidth: viewportWidth,
        largeCount: itemCount,
        largeItemWidth: itemCount > 0 ? viewportWidth / itemCount : 0,
        pillWidth: 0,
      );
    }
    CarouselLayout withLargeCount(int largeCount) {
      var largeItemWidth = max(0.0,
          min(itemMaxWidth, (availableWidth - _minimumPillWidth) / largeCount));
      var pillWidth = availableWidth - largeCount * largeItemWidth;
      if (pillWidth > largeItemWidth) {
        largeItemWidth = availableWidth / (largeCount + 1);
        pillWidth = largeItemWidth;
      }
      return CarouselLayout._(
        itemCount: itemCount,
        viewportWidth: availableWidth,
        largeCount: largeCount,
        largeItemWidth: largeItemWidth,
        pillWidth: pillWidth,
      );
    }

    for (var largeCount =
            min((availableWidth / itemMaxWidth).ceil(), itemCount - 1);
        largeCount > 1;
        largeCount--) {
      final layout = withLargeCount(largeCount);
      if (layout.largeItemWidth >= itemMinWidth * _widthTolerance) {
        return layout;
      }
    }
    return withLargeCount(1);
  }

  final int itemCount;
  final double viewportWidth;
  final int largeCount;
  final double largeItemWidth;
  final double pillWidth;

  bool get scrolls => maxScrolledItems > 0;
  int get maxScrolledItems => pillWidth > 0 ? itemCount - largeCount : 0;
  double get contentWidth => largeItemWidth - 2 * carouselItemInset;
  double get maxPixels => maxScrolledItems * largeItemWidth;

  double scrolledItems(double pixels) =>
      largeItemWidth > 0 ? pixels / largeItemWidth : 0;

  List<double> itemWidths(double scrolledItems) {
    final position = scrolledItems.clamp(0.0, maxScrolledItems.toDouble());
    final restBefore = position.floor();
    final restAfter = min(restBefore + 1, maxScrolledItems);
    final progress = position - restBefore;
    return [
      for (var item = 0; item < itemCount; item++)
        lerpDouble(_restWidth(item, restBefore), _restWidth(item, restAfter),
            progress)!
    ];
  }

  double _leadingPillWidth(int rest) {
    if (rest == 0) return 0;
    return rest == maxScrolledItems ? pillWidth : pillWidth / 2;
  }

  double _restWidth(int item, int rest) {
    final slot = item - rest + 1;
    if (slot < 0 || slot > largeCount + 1) return 0;
    if (slot == 0) return _leadingPillWidth(rest);
    if (slot <= largeCount) return largeItemWidth;
    return pillWidth - _leadingPillWidth(rest);
  }

  static int flingTargetItem({
    required double scrolledItems,
    required double projectedItems,
    required double direction,
    required int maxScrolledItems,
  }) {
    final nearest = scrolledItems.roundToDouble();
    final position = (scrolledItems - nearest).abs() < _itemPositionTolerance
        ? nearest
        : scrolledItems;
    final item = projectedItems.round();
    final steppedItem = switch (direction) {
      > 0 => max(item, position.floor() + 1),
      < 0 => min(item, position.ceil() - 1),
      _ => position.round(),
    };
    return steppedItem.clamp(0, maxScrolledItems);
  }
}
