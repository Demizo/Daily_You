// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:material_ui/material_ui.dart';

class DateRangeSelection {
  const DateRangeSelection({this.range, this.isAwaitingEnd = false});

  final DateTimeRange? range;
  final bool isAwaitingEnd;

  bool contains(DateTime day) {
    final selected = range;
    return selected != null &&
        !day.isBefore(selected.start) &&
        !day.isAfter(selected.end);
  }

  DateRangeSelection tap(DateTime day) {
    final selected = range;
    if (!isAwaitingEnd || selected == null) {
      return DateRangeSelection(
        range: DateTimeRange(start: day, end: day),
        isAwaitingEnd: true,
      );
    }
    final anchor = selected.start;
    return DateRangeSelection(
      range: day.isBefore(anchor)
          ? DateTimeRange(start: day, end: anchor)
          : DateTimeRange(start: anchor, end: day),
    );
  }
}
