// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/gallery_filter.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/utils/gallery_date_range.dart';
import 'package:daily_you/widgets/date_range_dialog.dart';
import 'package:daily_you/widgets/date_selection_label.dart';
import 'package:daily_you/widgets/gallery_filter_dialog.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

enum _DateChoice {
  lastMonth(1),
  lastSixMonths(6),
  calendarYear(null),
  customRange(null);

  const _DateChoice(this.months);

  final int? months;

  static _DateChoice? of(DateSelection selection) => switch (selection) {
        NoDateSelection() => null,
        LastMonthsSelection(:final months) =>
          values.where((choice) => choice.months == months).firstOrNull,
        CalendarYearSelection() => calendarYear,
        CustomRangeSelection() => customRange,
      };
}

class DateFilterDialog extends StatelessWidget {
  const DateFilterDialog({super.key});

  Future<void> _pickRange(
    BuildContext context,
    EntriesProvider provider,
  ) async {
    final today = DateTime.now();
    final selection = provider.filter.date;
    final dates = [
      for (final entry in provider.entries) entry.timeCreate,
      if (selection is CustomRangeSelection) ...[
        selection.start,
        selection.end
      ],
    ];
    final picked = await showDateRangeDialog(
      context,
      initialRange: selection is CustomRangeSelection
          ? DateTimeRange(start: selection.start, end: selection.end)
          : null,
      firstDate:
          dates.isEmpty ? today : dates.reduce((a, b) => a.isBefore(b) ? a : b),
      lastDate: dates.fold(today, (a, b) => a.isAfter(b) ? a : b),
    );
    if (picked == null) return;
    provider.filter = provider.filter.copyWith(
      date: CustomRangeSelection(picked.start, picked.end),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<EntriesProvider>();
    final filter = provider.filter;
    final isJalali = TimeManager.isJalaliCalendar(context);
    final years = calendarYearsOf(
      [for (final entry in provider.entries) entry.timeCreate],
      isJalali: isJalali,
    );
    final selection = filter.date;
    final choice = _DateChoice.of(selection);

    void select(_DateChoice? tapped) {
      if (tapped == null) return;
      final months = tapped.months;
      if (months != null) {
        provider.filter = filter.copyWith(
            date: LastMonthsSelection(months, isJalali: isJalali));
      } else if (tapped == _DateChoice.calendarYear) {
        provider.filter = filter.copyWith(
          date: CalendarYearSelection(years.first, isJalali: isJalali),
        );
      } else if (tapped == _DateChoice.customRange) {
        _pickRange(context, provider);
      }
    }

    return GalleryFilterDialog(
      title: l10n.sortDateTitle,
      canClear: filter.hasDate,
      onClear: () => provider.filter = filter.withoutDate(),
      content: RadioGroup<_DateChoice>(
        groupValue: choice,
        onChanged: (value) => select(
          value ?? (choice == _DateChoice.customRange ? choice : null),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final preset in _DateChoice.values.where(
              (choice) => choice.months != null,
            ))
              RadioListTile<_DateChoice>(
                value: preset,
                title: Text(l10n.dateFilterLastMonths(preset.months!)),
              ),
            if (years.length > 1)
              RadioListTile<_DateChoice>(
                value: _DateChoice.calendarYear,
                title: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Text(l10n.chartGroupingYear),
                    _YearDropdown(
                      years: years,
                      selectedYear: selection is CalendarYearSelection
                          ? selection.year
                          : years.first,
                      isJalali: isJalali,
                      onSelected: (year) => provider.filter = filter.copyWith(
                        date: CalendarYearSelection(year, isJalali: isJalali),
                      ),
                    ),
                  ],
                ),
              ),
            RadioListTile<_DateChoice>(
              value: _DateChoice.customRange,
              toggleable: true,
              title: Text(l10n.dateFilterCustomRange),
              subtitle: selection is CustomRangeSelection
                  ? Text(selection.label(context))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _YearDropdown extends StatelessWidget {
  const _YearDropdown({
    required this.years,
    required this.selectedYear,
    required this.isJalali,
    required this.onSelected,
  });

  final List<int> years;
  final int selectedYear;
  final bool isJalali;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.secondary;

    return PopupMenuButton<int>(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: onSelected,
      itemBuilder: (menuContext) => [
        for (final year in years)
          PopupMenuItem<int>(
            value: year,
            child: Row(
              children: [
                Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: year == selectedYear
                      ? Theme.of(menuContext).colorScheme.primary
                      : Colors.transparent,
                ),
                const SizedBox(width: 8),
                Text(calendarYearLabel(menuContext, year, isJalali: isJalali)),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: color.withValues(alpha: 0.12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              calendarYearLabel(context, selectedYear, isJalali: isJalali),
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: color),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 18, color: color),
          ],
        ),
      ),
    );
  }
}
