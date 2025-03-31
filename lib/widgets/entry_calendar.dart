import 'package:daily_you/config_provider.dart';
import 'package:daily_you/stats_provider.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/widgets/entry_day_cell.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class EntryCalendar extends StatelessWidget {
  const EntryCalendar({super.key});

  @override
  Widget build(BuildContext context) {
    final statsProvider = Provider.of<StatsProvider>(context);
    return TableCalendar(
      locale: WidgetsBinding.instance.platformDispatcher.locale.toString(),
      rowHeight: 57,
      sixWeekMonthsEnforced: true,
      startingDayOfWeek: StartingDayOfWeek
          .values[ConfigProvider.instance.getFirstDayOfWeekIndex()],
      availableGestures: AvailableGestures.horizontalSwipe,
      availableCalendarFormats: const {
        CalendarFormat.month: 'Month',
      },
      focusedDay: statsProvider.selectedDate,
      lastDay: DateTime.now(),
      firstDay: DateTime.utc(2000),
      onPageChanged: (DateTime date) => statsProvider.selectedDate = date,
      calendarBuilders: CalendarBuilders(
        headerTitleBuilder: (context, date) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                child: Text(
                  DateFormat(
                          "MMMM y",
                          WidgetsBinding.instance.platformDispatcher.locale
                              .toString())
                      .format(date)
                      .toString(),
                  style: const TextStyle(fontSize: 18),
                ),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    initialDatePickerMode: DatePickerMode.year,
                    context: context,
                    initialDate: statsProvider.selectedDate,
                    firstDate: DateTime.utc(2000),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null &&
                      pickedDate != statsProvider.selectedDate) {
                    statsProvider.selectedDate = pickedDate;
                    // Update now to jump to the selected day on the calendar
                    statsProvider.forceUpdate();
                  }
                },
              ),
              const CalendarViewModeSelector(),
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
