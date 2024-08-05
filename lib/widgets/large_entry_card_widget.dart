import 'package:daily_you/models/image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'local_image_loader.dart';

class LargeEntryCardWidget extends StatelessWidget {
  const LargeEntryCardWidget({
    super.key,
    this.title,
    required this.entry,
    this.image,
  });

  final Entry entry;
  final EntryImage? image;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = DateFormat.yMMMd().format(entry.timeCreate);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (image != null)
            Expanded(
                child: Center(
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: LocalImageLoader(
                    imagePath: image!.imgPath,
                  )),
            )),
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
                              "No text for this log...",
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
