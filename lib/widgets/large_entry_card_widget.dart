import 'package:daily_you/models/image.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/image_grid.dart';
import 'package:daily_you/widgets/scaled_markdown.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/widgets/mood_icon.dart';

class LargeEntryCardWidget extends StatelessWidget {
  const LargeEntryCardWidget(
      {super.key,
      this.title,
      required this.entry,
      required this.images,
      this.hideImage = false});

  final Entry entry;
  final List<EntryImage> images;
  final String? title;
  final bool hideImage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = DateFormat.yMMMd(TimeManager.currentLocale(context))
        .format(entry.timeCreate);
    return Card.filled(
      color: Theme.of(context).colorScheme.surfaceContainer,
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (images.isNotEmpty && !hideImage)
            Expanded(
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ImageGrid(images: images))),
          Expanded(
            child: Wrap(children: [
              Padding(
                padding: const EdgeInsets.all(2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Text(
                        title == null ? time : title!,
                        style: TextStyle(
                            color: theme.textTheme.labelSmall?.color,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      constraints: const BoxConstraints(minWidth: 16),
                      child: MoodIcon(
                        moodValue: entry.mood,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                child: Wrap(children: [
                  IgnorePointer(
                      child: (entry.text.isNotEmpty)
                          ? ScaledMarkdown(data: entry.text)
                          : Text(
                              AppLocalizations.of(context)!.writeSomethingHint,
                              style: TextStyle(
                                  color: theme.disabledColor, fontSize: 16),
                            ))
                ]),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
