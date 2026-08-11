import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/entry_card_header_row.dart';
import 'package:daily_you/widgets/image_grid.dart';
import 'package:daily_you/widgets/scaled_markdown.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/models/entry.dart';

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
    final time = TimeManager.formatDate(entry.timeCreate, context);
    return Card.filled(
      color: Theme.of(context).colorScheme.surfaceContainer,
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: ClipRRect(
              clipBehavior: Clip.hardEdge,
              borderRadius: BorderRadius.circular(12),
              child: (images.isNotEmpty && !hideImage)
                  ? ImageGrid(images: images)
                  : (entry.text.isNotEmpty)
                      ? ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.black, Colors.transparent],
                              stops: [0.85, 1.0],
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.dstIn,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Wrap(children: [
                              IgnorePointer(
                                  child: SizedBox(
                                width: double.maxFinite,
                                child: ScaledMarkdown(
                                  data: entry.text,
                                  maxCharacters: 250,
                                  scaleFactor: 0.95,
                                ),
                              ))
                            ]),
                          ),
                        )
                      : Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Align(
                            alignment: AlignmentDirectional.topStart,
                            child: Text(
                              AppLocalizations.of(context)!.writeSomethingHint,
                              style: TextStyle(
                                  color: theme.disabledColor, fontSize: 16),
                            ),
                          ),
                        ),
            ),
          ),
          EntryCardHeaderRow(
            entry: entry,
            title: title == null ? time : title!,
            titlePadding: const EdgeInsets.symmetric(horizontal: 4.0),
            titleStyle: TextStyle(
                color: theme.textTheme.labelSmall?.color,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
