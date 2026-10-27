// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math' as math;

import 'package:daily_you/time_manager.dart';
import 'package:daily_you/utils/year_month_range.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

Future<DateTime?> showYearMonthPicker(
  BuildContext context, {
  DateTime? initialDate,
  bool isJalali = false,
}) {
  final locale = Localizations.localeOf(context).toString();
  final monthNames = List.generate(
      12,
      (index) => isJalali
          ? TimeManager.jalaliMonthName(index + 1, locale)
          : DateFormat.MMMM(locale).format(DateTime(2000, index + 1)));
  return showAppDialog<DateTime>(
    context: context,
    builder: (context) => _YearMonthPickerDialog(
      range: YearMonthRange(
        isJalali: isJalali,
        earliestDate: TimeManager.minEntryDate,
        latestDate: DateTime.now(),
      ),
      monthNames: monthNames,
      initialDate: initialDate ?? DateTime.now(),
    ),
  );
}

class _YearMonthPickerDialog extends StatefulWidget {
  const _YearMonthPickerDialog({
    required this.range,
    required this.monthNames,
    required this.initialDate,
  });

  final YearMonthRange range;
  final List<String> monthNames;
  final DateTime initialDate;

  @override
  State<_YearMonthPickerDialog> createState() => _YearMonthPickerDialogState();
}

class _YearMonthPickerDialogState extends State<_YearMonthPickerDialog> {
  late int _year;
  late int _month;
  bool _choosingYear = false;

  YearMonthRange get _range => widget.range;

  @override
  void initState() {
    super.initState();
    final initial = _range.clamp(widget.initialDate);
    _year = initial.year;
    _month = initial.month;
  }

  void _selectYear(int year) {
    setState(() {
      _year = year;
      _month = _range.clampMonth(year, _month);
      _choosingYear = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      content: SizedBox(
        width: 304,
        height: 296,
        child: Column(
          children: [
            TextButton.icon(
              onPressed: () => setState(() => _choosingYear = !_choosingYear),
              iconAlignment: IconAlignment.end,
              icon: Icon(_choosingYear
                  ? Icons.arrow_drop_up_rounded
                  : Icons.arrow_drop_down_rounded),
              label: Text(
                '$_year',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _choosingYear
                    ? _YearGrid(
                        key: const ValueKey('years'),
                        minYear: _range.earliest.year,
                        maxYear: _range.latest.year,
                        selectedYear: _year,
                        onSelected: _selectYear,
                      )
                    : _MonthGrid(
                        key: const ValueKey('months'),
                        monthNames: widget.monthNames,
                        selectedMonth: _month,
                        isEnabled: (month) =>
                            _range.isMonthEnabled(_year, month),
                        onSelected: (month) => setState(() => _month = month),
                      ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(localizations.cancelButtonLabel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _range.toDate(_year, _month)),
          child: Text(localizations.okButtonLabel),
        ),
      ],
    );
  }
}

const int _gridColumns = 3;
const double _gridCellHeight = 48;
const double _gridSpacing = 4;
const int _rowsAboveSelectedYear = 2;

const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: _gridColumns,
  mainAxisExtent: _gridCellHeight,
  mainAxisSpacing: _gridSpacing,
  crossAxisSpacing: _gridSpacing,
);

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    super.key,
    required this.monthNames,
    required this.selectedMonth,
    required this.isEnabled,
    required this.onSelected,
  });

  final List<String> monthNames;
  final int selectedMonth;
  final bool Function(int month) isEnabled;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: _gridDelegate,
      itemCount: monthNames.length,
      itemBuilder: (context, index) {
        final month = index + 1;
        return _GridCell(
          label: monthNames[index],
          isSelected: month == selectedMonth,
          onTap: isEnabled(month) ? () => onSelected(month) : null,
        );
      },
    );
  }
}

class _YearGrid extends StatefulWidget {
  const _YearGrid({
    super.key,
    required this.minYear,
    required this.maxYear,
    required this.selectedYear,
    required this.onSelected,
  });

  final int minYear;
  final int maxYear;
  final int selectedYear;
  final ValueChanged<int> onSelected;

  @override
  State<_YearGrid> createState() => _YearGridState();
}

class _YearGridState extends State<_YearGrid> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    final selectedRow = (widget.selectedYear - widget.minYear) ~/ _gridColumns;
    const rowStride = _gridCellHeight + _gridSpacing;
    _controller = ScrollController(
        initialScrollOffset:
            math.max(0, (selectedRow - _rowsAboveSelectedYear) * rowStride));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: _controller,
      gridDelegate: _gridDelegate,
      itemCount: widget.maxYear - widget.minYear + 1,
      itemBuilder: (context, index) {
        final year = widget.minYear + index;
        return _GridCell(
          label: '$year',
          isSelected: year == widget.selectedYear,
          isCurrent: year == widget.maxYear,
          onTap: () => widget.onSelected(year),
        );
      },
    );
  }
}

class _GridCell extends StatelessWidget {
  const _GridCell({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isCurrent = false,
  });

  final String label;
  final bool isSelected;
  final bool isCurrent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = onTap == null
        ? Theme.of(context).disabledColor
        : isSelected
            ? colors.onPrimary
            : isCurrent
                ? colors.primary
                : colors.onSurface;
    final shape = StadiumBorder(
      side: isCurrent && !isSelected
          ? BorderSide(color: colors.primary)
          : BorderSide.none,
    );
    return Material(
      color: isSelected ? colors.primary : Colors.transparent,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: foreground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
