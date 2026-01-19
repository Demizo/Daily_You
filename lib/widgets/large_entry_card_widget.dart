import 'package:daily_you/models/image.dart';
import 'package:daily_you/time_manager.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'local_image_loader.dart';

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
                child: Stack(
                    fit: StackFit.expand,
                    alignment: Alignment.topRight,
                    children: [
                  ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LocalImageLoader(
                        imagePath: images.first.imgPath,
                      )),
                  if (images.length > 1)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.photo_library_rounded,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                blurRadius: 6,
                                offset: Offset(0, 0)),
                          ],
                        ),
                      ),
                    ),
                ])),
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
                          ? MarkdownBlock(
                              config: theme.brightness == Brightness.light
                                  ? MarkdownConfig.defaultConfig
                                  : MarkdownConfig.darkConfig,
                              data: entry.text)
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
