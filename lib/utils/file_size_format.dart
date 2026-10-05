// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:intl/intl.dart';

String formatFileSize(int bytes, String locale) {
  const kb = 1024;
  const mb = kb * 1024;
  const gb = mb * 1024;
  final (size, unit) = switch (bytes) {
    < mb => (bytes / kb, 'KB'),
    < gb => (bytes / mb, 'MB'),
    _ => (bytes / gb, 'GB'),
  };
  final number = NumberFormat.decimalPatternDigits(
      locale: Intl.verifiedLocale(locale, NumberFormat.localeExists,
          onFailure: (_) => 'en'),
      decimalDigits: 1);
  return '${number.format(size)} $unit';
}
