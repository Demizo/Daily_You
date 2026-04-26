import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:daily_you/widgets/scaled_markdown.dart';
import 'package:flutter/material.dart';
import 'local_image_loader.dart';

class FlashbackCardWidget extends StatelessWidget {
  const FlashbackCardWidget({
    super.key,
    required this.title,
    required this.entries,
  });

  final String title;
  final List<Entry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imagesProvider = EntryImagesProvider.instance;

    // First image per entry (entries that have at least one image), up to 4
    final coverImages = entries
        .map((e) => imagesProvider.getForEntry(e).firstOrNull)
        .whereType<EntryImage>()
        .take(4)
        .toList();

    final hasImages = coverImages.isNotEmpty;
    final firstEntry = entries.first;

    return Card.filled(
      color: Theme.of(context).colorScheme.surfaceContainer,
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: hasImages
                  ? _imageGrid(coverImages)
                  : (firstEntry.text.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Wrap(children: [
                            IgnorePointer(
                              child: SizedBox(
                                width: double.maxFinite,
                                child: ScaledMarkdown(data: firstEntry.text),
                              ),
                            ),
                          ]),
                        )
                      : const SizedBox.expand()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                child: Text(
                  title,
                  style: TextStyle(
                      color: theme.textTheme.labelSmall?.color,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
              ),
              if (entries.length == 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 16),
                    child: MoodIcon(
                      moodValue: entries[0].mood,
                    ),
                  ),
                ),
              if (entries.length > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.onSurface,
                    ),
                    child: Center(
                      child: Text(
                        '${entries.length}',
                        style: TextStyle(
                          color: theme.colorScheme.surfaceContainer,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _imageGrid(List<EntryImage> imgs) {
    if (imgs.length == 1) {
      return LocalImageLoader(imagePath: imgs[0].imgPath);
    }

    if (imgs.length == 2) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: LocalImageLoader(imagePath: imgs[0].imgPath)),
          const SizedBox(width: 2),
          Expanded(child: LocalImageLoader(imagePath: imgs[1].imgPath)),
        ],
      );
    }

    if (imgs.length == 3) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: LocalImageLoader(imagePath: imgs[0].imgPath)),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: LocalImageLoader(imagePath: imgs[1].imgPath)),
                const SizedBox(height: 2),
                Expanded(child: LocalImageLoader(imagePath: imgs[2].imgPath)),
              ],
            ),
          ),
        ],
      );
    }

    // 4+
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: LocalImageLoader(imagePath: imgs[0].imgPath)),
              const SizedBox(width: 2),
              Expanded(child: LocalImageLoader(imagePath: imgs[1].imgPath)),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: LocalImageLoader(imagePath: imgs[2].imgPath)),
              const SizedBox(width: 2),
              Expanded(child: LocalImageLoader(imagePath: imgs[3].imgPath)),
            ],
          ),
        ),
      ],
    );
  }
}
