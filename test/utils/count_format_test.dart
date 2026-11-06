// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/utils/count_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('groups thousands for the locale', () {
    expect(formatCount(62110, 'en'), '62,110');
    expect(formatCount(62110, 'de'), '62.110');
  });

  test('formats a fraction as a whole percent', () {
    expect(formatPercent(0.85, 'en'), '85%');
    expect(formatPercent(1, 'en'), '100%');
    expect(formatPercent(0, 'en'), '0%');
  });

  test('keeps at most one decimal', () {
    expect(formatDecimal(7.25, 'en'), '7.3');
    expect(formatDecimal(9, 'en'), '9');
    expect(formatDecimal(1234.5, 'de'), '1.234,5');
  });

  test('falls back to English grouping for an unknown locale', () {
    expect(formatCount(1234, 'xx'), '1,234');
  });
}
