import 'package:flutter/material.dart';
import 'package:daily_you/entries_database.dart';
import 'package:daily_you/widgets/mood_icon.dart';

import '../models/entry.dart';
import '../pages/edit_entry_page.dart';
import '../pages/entry_detail_page.dart';

class EntryDayCell extends StatefulWidget {
  final DateTime date;

  const EntryDayCell({super.key, required this.date});

  @override
  State<EntryDayCell> createState() => _EntryDayCellState();
}

class _EntryDayCellState extends State<EntryDayCell> {
  late Entry? entry;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    getDateEntry();
  }

  void getDateEntry() async {
    setState(() => isLoading = true);

    entry = await EntriesDatabase.instance.getEntryForDate(widget.date);

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Your custom widget for the day cell (e.g., background, decorations, etc.)
            // This could be an image, gradient, or any other widget you want to draw over the day cell.
            // Example:
            Column(
              children: [
                const SizedBox(
                  height: 16,
                ),
                isLoading
                    ? Icon(
                        Icons.add_rounded,
                        color: Theme.of(context).disabledColor,
                      )
                    : entry != null
                        ? MoodIcon(moodValue: entry!.mood)
                        : Icon(
                            Icons.add_rounded,
                            color: Theme.of(context).disabledColor,
                          ),
              ],
            ),

            // The default day number rendering
            Text(
              '${widget.date.day}',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      onTap: () async {
        if (!isLoading) {
          if (entry != null) {
            await Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => EntryDetailPage(entryId: entry!.id!),
            ));
          } else {
            var newEntry = await Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => AddEditEntryPage(
                overrideCreateDate: widget.date,
              ),
            ));

            if (newEntry != null) {
              getDateEntry();
            }
          }
          getDateEntry();
        }
      },
    );
  }
}
