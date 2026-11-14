// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/utils/filter_selection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toggling adds a value that is not selected', () {
    expect(toggledSelection(const <int>{}, 2), {2});
    expect(toggledSelection(const {1}, 2), {1, 2});
  });

  test('toggling removes a value that is selected', () {
    expect(toggledSelection(const {1, 2}, 2), {1});
    expect(toggledSelection(const {2}, 2), isEmpty);
  });
}
