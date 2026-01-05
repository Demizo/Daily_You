import 'dart:ui' as ui;

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/pages/edit_entry_page.dart';
import 'package:daily_you/pages/entry_detail_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/year_month_picker.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/widgets/entry_day_cell.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class EntryCalendar extends StatefulWidget {
  const EntryCalendar({super.key});

  @override
  State<EntryCalendar> createState() => _EntryCalendarState();
}

class _EntryCalendarState extends State<EntryCalendar>
    with AutomaticKeepAliveClientMixin {
  Map<int, ui.Image> dayNumberCache = {};
  bool dayNumberCacheCreated = false;
  double? _lastDpr;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final dpr = MediaQuery.of(context).devicePixelRatio;
    if (_lastDpr == dpr) return;

    _lastDpr = dpr;
    _createDayNumberCache(dpr);
  }

  @override
  bool get wantKeepAlive => true;

  Widget _disabledDay(DateTime date) {
    return Center(
      child: Text('${date.day}',
          style:
              TextStyle(fontSize: 16, color: Theme.of(context).disabledColor)),
    );
  }

  Future<ui.Image> _bakeDayNumber(String text, double dpr) async {
    // Entry day cells are 57x57
    const logicalSize = 57.0;
    final physicalSize = (logicalSize * dpr).ceil();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Scale canvas so text uses logical units
    canvas.scale(dpr, dpr);

    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 18,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.8),
              blurRadius: 6,
            )
          ],
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );

    painter.layout();
    painter.paint(
      canvas,
      Offset((logicalSize - painter.width) / 2,
          (logicalSize - painter.height) / 2),
    );

    return recorder.endRecording().toImage(physicalSize, physicalSize);
  }

  Future<void> _createDayNumberCache(double dpr) async {
    for (int i = 1; i < 32; i++) {
      dayNumberCache[i] = await _bakeDayNumber(i.toString(), dpr);
    }
    setState(() {
      dayNumberCacheCreated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final entriesProvider = Provider.of<EntriesProvider>(context);
    final configProvider = Provider.of<ConfigProvider>(context);
    final theme = Theme.of(context);
    return !dayNumberCacheCreated
        ? SizedBox()
        : TableCalendar(
            locale: TimeManager.currentLocale(context),
            rowHeight: 57,
            daysOfWeekHeight: 24,
            sixWeekMonthsEnforced: true,
            startingDayOfWeek: StartingDayOfWeek
                .values[configProvider.getFirstDayOfWeekIndex(context)],
            availableGestures: AvailableGestures.horizontalSwipe,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Month',
            },
            focusedDay: entriesProvider.selectedDate,
            lastDay: DateTime.now(),
            firstDay: DateTime.utc(2000),
            onPageChanged: (DateTime date) =>
                entriesProvider.selectedDate = date,
            headerStyle: HeaderStyle(
                leftChevronIcon: Icon(Icons.chevron_left,
                    color: theme.colorScheme.onSurfaceVariant),
                leftChevronPadding: EdgeInsets.all(8),
                leftChevronMargin: EdgeInsets.only(left: 8),
                rightChevronIcon: Icon(Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant),
                rightChevronPadding: EdgeInsets.all(8),
                rightChevronMargin: EdgeInsets.only(right: 8)),
            calendarBuilders: CalendarBuilders(dowBuilder: (context, date) {
              return FittedBox(
                fit: BoxFit.scaleDown,
                child: Center(
                  child: Text(
                    DateFormat("E", TimeManager.currentLocale(context))
                        .format(date)
                        .toString(),
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              );
            }, headerTitleBuilder: (context, date) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          onPressed: () async {
                            DateTime? pickedDate = await showDatePicker(
                              initialDatePickerMode: DatePickerMode.day,
                              context: context,
                              initialDate: entriesProvider.selectedDate,
                              firstDate: DateTime.utc(2000),
                              lastDate: DateTime.now(),
                            );
                            if (pickedDate != null) {
                              // Update now to jump to the selected day on the calendar
                              entriesProvider.setSelectedDate(pickedDate);

                              Entry? pickedEntry =
                                  entriesProvider.getEntryForDate(pickedDate);

                              if (pickedEntry != null) {
                                // Open entry
                                await Navigator.of(context)
                                    .push(MaterialPageRoute(
                                  allowSnapshotting: false,
                                  builder: (context) => EntryDetailPage(
                                      filtered: false,
                                      index: entriesProvider
                                          .getIndexOfEntry(pickedEntry.id!)),
                                ));
                              } else {
                                // Create new entry
                                await Navigator.of(context)
                                    .push(MaterialPageRoute(
                                  allowSnapshotting: false,
                                  builder: (context) => AddEditEntryPage(
                                    overrideCreateDate:
                                        TimeManager.currentTimeOnDifferentDate(
                                                pickedDate)
                                            .copyWith(isUtc: false),
                                  ),
                                ));
                              }
                            }
                          },
                          icon: SvgPicture.asset(
                            'assets/icons/calendar_event.svg',
                            colorFilter: ColorFilter.mode(
                                theme.colorScheme.onSurfaceVariant,
                                BlendMode.srcIn),
                            width: 24,
                            height: 24,
                          )),
                      GestureDetector(
                        child: Text(
                          DateFormat(
                                  "MMMM y", TimeManager.currentLocale(context))
                              .format(date)
                              .toString(),
                          style: const TextStyle(fontSize: 18),
                        ),
                        onTap: () async {
                          final selectedDate = await showYearMonthPicker(
                              context,
                              initialDate: entriesProvider.selectedDate);
                          if (selectedDate != null) {
                            // Update now to jump to the selected day on the calendar
                            entriesProvider.setSelectedDate(selectedDate);
                          }
                        },
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: Duration(milliseconds: 300),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                          final scaleAnimation = TweenSequence([
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

                          return ScaleTransition(
                            scale: scaleAnimation,
                            child: child,
                          );
                        },
                        child: (!TimeManager.isSameMonth(
                                entriesProvider.selectedDate, DateTime.now()))
                            ? IconButton(
                                key: ValueKey('todayButton'),
                                onPressed: () async {
                                  // Update now to jump to today on the calendar
                                  entriesProvider
                                      .setSelectedDate(DateTime.now());
                                },
                                icon: SvgPicture.asset(
                                  'assets/icons/calendar_latest.svg',
                                  colorFilter: ColorFilter.mode(
                                      theme.colorScheme.onSurfaceVariant,
                                      BlendMode.srcIn),
                                  width: 24,
                                  height: 24,
                                ))
                            : SizedBox.shrink(
                                key: ValueKey('empty')), // Empty widget
                      ),
                      const CalendarViewModeSelector(),
                    ],
                  )
                ],
              );
            }, defaultBuilder: (context, date, currentMonth) {
              return EntryDayCell(
                  date: date,
                  currentMonth: currentMonth,
                  dayNumber: dayNumberCache[date.day]!);
            }, selectedBuilder: (context, date, currentMonth) {
              return EntryDayCell(
                  date: date,
                  currentMonth: currentMonth,
                  dayNumber: dayNumberCache[date.day]!);
            }, todayBuilder: (context, date, currentMonth) {
              if (TimeManager.isSameMonth(date, currentMonth)) {
                return EntryDayCell(
                    date: date,
                    currentMonth: currentMonth,
                    dayNumber: dayNumberCache[date.day]!);
              } else {
                return _disabledDay(date);
              }
            }, disabledBuilder: (context, date, currentMonth) {
              return _disabledDay(date);
            }, outsideBuilder: (context, date, currentMonth) {
              return _disabledDay(date);
            }),
          );
  }
}

class CalendarViewModeSelector extends StatelessWidget {
  const CalendarViewModeSelector({
    super.key,
  });

  Future<void> setViewMode() async {
    String viewMode = ConfigProvider.instance.get(ConfigKey.calendarViewMode);
    bool showMood = viewMode == 'mood';
    viewMode = showMood ? 'image' : 'mood';
    await ConfigProvider.instance.set(ConfigKey.calendarViewMode, viewMode);
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<ConfigProvider>(context);
    return IconButton(
        onPressed: () async {
          await setViewMode();
        },
        icon: configProvider.get(ConfigKey.calendarViewMode) == "mood"
            ? const Icon(Icons.image_rounded)
            : const Icon(Icons.mood_rounded));
  }
}
