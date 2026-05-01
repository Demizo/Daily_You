import 'package:daily_you/models/image.dart';
import 'package:flutter/material.dart';
import 'local_image_loader.dart';

class ImageGrid extends StatelessWidget {
  const ImageGrid({super.key, required this.images});

  final List<EntryImage> images;

  @override
  Widget build(BuildContext context) {
    final imgs = images.take(4).toList();

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
