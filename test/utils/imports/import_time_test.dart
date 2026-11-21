// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/utils/imports/import_time.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/pinned_time_zone.dart';

void main() {
  usePinnedTimeZone();

  group('wallClockIn', () {
    test('reads the instant in the named time zone', () {
      final time =
          wallClockIn(DateTime.utc(2026, 11, 21, 5, 21, 20), 'America/Chicago');

      expect(time, DateTime(2026, 11, 20, 23, 21, 20));
      expect(time.isUtc, isFalse);
    });

    test('follows daylight saving time', () {
      final time = wallClockIn(DateTime.utc(2026, 7, 1, 12), 'America/Chicago');

      expect(time, DateTime(2026, 7, 1, 7));
    });

    test('falls back to the device time zone when the name is unknown', () {
      final instant = DateTime.utc(2026, 1, 2, 3);

      expect(wallClockIn(instant, 'Not/AZone'), instant.toLocal());
      expect(wallClockIn(instant, null), instant.toLocal());
    });
  });
}
