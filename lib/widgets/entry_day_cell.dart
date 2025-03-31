import 'package:daily_you/config_provider.dart';
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
    final configProvider = Provider.of<ConfigProvider>(context);

    var entries = statsProvider.entries
        .where((entry) => isSameDay(entry.timeCreate, date))
        .toList();
    Entry? entry = entries.isNotEmpty ? entries.first : null;

    EntryImage? image;
    if (entry != null) {
      var images = statsProvider.images
          .where((img) => img.entryId == entry.id!)
          .toList();
      image = images.isNotEmpty ? images.first : null;
    }

    bool showMood = configProvider.get(ConfigKey.calendarViewMode) == 'mood';

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
              builder: (context) => EntryDetailPage(
                index: statsProvider.getIndexOfEntry(entry.id!),
              ),
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
                    ? SizedBox(
                        height: 57,
                        child: Card(
                            clipBehavior: Clip.antiAlias,
                            child: LocalImageLoader(
                              imagePath: image.imgPath,
                              cacheSize: 100,
                            )),
                      )
                    : Icon(
                        size: 57,
                        Icons.image_rounded,
                        color: Theme.of(context).disabledColor.withOpacity(0.1),
                      ),
                Text('${date.day}',
                    style: image == null
                        ? TextStyle(
                            fontSize: 18,
                          )
                        : TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            shadows: [
                                Shadow(
                                    color: Colors.black.withOpacity(0.8),
                                    blurRadius: 6,
                                    offset: Offset(0, 0)),
                              ])),
              ],
            ),
          ),
          onTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => EntryDetailPage(
                  index: statsProvider.getIndexOfEntry(entry.id!)),
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
                    color: isSameDay(date, DateTime.now())
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).disabledColor,
                  ),
                ],
              ),
              Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSameDay(date, DateTime.now())
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: isSameDay(date, DateTime.now())
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
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
