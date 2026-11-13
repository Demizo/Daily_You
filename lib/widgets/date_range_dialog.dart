// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/utils/date_range_selection.dart';
import 'package:daily_you/utils/year_month_range.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/year_month_picker.dart';
import 'package:material_ui/material_ui.dart';

Future<DateTimeRange?> showDateRangeDialog(
  BuildContext context, {
  DateTimeRange? initialRange,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  return showAppDialog<DateTimeRange>(
    context: context,
    builder: (context) => DateRangeDialog(
      initialRange: initialRange,
      firstDate: firstDate,
      lastDate: lastDate,
    ),
  );
}

DateTime _dayOf(DateTime date) => DateTime(date.year, date.month, date.day);

const double _dialogMaxWidth = 360;
const double _dayCellHeight = 44;
const int _weekRowCount = 6;
const int _daysPerWeek = 7;

class DateRangeDialog extends StatefulWidget {
  const DateRangeDialog({
    super.key,
    this.initialRange,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTimeRange? initialRange;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<DateRangeDialog> createState() => _DateRangeDialogState();
}

class _DateRangeDialogState extends State<DateRangeDialog> {
  late final DateTime _firstDay = _dayOf(widget.firstDate);
  late final DateTime _lastDay = _dayOf(widget.lastDate);
  late final YearMonthRange _months = YearMonthRange(
    isJalali: TimeManager.isJalaliCalendar(context),
    earliestDate: _firstDay,
    latestDate: _lastDay,
  );
  late final PageController _pageController = PageController(
    initialPage: _months.indexOf(widget.initialRange?.start ?? _lastDay),
  );
  late int _pageIndex = _pageController.initialPage;
  late DateRangeSelection _selection = DateRangeSelection(
    range: widget.initialRange == null
        ? null
        : DateTimeRange(
            start: _dayOf(widget.initialRange!.start),
            end: _dayOf(widget.initialRange!.end),
          ),
  );

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime get _visibleMonthStart {
    final month = _months.monthAt(_pageIndex);
    return _months.toDate(month.year, month.month);
  }

  bool _isSelectable(DateTime day) =>
      !day.isBefore(_firstDay) && !day.isAfter(_lastDay);

  void _goToPage(int index) => _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );

  Future<void> _pickMonth() async {
    final picked = await showYearMonthPicker(
      context,
      initialDate: _visibleMonthStart,
      isJalali: _months.isJalali,
    );
    if (picked == null) return;
    _pageController.jumpToPage(_months.indexOf(picked));
  }

  String _summary(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localizations = MaterialLocalizations.of(context);
    final range = _selection.range;
    final startText = range == null
        ? localizations.dateRangeStartLabel
        : TimeManager.formatDate(range.start, context);
    final endText = range == null || _selection.isAwaitingEnd
        ? localizations.dateRangeEndLabel
        : TimeManager.formatDate(range.end, context);
    return l10n.dateFilterRange(startText, endText);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = MaterialLocalizations.of(context);
    final firstWeekdayIndex =
        ConfigProvider.instance.getFirstDayOfWeekIndex(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _dialogMaxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.dateRangePickerHelpText,
                      style: textTheme.labelLarge
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Text(_summary(context), style: textTheme.titleLarge),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _pickMonth,
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.arrow_drop_down_rounded),
                    label: Text(
                      TimeManager.formatMonthYear(_visibleMonthStart, context),
                      style: textTheme.titleSmall,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: localizations.previousMonthTooltip,
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed:
                        _pageIndex > 0 ? () => _goToPage(_pageIndex - 1) : null,
                  ),
                  IconButton(
                    tooltip: localizations.nextMonthTooltip,
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: _pageIndex < _months.monthCount - 1
                        ? () => _goToPage(_pageIndex + 1)
                        : null,
                  ),
                ],
              ),
              _WeekdayHeader(firstWeekdayIndex: firstWeekdayIndex),
              SizedBox(
                height: _weekRowCount * _dayCellHeight,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _months.monthCount,
                  onPageChanged: (index) => setState(() => _pageIndex = index),
                  itemBuilder: (context, index) => _MonthPage(
                    months: _months,
                    month: _months.monthAt(index),
                    firstWeekdayIndex: firstWeekdayIndex,
                    selection: _selection,
                    isSelectable: _isSelectable,
                    onDayTapped: (day) =>
                        setState(() => _selection = _selection.tap(day)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(localizations.cancelButtonLabel),
                  ),
                  TextButton(
                    onPressed: _selection.range == null
                        ? null
                        : () => Navigator.pop(context, _selection.range),
                    child: Text(localizations.okButtonLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({required this.firstWeekdayIndex});

  final int firstWeekdayIndex;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
    return Row(
      children: [
        for (var column = 0; column < _daysPerWeek; column++)
          Expanded(
            child: Center(
              child: Text(
                TimeManager.formatNarrowWeekday(
                  (firstWeekdayIndex + column) % _daysPerWeek + 1,
                  context,
                ),
                style: style,
              ),
            ),
          ),
      ],
    );
  }
}

class _MonthPage extends StatelessWidget {
  const _MonthPage({
    required this.months,
    required this.month,
    required this.firstWeekdayIndex,
    required this.selection,
    required this.isSelectable,
    required this.onDayTapped,
  });

  final YearMonthRange months;
  final YearMonth month;
  final int firstWeekdayIndex;
  final DateRangeSelection selection;
  final bool Function(DateTime day) isSelectable;
  final ValueChanged<DateTime> onDayTapped;

  @override
  Widget build(BuildContext context) {
    final leadingBlanks = (months.toDate(month.year, month.month).weekday -
            1 -
            firstWeekdayIndex +
            _daysPerWeek) %
        _daysPerWeek;
    final dayCount = months.daysIn(month.year, month.month);
    final range = selection.range;
    final localizations = MaterialLocalizations.of(context);

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _daysPerWeek,
        mainAxisExtent: _dayCellHeight,
      ),
      itemCount: leadingBlanks + dayCount,
      itemBuilder: (context, index) {
        if (index < leadingBlanks) return const SizedBox.shrink();
        final dayNumber = index - leadingBlanks + 1;
        final day = months.toDate(month.year, month.month, dayNumber);
        return _DayCell(
          day: day,
          label: localizations.formatDecimal(dayNumber),
          isRangeStart: range != null && day == range.start,
          isRangeEnd: range != null && day == range.end,
          isInRange: selection.contains(day),
          onTap: isSelectable(day) ? () => onDayTapped(day) : null,
        );
      },
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.label,
    required this.isRangeStart,
    required this.isRangeEnd,
    required this.isInRange,
    required this.onTap,
  });

  final DateTime day;
  final String label;
  final bool isRangeStart;
  final bool isRangeEnd;
  final bool isInRange;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEndpoint = isRangeStart || isRangeEnd;
    final isSingleDay = isRangeStart && isRangeEnd;
    final isToday = TimeManager.isToday(day);
    final foreground = onTap == null
        ? colorScheme.onSurface.withValues(alpha: 0.38)
        : isEndpoint
            ? colorScheme.onPrimary
            : isInRange
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurface;

    return Semantics(
      button: true,
      enabled: onTap != null,
      selected: isInRange,
      label: TimeManager.formatDateWithWeekday(day, context),
      excludeSemantics: true,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isInRange && !isSingleDay)
            Positioned.fill(
              top: 2,
              bottom: 2,
              child: FractionallySizedBox(
                widthFactor: isEndpoint ? 0.5 : 1,
                alignment: isRangeStart
                    ? AlignmentDirectional.centerEnd
                    : AlignmentDirectional.centerStart,
                child: ColoredBox(color: colorScheme.primaryContainer),
              ),
            ),
          Material(
            color: isEndpoint ? colorScheme.primary : Colors.transparent,
            shape: CircleBorder(
              side: isToday && !isEndpoint
                  ? BorderSide(color: colorScheme.primary)
                  : BorderSide.none,
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox.square(
                dimension: _dayCellHeight - 4,
                child: Center(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: foreground,
                          fontWeight:
                              isEndpoint ? FontWeight.w600 : FontWeight.normal,
                        ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
