// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/utils/duration_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatDuration', () {
    test('pads seconds under ten', () {
      expect(formatDuration(const Duration(minutes: 1, seconds: 4)), '1:04');
    });

    test('does not pad minutes', () {
      expect(formatDuration(const Duration(minutes: 12, seconds: 34)), '12:34');
    });

    test('rolls seconds over into minutes', () {
      expect(formatDuration(const Duration(seconds: 125)), '2:05');
    });
  });
}
