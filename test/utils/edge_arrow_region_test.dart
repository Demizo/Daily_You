// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:ui';

import 'package:daily_you/utils/edge_arrow_region.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const size = Size(1000, 656);
  const topInset = 56.0;
  const middleY = 356.0;

  bool inside(Offset position, {required bool leftSide}) => isInEdgeArrowRegion(
        position: position,
        leftSide: leftSide,
        size: size,
        topInset: topInset,
      );

  test('the middle is as wide as the full region', () {
    expect(inside(const Offset(110, middleY), leftSide: true), isTrue);
    expect(inside(const Offset(130, middleY), leftSide: true), isFalse);
    expect(inside(const Offset(890, middleY), leftSide: false), isTrue);
    expect(inside(const Offset(870, middleY), leftSide: false), isFalse);
  });

  test('the region narrows toward the top', () {
    expect(inside(const Offset(40, topInset + 10), leftSide: true), isFalse);
    expect(inside(const Offset(4, topInset + 10), leftSide: true), isTrue);
    expect(inside(const Offset(960, topInset + 10), leftSide: false), isFalse);
    expect(inside(const Offset(996, topInset + 10), leftSide: false), isTrue);
  });

  test('the region narrows toward the bottom', () {
    expect(inside(Offset(40, size.height - 10), leftSide: true), isFalse);
    expect(inside(Offset(4, size.height - 10), leftSide: true), isTrue);
    expect(inside(Offset(960, size.height - 10), leftSide: false), isFalse);
    expect(inside(Offset(996, size.height - 10), leftSide: false), isTrue);
  });

  test('halfway up is halfway between the tip and the full width', () {
    final quarterHeight = topInset + (size.height - topInset) / 4;
    expect(inside(Offset(60, quarterHeight), leftSide: true), isTrue);
    expect(inside(Offset(70, quarterHeight), leftSide: true), isFalse);
  });

  test('outside the content area is never inside', () {
    expect(inside(const Offset(2, topInset - 1), leftSide: true), isFalse);
    expect(inside(const Offset(2, 20), leftSide: true), isFalse);
    expect(inside(Offset(2, size.height + 1), leftSide: true), isFalse);
    expect(inside(const Offset(998, 20), leftSide: false), isFalse);
  });

  test('a side only covers its own edge', () {
    expect(inside(const Offset(20, middleY), leftSide: false), isFalse);
    expect(inside(const Offset(980, middleY), leftSide: true), isFalse);
  });

  test('a content area with no height has no region', () {
    expect(
      isInEdgeArrowRegion(
        position: const Offset(2, 56),
        leftSide: true,
        size: const Size(1000, 56),
        topInset: 56,
      ),
      isFalse,
    );
  });
}
