import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/image_grid.dart';
import 'package:daily_you/widgets/scaled_markdown.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/widgets/mood_icon.dart';

class EntryCardWidget extends StatelessWidget {
  const EntryCardWidget(
      {super.key,
      this.title,
      required this.entry,
      required this.images,
      this.hideImage = false});

  final Entry entry;
  final String? title;
  final List<EntryImage> images;
  final bool hideImage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = DateFormat.yMMMd(TimeManager.currentLocale(context))
        .format(entry.timeCreate);
    return Card.filled(
      color: Theme.of(context).colorScheme.surfaceContainer,
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: (images.isNotEmpty && !hideImage)
                  ? ImageGrid(images: images)
                  : (entry.text.isNotEmpty)
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Wrap(children: [
                            IgnorePointer(
                                child: SizedBox(
                              width: double.maxFinite,
                              child: ScaledMarkdown(data: entry.text),
                            ))
                          ]),
                        )
                      : Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            AppLocalizations.of(context)!.writeSomethingHint,
                            style: TextStyle(
                                color: theme.disabledColor, fontSize: 16),
                          ),
                        ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  title == null ? time : title!,
                  style: TextStyle(
                      color: theme.textTheme.labelSmall?.color,
                      fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 16),
                  child: MoodIcon(
                    moodValue: entry.mood,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
