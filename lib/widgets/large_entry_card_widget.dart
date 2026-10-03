import 'package:daily_you/models/image.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/entry_card_header_row.dart';
import 'package:daily_you/widgets/image_grid.dart';
import 'package:daily_you/widgets/scaled_markdown.dart';
import 'package:material_ui/material_ui.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';

class LargeCard extends StatelessWidget {
  const LargeCard({super.key, this.media, this.header, this.body});

  final Widget? media;
  final Widget? header;
  final Widget? body;

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      color: Theme.of(context).colorScheme.surfaceContainer,
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (media != null)
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: media,
              ),
            ),
          if (header != null || body != null)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (header != null)
                    Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: header,
                    )
                  else
                    const SizedBox(height: 8),
                  if (body != null)
                    Expanded(
                      child: ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black, Colors.transparent],
                            stops: [0.8, 0.95],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.dstIn,
                        child: ClipRect(
                          clipBehavior: Clip.hardEdge,
                          child: Padding(
                            padding:
                                const EdgeInsets.only(left: 8.0, right: 8.0),
                            child: IgnorePointer(child: body),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static Widget markdownBody(String text) => OverflowBox(
        alignment: AlignmentDirectional.topStart,
        maxHeight: double.infinity,
        child: ScaledMarkdown(
          data: text,
          maxCharacters: 500,
          scaleFactor: 0.95,
        ),
      );
}

class LargeEntryCardWidget extends StatelessWidget {
  const LargeEntryCardWidget({
    super.key,
    this.title,
    required this.entry,
    required this.images,
    this.hideImage = false,
  });

  final Entry entry;
  final List<EntryImage> images;
  final String? title;
  final bool hideImage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = TimeManager.formatDate(entry.timeCreate, context);
    return LargeCard(
      media: images.isNotEmpty && !hideImage ? ImageGrid(images: images) : null,
      header: EntryCardHeaderRow(
        entry: entry,
        title: title == null ? time : title!,
        titlePadding: const EdgeInsets.only(left: 4.0),
        titleStyle: TextStyle(
          color: theme.textTheme.labelSmall?.color,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: entry.text.isNotEmpty
          ? LargeCard.markdownBody(entry.text)
          : Text(
              AppLocalizations.of(context)!.writeSomethingHint,
              style: TextStyle(color: theme.disabledColor, fontSize: 16),
            ),
    );
  }
}
