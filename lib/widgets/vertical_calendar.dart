import 'dart:ui' as ui;

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/pages/entries_list_page.dart';
import 'package:daily_you/pages/entry_timeline_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/entry_day_cell.dart';
import 'package:daily_you/widgets/year_month_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

sealed class _CalendarItem {
  const _CalendarItem();
}

final class _MonthHeaderItem extends _CalendarItem {
  final DateTime month;
  const _MonthHeaderItem(this.month);
}

final class _WeekRowItem extends _CalendarItem {
  final List<DateTime?> days;
  const _WeekRowItem(this.days);
}

class VerticalCalendar extends StatefulWidget {
  final ScrollController scrollController;

  const VerticalCalendar({super.key, required this.scrollController});

  @override
  State<VerticalCalendar> createState() => _VerticalCalendarState();
}

class _VerticalCalendarState extends State<VerticalCalendar>
    with AutomaticKeepAliveClientMixin {
  static const double _daysOfWeekRowHeight = 32.0;

  double _weekRowHeight = 57.0;
  double _todayOffset = 0.0;

  Map<int, ui.Image> _dayNumberCache = {};
  double? _lastDpr;
  double _lastWeekRowHeight = 0.0;
  int _cacheGeneration = 0;

  bool _initialScrollDone = false;

  List<_CalendarItem> _items = [];
  List<(double, DateTime)> _monthOffsets = [];

  final _showTodayButton = ValueNotifier<bool>(false);
  DateTime _visibleMonth = DateTime.now();
  String _cachedLocale = '';

  int? _lastFirstDayIndex;
  double _cellWidth = 0;
  List<String> _dayLabels = [];

  final DateTime _firstDate = DateTime(2000, 1, 1);
  late final DateTime _lastDate =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  final DateTime _today =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final configProvider = Provider.of<ConfigProvider>(context, listen: false);
    final firstDayIndex = configProvider.getFirstDayOfWeekIndex(context);
    final newLocale = TimeManager.currentLocale(context);

    final firstDayChanged = firstDayIndex != _lastFirstDayIndex;
    final localeChanged = newLocale != _cachedLocale;
    _cachedLocale = newLocale;

    if (firstDayChanged) {
      _lastFirstDayIndex = firstDayIndex;
      _buildCalendarItems(firstDayIndex);
      _visibleMonth = DateTime.now();
    }

    if (firstDayChanged || localeChanged) {
      final allLabels = TimeManager.daysOfWeekLabels(context);
      _dayLabels = [
        ...allLabels.sublist(firstDayIndex),
        ...allLabels.sublist(0, firstDayIndex),
      ];
    }
  }

  @override
  void dispose() {
    _showTodayButton.dispose();
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  Future<ui.Image> _bakeDayNumber(
      String text, double dpr, double logicalSize) async {
    final physicalSize = (logicalSize * dpr).ceil();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(dpr, dpr);

    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 18,
          color: Colors.white,
          shadows: [
            Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 6),
          ],
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      Offset(
        (logicalSize - painter.width) / 2,
        (logicalSize - painter.height) / 2,
      ),
    );

    return recorder.endRecording().toImage(physicalSize, physicalSize);
  }

  Future<void> _createDayNumberCache(double dpr) async {
    final generation = ++_cacheGeneration;
    final logicalSize = _weekRowHeight;
    final cache = <int, ui.Image>{};
    for (int i = 1; i <= 31; i++) {
      cache[i] = await _bakeDayNumber(i.toString(), dpr, logicalSize);
    }
    if (!mounted || generation != _cacheGeneration) return;
    setState(() => _dayNumberCache = cache);
  }

  void _buildCalendarItems(int firstDayIndex) {
    final firstDayDart = firstDayIndex == 6 ? 7 : firstDayIndex + 1;

    final items = <_CalendarItem>[];
    final monthOffsets = <(double, DateTime)>[];
    double offset = 0;

    DateTime current = DateTime(_lastDate.year, _lastDate.month, 1);
    final end = DateTime(_firstDate.year, _firstDate.month, 1);

    while (!current.isBefore(end)) {
      monthOffsets.add((offset, current));

      // Day 0 is the last day of the previous month.
      final lastDayOfMonth = DateTime(current.year, current.month + 1, 0);

      // Find the start of the last week
      final daysFromWeekStart = (lastDayOfMonth.weekday - firstDayDart + 7) % 7;

      // Use constructor to subtract days to avoid DST drifts
      DateTime weekIter = DateTime(
        lastDayOfMonth.year,
        lastDayOfMonth.month,
        lastDayOfMonth.day - daysFromWeekStart,
      );

      // Find the start of the first week of this month
      final daysBeforeFirst = (current.weekday - firstDayDart + 7) % 7;

      DateTime firstWeekStart = DateTime(
        current.year,
        current.month,
        current.day - daysBeforeFirst,
      );

      // Iterate backwards from the last week to the first week
      while (!weekIter.isBefore(firstWeekStart)) {
        final days = List<DateTime?>.generate(7, (i) {
          final day = DateTime(weekIter.year, weekIter.month, weekIter.day + i);

          return (day.month == current.month && day.year == current.year)
              ? day
              : null;
        });

        // Save the offset for the current day
        if (current.year == _today.year && current.month == _today.month) {
          if (days.any((d) => d != null && d.day == _today.day)) {
            _todayOffset = (offset -= _weekRowHeight).clamp(0, double.infinity);
          }
        }

        items.add(_WeekRowItem(days));
        offset += _weekRowHeight;

        weekIter = DateTime(weekIter.year, weekIter.month, weekIter.day - 7);
      }

      items.add(_MonthHeaderItem(current));
      offset += _weekRowHeight;

      current = DateTime(current.year, current.month - 1, 1);
    }

    _items = items;
    _monthOffsets = monthOffsets;
  }

  void _scrollToToday({bool animate = true}) {
    if (!widget.scrollController.hasClients) return;
    if (animate) {
      widget.scrollController.animateTo(
        _todayOffset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      widget.scrollController.jumpTo(_todayOffset);
    }
    _updateVisibleMonthFromOffset(_todayOffset);
  }

  void _jumpToMonth(DateTime month) {
    if (!widget.scrollController.hasClients) return;
    final entry = _monthOffsets
        .where((e) => e.$2.year == month.year && e.$2.month == month.month)
        .firstOrNull;
    if (entry == null) return;
    _jumpToOffsetIteratively(entry.$1);
  }

  void _jumpToOffsetIteratively(double target, [double? previousMaxExtent]) {
    if (!mounted || !widget.scrollController.hasClients) return;
    final clamped =
        target.clamp(0.0, widget.scrollController.position.maxScrollExtent);
    widget.scrollController.jumpTo(clamped);

    if (widget.scrollController.offset < target - 1.0) {
      final currentMax = widget.scrollController.position.maxScrollExtent;
      if (previousMaxExtent != null && currentMax <= previousMaxExtent) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _jumpToOffsetIteratively(target, currentMax);
      });
    }
  }

  void _onScroll() {
    final offset = widget.scrollController.offset;
    final showToday = (offset - _todayOffset).abs() > _weekRowHeight * 12;
    if (_showTodayButton.value != showToday) {
      _showTodayButton.value = showToday;
    }
    _updateVisibleMonthFromOffset(offset);
  }

  void _updateVisibleMonthFromOffset(double offset) {
    if (_monthOffsets.isEmpty) return;
    // Binary search for current month
    int lo = 0, hi = _monthOffsets.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (_monthOffsets[mid].$1 > offset) {
        hi = mid - 1;
      } else {
        lo = mid;
      }
    }
    _visibleMonth = _monthOffsets[lo].$2;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final firstDayIndex =
        context.watch<ConfigProvider>().getFirstDayOfWeekIndex(context);
    final entriesProvider = context.watch<EntriesProvider>();
    final imagesProvider = context.watch<EntryImagesProvider>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final newCellWidth = constraints.maxWidth / 7;
        if (newCellWidth != _cellWidth) {
          _cellWidth = newCellWidth;
          _weekRowHeight = newCellWidth;
          _buildCalendarItems(firstDayIndex);
        }

        final dpr = MediaQuery.devicePixelRatioOf(context);
        if (_lastDpr != dpr || _lastWeekRowHeight != _weekRowHeight) {
          _lastDpr = dpr;
          _lastWeekRowHeight = _weekRowHeight;
          _createDayNumberCache(dpr);
        }

        if (!_initialScrollDone) {
          _initialScrollDone = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (widget.scrollController.hasClients) {
              widget.scrollController.jumpTo(_todayOffset);
            }
          });
        }

        return Stack(
            fit: StackFit.loose,
            alignment: AlignmentDirectional.bottomCenter,
            children: [
              Column(
                children: [
                  _buildWeekdayHeader(context, _dayLabels),
                  Expanded(
                    child: CustomScrollView(
                      controller: widget.scrollController,
                      reverse: true,
                      slivers: [
                        const SliverPadding(
                            padding: EdgeInsets.only(bottom: 85)),
                        SliverFixedExtentList(
                          itemExtent: _weekRowHeight,
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildItem(context, index,
                                entriesProvider, imagesProvider),
                            childCount: _items.length,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              _buildCalendarControls(context),
              _buildJumpToTodayButton(context),
            ]);
      },
    );
  }

  Widget _buildWeekdayHeader(BuildContext context, List<String> dayLabels) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
      ),
      child: SizedBox(
        height: _daysOfWeekRowHeight,
        child: Row(
          children: dayLabels.map((label) {
            return Expanded(
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCalendarControls(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 1,
            margin: EdgeInsets.all(0),
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(80))),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _onMonthLabelTap(context),
                  icon: const Icon(Icons.calendar_month_rounded),
                  color: theme.colorScheme.primary,
                  padding: const EdgeInsets.all(8),
                ),
                IconButton(
                  onPressed: () => _onCalendarIconTap(context),
                  icon: Icon(Icons.event_rounded),
                  color: theme.colorScheme.primary,
                  padding: const EdgeInsets.all(8),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJumpToTodayButton(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 13.0),
        child: ValueListenableBuilder<bool>(
          valueListenable: _showTodayButton,
          builder: (context, showToday, _) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              final scale = TweenSequence([
                TweenSequenceItem(
                  tween: Tween<double>(begin: 0.0, end: 1.1)
                      .chain(CurveTween(curve: Curves.easeOut)),
                  weight: 50,
                ),
                TweenSequenceItem(
                  tween: Tween<double>(begin: 1.1, end: 1.0)
                      .chain(CurveTween(curve: Curves.easeIn)),
                  weight: 50,
                ),
              ]).animate(animation);
              return ScaleTransition(scale: scale, child: child);
            },
            child: showToday
                ? IconButton(
                    color: theme.colorScheme.primary,
                    key: const ValueKey('todayBtn'),
                    onPressed: () => _scrollToToday(),
                    icon: Icon(Icons.arrow_downward_rounded),
                    style: IconButton.styleFrom(
                        elevation: 1,
                        shadowColor: theme.shadowColor,
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer),
                  )
                : const SizedBox.shrink(key: ValueKey('noBtn')),
          ),
        ),
      ),
    );
  }

  Future<void> _openTimeline(BuildContext context, DateTime date) async {
    final locale = TimeManager.currentLocale(context);
    final title = DateFormat.yMMMd(locale).format(date);
    await Navigator.of(context).push(MaterialPageRoute(
      allowSnapshotting: false,
      builder: (context) => EntryTimelinePage(
        header: title,
        getEntries: () => EntriesProvider.instance.entries
            .where((e) =>
                e.timeCreate.day == date.day &&
                e.timeCreate.month == date.month &&
                e.timeCreate.year == date.year)
            .toList()
            .reversed
            .toList(),
        labelBuilder: (e) => DateFormat.jm(locale).format(e.timeCreate),
      ),
    ));
  }

  Future<void> _onCalendarIconTap(BuildContext context) async {
    final entriesProvider = context.read<EntriesProvider>();
    final DateTime? picked = await showDatePicker(
      context: context,
      selectableDayPredicate: (date) {
        if (entriesProvider.entries.isEmpty) return true;
        return entriesProvider.getEntryForDate(date) != null;
      },
      initialDatePickerMode: DatePickerMode.day,
      initialDate: entriesProvider.entries.isNotEmpty
          ? entriesProvider.entries.first.timeCreate
          : DateTime.now(),
      firstDate: _firstDate,
      lastDate: DateTime.now(),
    );

    if (picked == null || !mounted) return;
    _jumpToMonth(picked);

    final List<Entry> entries = entriesProvider.getEntriesForDate(picked);
    if (!context.mounted) return;

    if (entries.isNotEmpty) {
      if (entries.length == 1) {
        await Navigator.of(context).push(MaterialPageRoute(
          allowSnapshotting: false,
          builder: (context) => EntriesListPage(
            index: entriesProvider.getIndexOfEntry(entries.first.id!),
            getEntries: () => entriesProvider.entries,
          ),
        ));
      } else {
        _openTimeline(context, picked);
      }
    }
  }

  Future<void> _onMonthLabelTap(BuildContext context) async {
    final DateTime? selected =
        await showYearMonthPicker(context, initialDate: _visibleMonth);
    if (selected == null) return;
    _jumpToMonth(selected);
  }

  Widget _buildItem(BuildContext context, int index,
      EntriesProvider entriesProvider, EntryImagesProvider imagesProvider) {
    final item = _items[index];
    if (item is _MonthHeaderItem) return _buildMonthHeader(context, item.month);
    if (item is _WeekRowItem) {
      return _buildWeekRow(context, item, entriesProvider, imagesProvider);
    }
    return const SizedBox.shrink();
  }

  Widget _buildMonthHeader(BuildContext context, DateTime month) {
    return SizedBox(
      height: _weekRowHeight,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: _daysOfWeekRowHeight,
          margin: const EdgeInsets.only(bottom: 2.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(14),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Center(
            child: Text(
              DateFormat('MMMM y', _cachedLocale).format(month),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeekRow(BuildContext context, _WeekRowItem item,
      EntriesProvider entriesProvider, EntryImagesProvider imagesProvider) {
    return RepaintBoundary(
      child: _WeekRow(
        days: item.days,
        today: _today,
        cellSize: _cellWidth,
        dayNumberCache: _dayNumberCache,
        entriesProvider: entriesProvider,
        imagesProvider: imagesProvider,
      ),
    );
  }
}

class _WeekRow extends StatelessWidget {
  final List<DateTime?> days;
  final DateTime today;
  final double cellSize;
  final Map<int, ui.Image> dayNumberCache;
  final EntriesProvider entriesProvider;
  final EntryImagesProvider imagesProvider;

  const _WeekRow({
    required this.days,
    required this.today,
    required this.cellSize,
    required this.dayNumberCache,
    required this.entriesProvider,
    required this.imagesProvider,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: cellSize,
      child: Row(
        children: days.map((day) {
          if (day == null) {
            return SizedBox(
              width: cellSize,
              height: cellSize,
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }

          final isFuture =
              day.isAfter(today) && !TimeManager.isSameDay(day, today);
          if (isFuture) {
            return SizedBox(
              width: cellSize,
              height: cellSize,
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                        fontSize: 16, color: Theme.of(context).disabledColor),
                  ),
                ),
              ),
            );
          }

          final entries = entriesProvider.getEntriesForDate(day);
          final firstEntry = entries.firstOrNull;
          final firstImage = firstEntry == null
              ? null
              : imagesProvider.getFirstImageForEntry(firstEntry.id!);

          return SizedBox(
            width: cellSize,
            height: cellSize,
            child: EntryDayCell(
              date: day,
              today: today,
              entries: entries,
              firstImage: firstImage,
              cellSize: cellSize,
              dayNumber: dayNumberCache[day.day],
            ),
          );
        }).toList(),
      ),
    );
  }
}
