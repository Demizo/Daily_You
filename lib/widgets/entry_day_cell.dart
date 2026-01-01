import 'package:daily_you/config_provider.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
import 'package:daily_you/time_manager.dart';
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
  final DateTime currentMonth;

  const EntryDayCell(
      {super.key, required this.date, required this.currentMonth});

  @override
  Widget build(BuildContext context) {
    final entriesProvider = Provider.of<EntriesProvider>(context);
    final entryImagesProvider = Provider.of<EntryImagesProvider>(context);
    final configProvider = Provider.of<ConfigProvider>(context);

    Entry? entry = entriesProvider.getEntryForDate(date);

    EntryImage? image;
    if (entry != null) {
      image = entryImagesProvider.getForEntry(entry).firstOrNull;
    }

    bool showMood = configProvider.get(ConfigKey.calendarViewMode) == 'mood';

    if (entry != null) {
      if (showMood || image == null) {
        // Show mood
        return GestureDetector(
          child: SizedBox(
            width: 57,
            height: 57,
            child: Card(
              margin: EdgeInsets.all(2),
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainer,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8))),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${date.day}',
                    style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                  MoodIcon(moodValue: entry.mood)
                ],
              ),
            ),
          ),
          onTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(
              allowSnapshotting: false,
              builder: (context) => EntryDetailPage(
                filtered: false,
                index: entriesProvider.getIndexOfEntry(entry.id!),
              ),
            ));
          },
        );
      } else {
        // Show image
        return GestureDetector(
          child: Container(
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 57,
                  child: Card(
                      elevation: 0,
                      margin: EdgeInsets.all(2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8))),
                      clipBehavior: Clip.antiAlias,
                      child: LocalImageLoader(
                        imagePath: image.imgPath,
                        cacheSize: 100,
                      )),
                ),
                Text('${date.day}',
                    style:
                        TextStyle(fontSize: 18, color: Colors.white, shadows: [
                      Shadow(
                          color: Colors.black.withValues(alpha: 0.8),
                          blurRadius: 6,
                          offset: Offset(0, 0)),
                    ])),
              ],
            ),
          ),
          onTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(
              allowSnapshotting: false,
              builder: (context) => EntryDetailPage(
                  filtered: false,
                  index: entriesProvider.getIndexOfEntry(entry.id!)),
            ));
          },
        );
      }
    } else {
      // No entry
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        child: Center(
          child: Text('${date.day}',
              style: isSameDay(date, DateTime.now())
                  ? TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary)
                  : TextStyle(fontSize: 16)),
        ),
        onTap: () async {
          await Navigator.of(context).push(MaterialPageRoute(
            allowSnapshotting: false,
            builder: (context) => AddEditEntryPage(
              overrideCreateDate: TimeManager.currentTimeOnDifferentDate(date)
                  .copyWith(isUtc: false),
            ),
          ));
        },
      );
    }
  }
}
