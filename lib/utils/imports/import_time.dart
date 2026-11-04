// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

DateTime wallClockOf(DateTime shiftedUtc) => DateTime(
      shiftedUtc.year,
      shiftedUtc.month,
      shiftedUtc.day,
      shiftedUtc.hour,
      shiftedUtc.minute,
      shiftedUtc.second,
      shiftedUtc.millisecond,
      shiftedUtc.microsecond,
    );
