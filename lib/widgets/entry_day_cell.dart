import 'dart:ui' as ui;

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/pages/edit_entry_page.dart';
import 'package:daily_you/pages/entry_timeline_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/local_image_loader.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:daily_you/pages/entries_list_page.dart';

class EntryDayCell extends StatelessWidget {
  final DateTime date;
  final DateTime currentMonth;
  final ui.Image? dayNumber;
  final double cellSize;
  final List<Entry> entries;
  final EntryImage? firstImage;

  const EntryDayCell({
    super.key,
    required this.date,
    required this.currentMonth,
    required this.dayNumber,
    required this.cellSize,
    required this.entries,
    required this.firstImage,
  });

  String _countLabel(int count) => count > 99 ? '99+' : '$count';

  Widget _countBadge(BuildContext context, int count) {
    return Container(
      width: 23,
      height: 23,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _countLabel(count),
          textScaler: TextScaler.noScaling,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Future<void> _openTimeline(BuildContext context) async {
    final locale = TimeManager.currentLocale(context);
    final title = DateFormat.yMMMd(locale).format(date);
    await Navigator.of(context).push(MaterialPageRoute(
      allowSnapshotting: false,
      builder: (context) => EntryTimelinePage(
        header: title,
        getEntries: () => EntriesProvider.instance.entries
            .where((e) =>
                e.timeCreate.day == date.day &&
                e.timeCreate.month == date.month &&
                e.timeCreate.year == date.year)
            .toList()
            .reversed
            .toList(),
        labelBuilder: (e) => DateFormat.jm(locale).format(e.timeCreate),
      ),
    ));
  }

  Future<void> _showPopupMenu(
    BuildContext context,
    EntriesProvider entriesProvider,
  ) async {
    final locale = TimeManager.currentLocale(context);
    final formattedDate = DateFormat.yMMMd(locale).format(date);

    final hasOnThisDay = entriesProvider.entries.any((e) =>
        e.timeCreate.day == date.day &&
        e.timeCreate.month == date.month &&
        e.timeCreate.year != date.year);

    if (!context.mounted) return;

    // Get the RenderBox of the EntryDayCell
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    // Calculate the position representing the bottom edge of the cell
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(button.size.bottomLeft(Offset.zero),
            ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final result = await showMenu<String>(
      context: context,
      position: position,
      menuPadding: EdgeInsets.all(0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: [
        if (hasOnThisDay)
          PopupMenuItem<String>(
            value: 'on_this_day',
            child: Row(
              children: [
                Icon(Icons.history_rounded),
                SizedBox(width: 12),
                Text(AppLocalizations.of(context)!.flashbackOnThisDay),
              ],
            ),
          ),
        PopupMenuItem<String>(
          value: 'new_entry',
          child: Row(
            children: [
              const Icon(Icons.add_rounded),
              const SizedBox(width: 12),
              Text(formattedDate),
            ],
          ),
        ),
      ],
    );

    if (!context.mounted) return;

    if (result == 'on_this_day') {
      await Navigator.of(context).push(MaterialPageRoute(
        allowSnapshotting: false,
        builder: (context) => EntryTimelinePage(
          header: DateFormat.MMMd(locale).format(date),
          getEntries: () => entriesProvider.entries
              .where((e) =>
                  e.timeCreate.day == date.day &&
                  e.timeCreate.month == date.month &&
                  e.timeCreate.year == date.year)
              .toList()
              .reversed
              .toList(),
          labelBuilder: (e) => DateFormat.y(locale).format(e.timeCreate),
        ),
      ));
    } else if (result == 'new_entry') {
      await Navigator.of(context).push(MaterialPageRoute(
        allowSnapshotting: false,
        builder: (context) => AddEditEntryPage(
          overrideCreateDate: TimeManager.currentTimeOnDifferentDate(date)
              .copyWith(isUtc: false),
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstEntry = entries.firstOrNull;
    final entriesProvider = context.read<EntriesProvider>();
    final isMulti = entries.length > 1;

    if (entries.isNotEmpty) {
      return GestureDetector(
        onTap: () async {
          if (isMulti) {
            await _openTimeline(context);
          } else {
            await Navigator.of(context).push(MaterialPageRoute(
              allowSnapshotting: false,
              builder: (context) => EntriesListPage(
                  index: entriesProvider.getIndexOfEntry(firstEntry!.id!),
                  getEntries: () => entriesProvider.entries),
            ));
          }
        },
        onLongPress: () => _showPopupMenu(context, entriesProvider),
        child: SizedBox(
          width: cellSize,
          height: cellSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: cellSize,
                child: firstImage != null
                    ? Card(
                        elevation: 0,
                        margin: const EdgeInsets.all(2),
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8))),
                        clipBehavior: Clip.antiAlias,
                        child: LocalImageLoader(
                          imagePath: firstImage!.imgPath,
                          cacheSize: 100,
                        ))
                    : Card(
                        elevation: 0,
                        margin: const EdgeInsets.all(2),
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8))),
                        child: Center(
                          child: Text('${date.day}',
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer,
                                  fontSize: 16)),
                        ),
                      ),
              ),
              if (firstImage != null)
                RawImage(
                  image: dayNumber,
                ),
              Positioned(
                bottom: 0,
                right: 0,
                child: isMulti
                    ? _countBadge(context, entries.length)
                    : firstEntry!.mood != null
                        ? Container(
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
                                moodValue: firstEntry.mood,
                                size: 16,
                                allowScaling: false,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    } else {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () async {
          await Navigator.of(context).push(MaterialPageRoute(
            allowSnapshotting: false,
            builder: (context) => AddEditEntryPage(
              overrideCreateDate: TimeManager.currentTimeOnDifferentDate(date)
                  .copyWith(isUtc: false),
            ),
          ));
        },
        onLongPress: () => _showPopupMenu(context, entriesProvider),
        child: Card(
          elevation: 0,
          margin: const EdgeInsets.all(2),
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8))),
          child: Center(
            child: Text('${date.day}',
                style: TimeManager.isSameDay(date, DateTime.now())
                    ? TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary)
                    : const TextStyle(fontSize: 16)),
          ),
        ),
      );
    }
  }
}
