import 'package:daily_you/models/image.dart';
import 'package:daily_you/time_manager.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'local_image_loader.dart';

class EntryCardWidget extends StatelessWidget {
  const EntryCardWidget({
    super.key,
    this.title,
    required this.entry,
    required this.images,
  });

  final Entry entry;
  final String? title;
  final List<EntryImage> images;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = DateFormat.yMMMd(TimeManager.currentLocale(context))
        .format(entry.timeCreate);
    return Stack(alignment: Alignment.bottomLeft, children: [
      Card(
        clipBehavior: Clip.antiAlias,
        surfaceTintColor: null,
        child: Container(
          constraints: const BoxConstraints.expand(),
          padding: const EdgeInsets.all(0),
          child: Stack(
              alignment: Alignment.topRight,
              clipBehavior: Clip.antiAlias,
              children: [
                (images.isNotEmpty)
                    ? Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                              child: ClipRect(
                                  child: LocalImageLoader(
                            imagePath: images.first.imgPath,
                          )))
                        ],
                      )
                    : (entry.text.isNotEmpty)
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Wrap(children: [
                              IgnorePointer(
                                  child: SizedBox(
                                width: double.maxFinite,
                                child: MarkdownBlock(
                                    config: theme.brightness == Brightness.light
                                        ? MarkdownConfig.defaultConfig
                                        : MarkdownConfig.darkConfig,
                                    data: entry.text),
                              ))
                            ]),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Center(
                                  child: Icon(
                                Icons.photo,
                                color: theme.disabledColor,
                                size: 90,
                              )),
                              Text(
                                'Empty Log',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.disabledColor),
                              ),
                            ],
                          ),
                if (images.length > 1)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.photo_library_rounded,
                      color: theme.disabledColor,
                    ),
                  ),
              ]),
        ),
      ),
      Card(
        clipBehavior: Clip.antiAlias,
        shadowColor: Colors.transparent,
        child: Padding(
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
      ),
    ]);
  }
}
