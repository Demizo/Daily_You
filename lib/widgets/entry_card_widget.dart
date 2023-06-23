import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'local_image_loader.dart';

class EntryCardWidget extends StatelessWidget {
  const EntryCardWidget({
    Key? key,
    this.title,
    required this.entry,
  }) : super(key: key);

  final Entry entry;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = DateFormat.yMMMd().format(entry.timeCreate);
    return Stack(alignment: Alignment.bottomLeft, children: [
      Card(
        clipBehavior: Clip.antiAlias,
        color: theme.cardColor,
        surfaceTintColor: null,
        child: Container(
          constraints: const BoxConstraints.expand(),
          padding: const EdgeInsets.all(0),
          child: Stack(clipBehavior: Clip.antiAlias, children: [
            (entry.imgPath != null)
                ? Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                          child: ClipRect(
                              child: LocalImageLoader(
                        imagePath: entry.imgPath!,
                      )))
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                          child: Icon(
                        Icons.no_photography_rounded,
                        color: theme.disabledColor,
                        size: 90,
                      )),
                      Text(
                        'No Image',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.disabledColor),
                      ),
                    ],
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
              MoodIcon(
                moodValue: entry.mood,
              ),
            ],
          ),
        ),
      ),
    ]);
  }
}
