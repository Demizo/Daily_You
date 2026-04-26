import 'dart:ui' as ui;

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/pages/edit_entry_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/local_image_loader.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:daily_you/pages/entries_list_page.dart';

class EntryDayCell extends StatelessWidget {
  final DateTime date;
  final DateTime currentMonth;
  final ui.Image? dayNumber;

  const EntryDayCell(
      {super.key,
      required this.date,
      required this.currentMonth,
      required this.dayNumber});

  @override
  Widget build(BuildContext context) {
    final entry = context.select<EntriesProvider, Entry?>(
        (p) => p.getEntryForDate(date));
    final showMood = context.select<ConfigProvider, bool>(
        (p) => p.get(ConfigKey.calendarViewMode) == 'mood');
    final firstImage = entry == null
        ? null
        : context.select<EntryImagesProvider, EntryImage?>(
            (p) => p.getFirstImageForEntry(entry.id!));

    final entriesProvider = context.read<EntriesProvider>();

    if (entry != null) {
      if (showMood || firstImage == null) {
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
                  MoodIcon(
                    moodValue: entry.mood,
                    allowScaling: false,
                  )
                ],
              ),
            ),
          ),
          onTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(
              allowSnapshotting: false,
              builder: (context) => EntriesListPage(
                index: entriesProvider.getIndexOfEntry(entry.id!),
                getEntries: () => entriesProvider.entries,
              ),
            ));
          },
        );
      } else {
        return GestureDetector(
          child: SizedBox(
            width: 57,
            height: 57,
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
                        imagePath: firstImage.imgPath,
                        cacheSize: 100,
                      )),
                ),
                // Use number with baked in shadow. The Impeller renderer stutters with text shadows
                RawImage(
                  image: dayNumber,
                ),
                if (entry.mood != null)
                  Positioned(
                    bottom: 1,
                    right: 1,
                    child: Container(
                      width: 23,
                      height: 23,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surface
                            .withAlpha(255),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: MoodIcon(
                          moodValue: entry.mood,
                          size: 16,
                          allowScaling: false,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          onTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(
              allowSnapshotting: false,
              builder: (context) => EntriesListPage(
                  index: entriesProvider.getIndexOfEntry(entry.id!),
                  getEntries: () => entriesProvider.entries),
            ));
          },
        );
      }
    } else {
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
