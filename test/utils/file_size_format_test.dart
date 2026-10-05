// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/utils/file_size_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the largest whole unit', () {
    expect(formatFileSize(512, 'en'), '0.5 KB');
    expect(formatFileSize(1536, 'en'), '1.5 KB');
    expect(formatFileSize(5 * 1024 * 1024, 'en'), '5.0 MB');
    expect(formatFileSize(3 * 1024 * 1024 * 1024, 'en'), '3.0 GB');
  });

  test('formats the number for the locale', () {
    expect(formatFileSize(1536, 'de'), '1,5 KB');
  });

  test('falls back to English for a locale without number symbols', () {
    expect(formatFileSize(1536, 'oc'), '1.5 KB');
  });
}
