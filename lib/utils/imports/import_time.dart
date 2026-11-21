// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

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

bool _timeZonesLoaded = false;

DateTime wallClockIn(DateTime instant, String? timeZoneName) {
  final location = _locationNamed(timeZoneName);
  if (location == null) return instant.toLocal();
  return wallClockOf(timezone.TZDateTime.from(instant, location));
}

timezone.Location? _locationNamed(String? name) {
  if (name == null) return null;
  if (!_timeZonesLoaded) {
    timezone_data.initializeTimeZones();
    _timeZonesLoaded = true;
  }
  try {
    return timezone.getLocation(name);
  } on timezone.LocationNotFoundException {
    return null;
  }
}
