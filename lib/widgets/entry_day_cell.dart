import 'package:daily_you/config_provider.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
import 'package:daily_you/providers/selection_provider.dart';
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

  Future<void> _handleTap(
    BuildContext context,
    Entry? entry,
    bool isSelectionMode,
    SelectionProvider selectionProvider,
    EntriesProvider entriesProvider,
  ) async {
    if (isSelectionMode) {
      // Toggle selection instead of navigating
      selectionProvider.toggleDate(date);
    } else {
      // Existing navigation logic
      if (entry != null) {
        await Navigator.of(context).push(MaterialPageRoute(
          allowSnapshotting: false,
          builder: (context) => EntryDetailPage(
            filtered: false,
            index: entriesProvider.getIndexOfEntry(entry.id!),
          ),
        ));
      } else {
        await Navigator.of(context).push(MaterialPageRoute(
          allowSnapshotting: false,
          builder: (context) => AddEditEntryPage(
            overrideCreateDate: TimeManager.currentTimeOnDifferentDate(date)
                .copyWith(isUtc: false),
          ),
        ));
      }
    }
  }

  Widget _wrapWithSelection(
    BuildContext context,
    Widget cellContent,
    bool isSelected,
  ) {
    if (isSelected) {
      return Stack(
        children: [
          cellContent,
          // Color overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          // Checkmark icon
          Positioned(
            top: 2,
            right: 2,
            child: Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
        ],
      );
    }
    return cellContent;
  }

  @override
  Widget build(BuildContext context) {
    final entriesProvider = Provider.of<EntriesProvider>(context);
    final entryImagesProvider = Provider.of<EntryImagesProvider>(context);
    final configProvider = Provider.of<ConfigProvider>(context);
    final selectionProvider = Provider.of<SelectionProvider>(context);

    Entry? entry = entriesProvider.getEntryForDate(date);
    bool isSelected = selectionProvider.isSelected(date);
    bool isSelectionMode = selectionProvider.isSelectionMode;

    EntryImage? image;
    if (entry != null) {
      image = entryImagesProvider.getForEntry(entry).firstOrNull;
    }

    bool showMood = configProvider.get(ConfigKey.calendarViewMode) == 'mood';

    Widget cellContent;

    if (entry != null) {
      if (showMood || image == null) {
        // Show mood
        cellContent = FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${date.day}',
                style: const TextStyle(fontSize: 16),
              ),
              MoodIcon(moodValue: entry.mood)
            ],
          ),
        );
      } else {
        // Show image
        cellContent = Container(
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 57,
                child: Card(
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
        );
      }
    } else {
      // No entry
      cellContent = Center(
        child: Text('${date.day}',
            style: isSameDay(date, DateTime.now())
                ? TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary)
                : TextStyle(fontSize: 16)),
      );
    }

    // Wrap with selection overlay if selected
    cellContent = _wrapWithSelection(context, cellContent, isSelected);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () =>
          _handleTap(context, entry, isSelectionMode, selectionProvider, entriesProvider),
      onLongPress: () => selectionProvider.toggleDate(date),
      child: cellContent,
    );
  }
}
