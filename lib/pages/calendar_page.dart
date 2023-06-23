import 'package:flutter/material.dart';
import 'package:daily_you/entries_database.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/widgets/entry_calendar.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late Entry? todaysEntry;
  bool isLoading = false;
  String searchText = '';
  bool sortOrderAsc = true;

  @override
  void initState() {
    super.initState();
    todaysEntry = null;
    getToday();
  }

  @override
  void dispose() {
    EntriesDatabase.instance.close();

    super.dispose();
  }

  Future getToday() async {
    setState(() => isLoading = true);
    todaysEntry =
        await EntriesDatabase.instance.getEntryForDate(DateTime.now());
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          child: isLoading
              ? const CircularProgressIndicator()
              : buildEntries(context),
        ),
      );

  Widget buildEntries(BuildContext context) => const Center(
      child: SizedBox(height: 400, width: 400, child: EntryCalendar()));
}
