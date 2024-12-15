import 'package:daily_you/models/image.dart';
import 'package:daily_you/stats_provider.dart';
import 'package:daily_you/widgets/local_image_loader.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/entry.dart';
import '../pages/edit_entry_page.dart';
import '../pages/entry_detail_page.dart';

class EntryDayCell extends StatelessWidget {
  final DateTime date;

  const EntryDayCell({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final statsProvider = Provider.of<StatsProvider>(context);

    Entry? entry = StatsProvider.instance.entries
        .where((entry) => isSameDay(entry.timeCreate, date))
        .firstOrNull;

    EntryImage? image;
    if (entry != null) {
      image = statsProvider.images
          .where((img) => img.entryId == entry.id!)
          .firstOrNull;
    }

    bool showMood = statsProvider.calendarViewMode == 'mood';

    if (entry != null) {
      if (showMood) {
        return GestureDetector(
          child: Container(
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Column(
                  children: [
                    const SizedBox(
                      height: 20,
                    ),
                    MoodIcon(moodValue: entry.mood)
                  ],
                ),
                Text(
                  '${date.day}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          onTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => EntryDetailPage(entryId: entry.id!),
            ));
          },
        );
      } else {
        return GestureDetector(
          child: Container(
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                image != null
                    ? Expanded(
                        child: Card(
                            clipBehavior: Clip.antiAlias,
                            child: LocalImageLoader(imagePath: image.imgPath)),
                      )
                    : Icon(
                        size: 57,
                        Icons.image_rounded,
                        color: Theme.of(context).disabledColor.withOpacity(0.1),
                      ),
                Text(
                  '${date.day}',
                  style: TextStyle(fontSize: 18, shadows: [
                    if (image != null)
                      Shadow(
                          color: Theme.of(context).canvasColor.withOpacity(0.5),
                          blurRadius: 10,
                          offset: Offset(1, 1)),
                    if (image != null)
                      Shadow(
                          color: Theme.of(context).canvasColor.withOpacity(0.5),
                          blurRadius: 10,
                          offset: Offset(-1, -1)),
                    if (image != null)
                      Shadow(
                          color: Theme.of(context).canvasColor.withOpacity(0.5),
                          blurRadius: 10,
                          offset: Offset(1, -1)),
                    if (image != null)
                      Shadow(
                          color: Theme.of(context).canvasColor.withOpacity(0.5),
                          blurRadius: 10,
                          offset: Offset(-1, 1)),
                  ]),
                ),
              ],
            ),
          ),
          onTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => EntryDetailPage(entryId: entry.id!),
            ));
          },
        );
      }
    } else {
      return GestureDetector(
        child: Container(
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Column(
                children: [
                  const SizedBox(
                    height: 20,
                  ),
                  Icon(
                    Icons.add_rounded,
                    color: Theme.of(context).disabledColor,
                  ),
                ],
              ),
              Text(
                '${date.day}',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        onTap: () async {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => AddEditEntryPage(
              overrideCreateDate: date,
            ),
          ));
        },
      );
    }
  }
}
