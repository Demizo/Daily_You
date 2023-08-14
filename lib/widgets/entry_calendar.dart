import 'package:daily_you/config_manager.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/widgets/entry_day_cell.dart';
import 'package:table_calendar/table_calendar.dart';

class EntryCalendar extends StatefulWidget {
  const EntryCalendar({super.key});

  @override
  _EntryCalendarState createState() => _EntryCalendarState();
}

class _EntryCalendarState extends State<EntryCalendar> {
  late DateTime selectedDate = DateTime.now();
  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      availableCalendarFormats: const {CalendarFormat.month: 'Month'},
      focusedDay: selectedDate,
      lastDay: DateTime.now(),
      firstDay: DateTime.utc(2000),
      startingDayOfWeek:
          ConfigManager.instance.getField('startingDayOfWeek') == 'sunday'
              ? StartingDayOfWeek.sunday
              : StartingDayOfWeek.monday,
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, date, _) {
          return EntryDayCell(date: date);
        },
        selectedBuilder: (context, date, _) {
          return EntryDayCell(date: date);
        },
        todayBuilder: (context, date, _) {
          return EntryDayCell(date: date);
        },
      ),
      onHeaderTapped: (_) async {
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
    );
  }
}
