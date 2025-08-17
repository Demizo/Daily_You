import 'package:daily_you/config_provider.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/pages/edit_entry_page.dart';
import 'package:daily_you/pages/entry_detail_page.dart';
import 'package:daily_you/stats_provider.dart';
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
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final statsProvider = Provider.of<StatsProvider>(context);
    return TableCalendar(
      locale: TimeManager.currentLocale(context),
      rowHeight: 57,
      sixWeekMonthsEnforced: true,
      startingDayOfWeek: StartingDayOfWeek
          .values[ConfigProvider.instance.getFirstDayOfWeekIndex(context)],
      availableGestures: AvailableGestures.horizontalSwipe,
      availableCalendarFormats: const {
        CalendarFormat.month: 'Month',
      },
      focusedDay: statsProvider.selectedDate,
      lastDay: DateTime.now(),
      firstDay: DateTime.utc(2000),
      onPageChanged: (DateTime date) => statsProvider.selectedDate = date,
      headerStyle: HeaderStyle(
          leftChevronPadding: EdgeInsets.all(8),
          leftChevronMargin: EdgeInsets.only(left: 8),
          rightChevronPadding: EdgeInsets.all(8),
          rightChevronMargin: EdgeInsets.only(right: 8)),
      calendarBuilders: CalendarBuilders(
        headerTitleBuilder: (context, date) {
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
                          initialDate: statsProvider.selectedDate,
                          firstDate: DateTime.utc(2000),
                          lastDate: DateTime.now(),
                        );
                        if (pickedDate != null) {
                          statsProvider.selectedDate = pickedDate;
                          // Update now to jump to the selected day on the calendar
                          statsProvider.forceUpdate();

                          Entry? pickedEntry =
                              statsProvider.getEntryForDate(pickedDate);

                          if (pickedEntry != null) {
                            // Open entry
                            await Navigator.of(context).push(MaterialPageRoute(
                              allowSnapshotting: false,
                              builder: (context) => EntryDetailPage(
                                  filtered: false,
                                  index: statsProvider
                                      .getIndexOfEntry(pickedEntry.id!)),
                            ));
                          } else {
                            // Create new entry
                            await Navigator.of(context).push(MaterialPageRoute(
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
                            Theme.of(context).colorScheme.onSurfaceVariant,
                            BlendMode.srcIn),
                        width: 24,
                        height: 24,
                      )),
                  GestureDetector(
                    child: Text(
                      DateFormat("MMMM y", TimeManager.currentLocale(context))
                          .format(date)
                          .toString(),
                      style: const TextStyle(fontSize: 18),
                    ),
                    onTap: () async {
                      final selectedDate = await showYearMonthPicker(context,
                          initialDate: statsProvider.selectedDate);
                      if (selectedDate != null) {
                        statsProvider.selectedDate = selectedDate;
                        // Update now to jump to the selected day on the calendar
                        statsProvider.forceUpdate();
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
                            statsProvider.selectedDate, DateTime.now()))
                        ? IconButton(
                            key: ValueKey('todayButton'),
                            onPressed: () async {
                              statsProvider.selectedDate = DateTime.now();
                              // Update now to jump to today on the calendar
                              statsProvider.forceUpdate();
                            },
                            icon: SvgPicture.asset(
                              'assets/icons/calendar_latest.svg',
                              colorFilter: ColorFilter.mode(
                                  Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
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
        },
        defaultBuilder: (context, date, _) {
          return EntryDayCell(
            date: date,
          );
        },
        selectedBuilder: (context, date, _) {
          return EntryDayCell(
            date: date,
          );
        },
        todayBuilder: (context, date, _) {
          return EntryDayCell(
            date: date,
          );
        },
      ),
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
