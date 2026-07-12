import 'dart:ui' as ui;

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/pages/edit_entry_page.dart';
import 'package:daily_you/pages/entry_timeline_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/utils/tag_visuals.dart';
import 'package:daily_you/widgets/local_image_loader.dart';
import 'package:daily_you/widgets/tag_icon_glyph.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:provider/provider.dart';
import 'package:daily_you/pages/entries_list_page.dart';

class EntryDayCell extends StatelessWidget {
  final DateTime date;
  final DateTime today;
  final ui.Image? dayNumber;
  final double cellSize;
  final List<Entry> entries;
  final EntryImage? firstImage;

  final bool showImages;
  final bool showMood;
  final bool isJalali;
  final Tag? calendarTagOverride;
  final Map<int, EntryTag> calendarTagEntryMap;

  const EntryDayCell({
    super.key,
    required this.date,
    required this.today,
    required this.dayNumber,
    required this.cellSize,
    required this.entries,
    required this.firstImage,
    this.showImages = true,
    this.showMood = true,
    this.isJalali = false,
    this.calendarTagOverride,
    this.calendarTagEntryMap = const {},
  });

  Widget _buildTagIconGlyph(
      Tag tag, Color color, double emojiSize, double iconSize) {
    return SizedBox(
      width: iconSize,
      height: iconSize,
      child: Center(
        child: TagIconGlyph(
          icon: tag.icon,
          iconType: tag.iconType,
          fallbackIcon: tag.typeIcon,
          color: color,
          size: iconSize,
          characterSize: emojiSize,
        ),
      ),
    );
  }

  /// Renders [value] within [maxWidth] at [fontSize]
  Widget _buildFadedTrackerValue(
      String value, double maxWidth, double fontSize, Color color,
      {TextAlign align = TextAlign.left}) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Text(
        value,
        textAlign: align,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.fade,
        textScaler: TextScaler.noScaling,
        style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: color,
            height: 1.0),
      ),
    );
  }

  Widget _buildTagCutout(BuildContext context, Tag tag, EntryTag? entryTag,
      ColorScheme colorScheme,
      {bool iconOnly = false}) {
    final color = tag.resolvedColor(context, fallback: colorScheme.secondary);
    if (!iconOnly &&
        tag.tagType == TagType.tracker &&
        entryTag?.value != null) {
      return Container(
        height: 23,
        constraints: const BoxConstraints(minWidth: 23, maxWidth: 50),
        padding: const EdgeInsets.symmetric(horizontal: 5),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(11.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTagIconGlyph(tag, color, 10, 11),
            const SizedBox(width: 3),
            _buildFadedTrackerValue(entryTag!.value!, 24, 11, color),
          ],
        ),
      );
    }
    return Container(
      width: 23,
      height: 23,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        shape: BoxShape.circle,
      ),
      child: Center(child: _buildTagIconGlyph(tag, color, 13, 14)),
    );
  }

  Widget _buildTagCutoutCenter(BuildContext context, Tag tag,
      EntryTag? entryTag, ColorScheme colorScheme) {
    final color = tag.resolvedColor(context, fallback: colorScheme.secondary);
    if (tag.tagType == TagType.tracker && entryTag?.value != null) {
      return Container(
        height: 40,
        constraints: const BoxConstraints(minWidth: 40, maxWidth: 56),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: _buildFadedTrackerValue(entryTag!.value!, 36, 16, color,
            align: TextAlign.center),
      );
    }
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        shape: BoxShape.circle,
      ),
      child: Center(child: _buildTagIconGlyph(tag, color, 22, 26)),
    );
  }

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

  Future<void> _showPopupMenu(
    BuildContext context,
    EntriesProvider entriesProvider,
  ) async {
    final formattedDate = TimeManager.formatDate(date, context);

    final hasOnThisDay = entriesProvider.entries.any((entry) =>
        TimeManager.isOnThisDayMatch(entry.timeCreate, date, isJalali));

    if (!context.mounted) return;

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
          header: TimeManager.formatMonthDay(date, context),
          getEntries: () => entriesProvider.entries
              .where((entry) => TimeManager.isSameCalendarDayOfYear(
                  entry.timeCreate, date, isJalali))
              .toList()
              .reversed
              .toList(),
          labelBuilder: (entry) =>
              TimeManager.formatYear(entry.timeCreate, context),
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
    final colorScheme = Theme.of(context).colorScheme;
    final overrideEntryTag = calendarTagOverride != null && firstEntry != null
        ? calendarTagEntryMap[firstEntry.id]
        : null;
    final hasOverrideTag = overrideEntryTag != null;
    final tagGoesCenter = hasOverrideTag && !showImages && !showMood;
    final isTrackerOverride = calendarTagOverride?.tagType == TagType.tracker;
    final tagGoesCorner =
        hasOverrideTag && (!tagGoesCenter || isTrackerOverride);

    if (entries.isNotEmpty) {
      final showImageBg = showImages && firstImage != null;
      return MergeSemantics(
          child: GestureDetector(
        onTap: () async {
          if (isMulti) {
            await EntryTimelinePage.pushForDay(context, date);
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
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: showImageBg ? Clip.hardEdge : Clip.none,
                child: showImageBg
                    ? LocalImageLoader(
                        imagePath: firstImage!.imgPath,
                        cacheSize: 100,
                      )
                    : Center(
                        child: tagGoesCenter
                            ? _buildTagCutoutCenter(
                                context,
                                calendarTagOverride!,
                                overrideEntryTag,
                                colorScheme)
                            : !showImages &&
                                    showMood &&
                                    firstEntry?.mood != null
                                ? Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: MoodIcon(
                                        moodValue: firstEntry!.mood,
                                        size: 28,
                                        allowScaling: false,
                                      ),
                                    ),
                                  )
                                : Text(
                                    '${isJalali ? TimeManager.jalaliDayNumber(date) : date.day}',
                                    style: TextStyle(
                                        color: colorScheme.onSecondaryContainer,
                                        fontSize: 16)),
                      ),
              ),
              if (showImageBg)
                ExcludeSemantics(
                  child: RawImage(
                    image: dayNumber,
                  ),
                ),
              Positioned(
                bottom: 0,
                right: 0,
                child: isMulti
                    ? _countBadge(context, entries.length)
                    : showImages && showMood && firstEntry!.mood != null
                        ? Container(
                            width: 23,
                            height: 23,
                            decoration: BoxDecoration(
                              color: colorScheme.surface.withAlpha(255),
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
              Positioned(
                top: 0,
                right: 0,
                child: tagGoesCorner
                    ? _buildTagCutout(context, calendarTagOverride!,
                        overrideEntryTag, colorScheme,
                        iconOnly: tagGoesCenter)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ));
    } else {
      return MergeSemantics(
          child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                  allowSnapshotting: false,
                  builder: (context) => AddEditEntryPage(
                    overrideCreateDate:
                        TimeManager.currentTimeOnDifferentDate(date)
                            .copyWith(isUtc: false),
                  ),
                ));
              },
              onLongPress: () => _showPopupMenu(context, entriesProvider),
              child: SizedBox(
                width: cellSize,
                height: cellSize,
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                        '${isJalali ? TimeManager.jalaliDayNumber(date) : date.day}',
                        style: TimeManager.isSameDay(date, today)
                            ? TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary)
                            : const TextStyle(fontSize: 16)),
                  ),
                ),
              )));
    }
  }
}
