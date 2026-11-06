// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/utils/chart_bar_width.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the maximum width when there is room', () {
    expect(
      chartBarWidth(plotWidth: 300, barCount: 5),
      chartMaximumBarWidth,
    );
  });

  test('leaves the gap between adjacent bars when space is tight', () {
    const plotWidth = 250.0;
    const barCount = 10;
    final width = chartBarWidth(plotWidth: plotWidth, barCount: barCount);

    expect(width, plotWidth / barCount - chartBarGap);
    expect(plotWidth - width * barCount, barCount * chartBarGap);
  });

  test('never collapses a bar to nothing', () {
    expect(chartBarWidth(plotWidth: 20, barCount: 10), greaterThan(0));
  });
}
