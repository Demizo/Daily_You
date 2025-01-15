import 'package:daily_you/config_manager.dart';
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
      rowHeight: 57,
      sixWeekMonthsEnforced: true,
      availableCalendarFormats: const {
        CalendarFormat.month: 'Month',
      },
      focusedDay: statsProvider.selectedDate,
      lastDay: DateTime.now(),
      firstDay: DateTime.utc(2000),
      startingDayOfWeek:
          ConfigManager.instance.getField('startingDayOfWeek') == 'sunday'
              ? StartingDayOfWeek.sunday
              : StartingDayOfWeek.monday,
      onPageChanged: (DateTime date) => statsProvider.selectedDate = date,
      calendarBuilders: CalendarBuilders(
        headerTitleBuilder: (context, date) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                child: Text(
                  DateFormat("MMMM y").format(date).toString(),
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
                  if (pickedDate != null && pickedDate != statsProvider.selectedDate) {
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
    String viewMode = ConfigManager.instance.getField('calendarViewMode');
    bool showMood = viewMode == 'mood';
    viewMode = showMood ? 'image' : 'mood';
    await ConfigManager.instance.setField('calendarViewMode', viewMode);
    await ConfigProvider.instance.updateConfig();
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<ConfigProvider>(context);
    return IconButton(
        onPressed: () async {
          await setViewMode();
        },
        icon: configProvider.calendarViewMode == "mood"
            ? const Icon(Icons.image_rounded)
            : const Icon(Icons.mood_rounded));
  }
}
