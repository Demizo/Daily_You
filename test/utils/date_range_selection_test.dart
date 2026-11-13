// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/utils/date_range_selection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final earlier = DateTime(2026, 3, 5);
  final later = DateTime(2026, 3, 20);

  test('starts empty', () {
    const selection = DateRangeSelection();

    expect(selection.range, isNull);
    expect(selection.isAwaitingEnd, isFalse);
    expect(selection.contains(earlier), isFalse);
  });

  test('the first tap selects one day and waits for the end', () {
    final selection = const DateRangeSelection().tap(earlier);

    expect(selection.range, DateTimeRange(start: earlier, end: earlier));
    expect(selection.isAwaitingEnd, isTrue);
  });

  test('a later second tap completes the range', () {
    final selection = const DateRangeSelection().tap(earlier).tap(later);

    expect(selection.range, DateTimeRange(start: earlier, end: later));
    expect(selection.isAwaitingEnd, isFalse);
  });

  test('an earlier second tap makes the earlier day the start', () {
    final selection = const DateRangeSelection().tap(later).tap(earlier);

    expect(selection.range, DateTimeRange(start: earlier, end: later));
    expect(selection.isAwaitingEnd, isFalse);
  });

  test('tapping the same day twice selects that single day', () {
    final selection = const DateRangeSelection().tap(earlier).tap(earlier);

    expect(selection.range, DateTimeRange(start: earlier, end: earlier));
    expect(selection.isAwaitingEnd, isFalse);
  });

  test('a tap after a complete range starts a new one', () {
    final selection =
        const DateRangeSelection().tap(earlier).tap(later).tap(later);

    expect(selection.range, DateTimeRange(start: later, end: later));
    expect(selection.isAwaitingEnd, isTrue);
  });

  test('contains covers both ends and the days between', () {
    final selection = const DateRangeSelection().tap(earlier).tap(later);

    expect(selection.contains(earlier), isTrue);
    expect(selection.contains(DateTime(2026, 3, 12)), isTrue);
    expect(selection.contains(later), isTrue);
    expect(selection.contains(DateTime(2026, 3, 4)), isFalse);
    expect(selection.contains(DateTime(2026, 3, 21)), isFalse);
  });
}
