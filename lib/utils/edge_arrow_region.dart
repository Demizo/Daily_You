// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:ui';

const double edgeArrowRegionWidth = 120;
const double edgeArrowRegionTipWidth = 8;

bool isInEdgeArrowRegion({
  required Offset position,
  required bool leftSide,
  required Size size,
  required double topInset,
}) {
  final height = size.height - topInset;
  if (height <= 0 || position.dy < topInset || position.dy > size.height) {
    return false;
  }
  final halfHeight = height / 2;
  final middle = topInset + halfHeight;
  final closeness = 1 - (position.dy - middle).abs() / halfHeight;
  final width = edgeArrowRegionTipWidth +
      (edgeArrowRegionWidth - edgeArrowRegionTipWidth) * closeness;
  final distanceFromEdge = leftSide ? position.dx : size.width - position.dx;
  return distanceFromEdge >= 0 && distanceFromEdge <= width;
}
