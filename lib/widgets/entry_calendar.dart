import 'package:daily_you/config_manager.dart';
import 'package:daily_you/stats_provider.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/widgets/entry_day_cell.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class EntryCalendar extends StatefulWidget {
  const EntryCalendar({super.key});

  @override
  _EntryCalendarState createState() => _EntryCalendarState();
}

class _EntryCalendarState extends State<EntryCalendar> {
  late DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TableCalendar(
          rowHeight: 57,
          sixWeekMonthsEnforced: true,
          availableCalendarFormats: const {
            CalendarFormat.month: 'Month',
          },
          focusedDay: selectedDate,
          lastDay: DateTime.now(),
          firstDay: DateTime.utc(2000),
          startingDayOfWeek:
              ConfigManager.instance.getField('startingDayOfWeek') == 'sunday'
                  ? StartingDayOfWeek.sunday
                  : StartingDayOfWeek.monday,
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
                        initialDate: selectedDate,
                        firstDate: DateTime.utc(2000),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null && pickedDate != selectedDate) {
                        setState(() {
                          selectedDate = pickedDate;
                        });
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
        ),
      ],
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
    await StatsProvider.instance.updateStats();
  }

  @override
  Widget build(BuildContext context) {
    final statsProvider = Provider.of<StatsProvider>(context);
    return IconButton(
        onPressed: () async {
          await setViewMode();
        },
        icon: statsProvider.calendarViewMode == "mood"
            ? const Icon(Icons.image_rounded)
            : const Icon(Icons.mood_rounded));
  }
}
