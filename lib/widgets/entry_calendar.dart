import 'package:flutter/material.dart';
import 'package:daily_you/widgets/entry_day_cell.dart';
import 'package:table_calendar/table_calendar.dart';

class EntryCalendar extends StatefulWidget {
  const EntryCalendar({super.key});

  @override
  _EntryCalendarState createState() => _EntryCalendarState();
}

class _EntryCalendarState extends State<EntryCalendar> {
  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      availableCalendarFormats: const {CalendarFormat.month: 'Month'},
      focusedDay: DateTime.now(),
      lastDay: DateTime.now(),
      firstDay: DateTime.utc(2000),
      // Customize other properties of the TableCalendar here, if needed
      calendarBuilders: CalendarBuilders(
        // Override the default day cell rendering with your custom widget
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
    );
  }
}
