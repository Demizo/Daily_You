// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:intl/intl.dart';

String _numberLocale(String locale) => Intl.verifiedLocale(
      locale,
      NumberFormat.localeExists,
      onFailure: (_) => 'en',
    )!;

String formatCount(num value, String locale) =>
    NumberFormat.decimalPattern(_numberLocale(locale)).format(value);

String formatPercent(double fraction, String locale) =>
    NumberFormat.percentPattern(_numberLocale(locale)).format(fraction);

String formatDecimal(num value, String locale) =>
    NumberFormat('#,##0.#', _numberLocale(locale)).format(value);
