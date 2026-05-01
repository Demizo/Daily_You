import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
import 'package:daily_you/widgets/image_grid.dart';
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

    final coverImages = entries
        .map((e) => imagesProvider.getForEntry(e).firstOrNull)
        .whereType<EntryImage>()
        .take(4)
        .toList();

    final hasImages = coverImages.isNotEmpty;
    final showCount = entries.length > 1;

    return AspectRatio(
      aspectRatio: 3.7 / 4,
      child: Card.filled(
        color: Theme.of(context).colorScheme.surfaceContainer,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            hasImages
                ? ImageGrid(images: coverImages)
                : Center(
                    child: Icon(
                      Icons.history_rounded,
                      color: Theme.of(context).disabledColor,
                      size: 36,
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
                            : Theme.of(context).colorScheme.onSurface,
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
                            decoration: const BoxDecoration(
                              color: Colors.white,
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
