import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/config_provider.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
import 'package:daily_you/widgets/image_grid.dart';
import 'package:daily_you/widgets/scaled_markdown.dart';
import 'package:flutter/material.dart';

class FlashbackCard extends StatelessWidget {
  const FlashbackCard({
    super.key,
    required this.title,
    required this.entries,
  });

  final String title;
  final List<Entry> entries;

  @override
  Widget build(BuildContext context) {
    final imagesProvider = EntryImagesProvider.instance;
    final hideImages =
        ConfigProvider.instance.get(ConfigKey.hideImagesInFlashbacks) == true;
    final theme = Theme.of(context);
    final text = entries.first.text;

    final coverImages = hideImages
        ? <EntryImage>[]
        : entries
            .map((e) => imagesProvider.getForEntry(e).firstOrNull)
            .whereType<EntryImage>()
            .take(4)
            .toList();

    final hasImages = coverImages.isNotEmpty;
    final showCount = entries.length > 1;

    return AspectRatio(
      aspectRatio: 3.7 / 4,
      child: Card.filled(
        color: theme.colorScheme.surfaceContainer,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            hasImages
                ? ImageGrid(images: coverImages)
                : ClipRect(
                    clipBehavior: Clip.hardEdge,
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black, Colors.transparent],
                          stops: [0.65, 0.75],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Wrap(children: [
                          IgnorePointer(
                              child: SizedBox(
                            width: double.maxFinite,
                            child: Padding(
                                padding: EdgeInsets.only(
                                    top: showCount ? 20.0 : 0.0),
                                child: (text.isNotEmpty)
                                    ? ScaledMarkdown(
                                        data: text,
                                        maxCharacters: 100,
                                      )
                                    : Text(
                                        AppLocalizations.of(
                                          context,
                                        )!
                                            .writeSomethingHint,
                                        style: TextStyle(
                                          color: theme.disabledColor,
                                          fontSize: 16,
                                        ),
                                      )),
                          ))
                        ]),
                      ),
                    ),
                  ),
            if (hasImages)
              Container(
                color: Colors.black.withValues(alpha: 0.30),
              ),
            Positioned(
              left: 6,
              right: 6,
              bottom: 6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: hasImages
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              left: 6,
              child: showCount
                  ? Row(
                      children: [
                        // The Opacity widget (< 1.0) forces Flutter to composite this entire
                        // container in an isolated layer. This ensures the BlendMode.dstOut
                        // only punches a hole through the white circle, not the main images underneath
                        Opacity(
                          opacity: 0.99,
                          child: Container(
                            height: 20,
                            width: 20,
                            decoration: BoxDecoration(
                              color: hasImages
                                  ? Colors.white
                                  : theme.colorScheme.onSurface,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                entries.length < 99
                                    ? '${entries.length}'
                                    : '99',
                                textScaler: TextScaler.noScaling,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  // This turns the text into an eraser to cut out the shape
                                  foreground: Paint()
                                    ..blendMode = BlendMode.dstOut,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
