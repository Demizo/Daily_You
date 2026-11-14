// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/gallery_filter.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/utils/gallery_date_range.dart';
import 'package:material_ui/material_ui.dart';

String calendarYearLabel(BuildContext context, int year,
        {required bool isJalali}) =>
    TimeManager.formatYear(firstDayOfYear(year, isJalali: isJalali), context);

extension DateSelectionLabel on DateSelection {
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (this) {
      NoDateSelection() => l10n.sortDateTitle,
      LastMonthsSelection(:final months) => l10n.dateFilterLastMonths(months),
      CalendarYearSelection(:final year, :final isJalali) =>
        calendarYearLabel(context, year, isJalali: isJalali),
      CustomRangeSelection(:final start, :final end) => l10n.dateFilterRange(
          TimeManager.formatDate(start, context),
          TimeManager.formatDate(end, context),
        ),
    };
  }
}
