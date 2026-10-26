// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/utils/carousel_layout.dart';
import 'package:flutter_test/flutter_test.dart';

CarouselLayout layoutFor({
  required double availableWidth,
  required int itemCount,
  double itemMinWidth = 140,
  double itemMaxWidth = 280,
}) =>
    CarouselLayout(
      availableWidth: availableWidth,
      itemCount: itemCount,
      itemMinWidth: itemMinWidth,
      itemMaxWidth: itemMaxWidth,
    );

double sum(List<double> values) => values.fold(0.0, (a, b) => a + b);

void main() {
  group('items that all fit', () {
    test('split the available width without scrolling', () {
      final layout = layoutFor(availableWidth: 400, itemCount: 2);

      expect(layout.scrolls, isFalse);
      expect(layout.viewportWidth, 400);
      expect(layout.largeItemWidth, 200);
      expect(layout.contentWidth, 200 - 2 * carouselItemInset);
      expect(layout.itemWidths(0), [200, 200]);
    });

    test('stop growing at the maximum item width', () {
      final layout = layoutFor(availableWidth: 800, itemCount: 2);

      expect(layout.viewportWidth, 560);
      expect(layout.largeItemWidth, 280);
    });

    test('a single item is capped at the maximum width', () {
      expect(layoutFor(availableWidth: 800, itemCount: 1).viewportWidth, 280);
      expect(layoutFor(availableWidth: 200, itemCount: 1).viewportWidth, 200);
    });
  });

  group('items that overflow', () {
    test('scroll with a pill beside the large items', () {
      final layout = layoutFor(availableWidth: 400, itemCount: 5);

      expect(layout.scrolls, isTrue);
      expect(layout.viewportWidth, 400);
      expect(layout.largeCount, 2);
      expect(layout.maxScrolledItems, 3);
      expect(layout.pillWidth, closeTo(400 - 2 * layout.largeItemWidth, 0.001));
      expect(layout.pillWidth, greaterThanOrEqualTo(56));
    });

    test('keep large items between the minimum and maximum width', () {
      for (final availableWidth in [320.0, 400.0, 600.0, 1000.0, 1600.0]) {
        final layout = layoutFor(availableWidth: availableWidth, itemCount: 12);

        expect(layout.largeItemWidth, greaterThanOrEqualTo(140 * 0.95));
        expect(layout.largeItemWidth, lessThanOrEqualTo(280 + 0.001));
      }
    });

    test('fall back to one large item when the width is narrow', () {
      final layout = layoutFor(availableWidth: 200, itemCount: 5);

      expect(layout.scrolls, isTrue);
      expect(layout.largeCount, 1);
      expect(layout.pillWidth, lessThanOrEqualTo(layout.largeItemWidth));
    });

    test(
        'fixed-size items stay close to their size and never get a larger pill',
        () {
      for (var availableWidth = 320.0;
          availableWidth <= 1200;
          availableWidth += 8) {
        final layout = layoutFor(
            availableWidth: availableWidth,
            itemCount: 8,
            itemMinWidth: 168,
            itemMaxWidth: 168);

        expect(layout.pillWidth, lessThanOrEqualTo(layout.largeItemWidth),
            reason: 'width $availableWidth');
        if (availableWidth >= 390) {
          expect(layout.largeItemWidth, closeTo(168, 168 * 0.1),
              reason: 'width $availableWidth');
        }
      }
    });
  });

  group('itemWidths', () {
    final layout = layoutFor(availableWidth: 400, itemCount: 6);

    test('start with the large items and a trailing pill', () {
      final widths = layout.itemWidths(0);

      expect(widths.sublist(0, layout.largeCount),
          everyElement(layout.largeItemWidth));
      expect(widths[layout.largeCount], closeTo(layout.pillWidth, 0.001));
      expect(widths.sublist(layout.largeCount + 1), everyElement(0));
    });

    test('end with a leading pill and the large items', () {
      final widths = layout.itemWidths(layout.maxScrolledItems.toDouble());
      final first = layout.itemCount - layout.largeCount - 1;

      expect(widths[first], closeTo(layout.pillWidth, 0.001));
      expect(widths.sublist(first + 1), everyElement(layout.largeItemWidth));
      expect(widths.sublist(0, first), everyElement(0));
    });

    test('split the pill between both sides in the middle', () {
      final widths = layout.itemWidths(1);

      expect(widths[0], closeTo(layout.pillWidth / 2, 0.001));
      expect(widths[1], layout.largeItemWidth);
      expect(
          widths[1 + layout.largeCount], closeTo(layout.pillWidth / 2, 0.001));
    });

    test('always fill the viewport exactly', () {
      for (var scrolled = 0.0;
          scrolled <= layout.maxScrolledItems;
          scrolled += 0.125) {
        expect(sum(layout.itemWidths(scrolled)), closeTo(400, 0.001),
            reason: 'scrolled $scrolled');
      }
    });

    test('never exceed the viewport or go negative', () {
      for (var scrolled = 0.0;
          scrolled <= layout.maxScrolledItems;
          scrolled += 0.125) {
        for (final width in layout.itemWidths(scrolled)) {
          expect(width, inInclusiveRange(0, layout.largeItemWidth));
        }
      }
    });

    test('shrink the leaving item to nothing', () {
      expect(layout.itemWidths(1.5)[0], closeTo(layout.pillWidth / 4, 0.001));
      expect(layout.itemWidths(2)[0], 0);
    });

    test('clamp positions beyond the ends', () {
      expect(layout.itemWidths(-1), layout.itemWidths(0));
      expect(layout.itemWidths(99),
          layout.itemWidths(layout.maxScrolledItems.toDouble()));
    });
  });

  group('scroll metrics', () {
    final layout = layoutFor(availableWidth: 400, itemCount: 5);

    test('one item scrolls by the width of a large item', () {
      expect(
          layout.scrolledItems(layout.largeItemWidth * 2), closeTo(2, 0.001));
    });

    test('maxPixels spans every item scrolled past the large ones', () {
      expect(layout.maxPixels,
          closeTo(layout.maxScrolledItems * layout.largeItemWidth, 0.001));
    });

    test('nothing scrolls when every item fits', () {
      final fitting = layoutFor(availableWidth: 400, itemCount: 2);

      expect(fitting.maxPixels, 0);
      expect(fitting.scrolledItems(0), 0);
    });
  });

  group('flingTargetItem', () {
    int target(double scrolled, double projected, double direction) =>
        CarouselLayout.flingTargetItem(
            scrolledItems: scrolled,
            projectedItems: projected,
            direction: direction,
            maxScrolledItems: 7);

    test('settles on the nearest item without velocity', () {
      expect(target(2.4, 2.4, 0), 2);
      expect(target(2.6, 2.6, 0), 3);
    });

    test('snaps to the item nearest where the fling coasts to', () {
      expect(target(2, 4.4, 1), 4);
      expect(target(2, 4.6, 1), 5);
      expect(target(5, 2.6, -1), 3);
    });

    test('advances at least one item in the fling direction', () {
      expect(target(2, 2.1, 1), 3);
      expect(target(2.6, 2.7, 1), 3);
      expect(target(2, 1.9, -1), 1);
      expect(target(2.4, 2.3, -1), 2);
    });

    test('treats a position within rounding error of an item as at rest', () {
      expect(target(2 - 1e-12, 2.1, 1), 3);
      expect(target(2 + 1e-12, 1.9, -1), 1);
    });

    test('stays within the scrollable items', () {
      expect(target(1, -4, -1), 0);
      expect(target(6, 40, 1), 7);
    });
  });
}
