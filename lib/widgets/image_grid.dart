import 'package:daily_you/models/image.dart';
import 'package:flutter/material.dart';
import 'local_image_loader.dart';

class ImageGrid extends StatelessWidget {
  ImageGrid({super.key, required List<EntryImage> images})
      : imagePaths = [for (final image in images) image.imgPath],
        imageBuilder = _buildStoredImage;

  const ImageGrid.fromPaths({
    super.key,
    required this.imagePaths,
    required this.imageBuilder,
  });

  final List<String> imagePaths;
  final Widget Function(String imagePath) imageBuilder;

  static Widget _buildStoredImage(String imagePath) =>
      LocalImageLoader(imagePath: imagePath);

  @override
  Widget build(BuildContext context) {
    final paths = imagePaths.take(4).toList();
    Widget tile(int index) => Expanded(child: imageBuilder(paths[index]));
    const horizontalGap = SizedBox(width: 2);
    const verticalGap = SizedBox(height: 2);

    if (paths.length == 1) {
      return imageBuilder(paths[0]);
    }

    if (paths.length == 2) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [tile(0), horizontalGap, tile(1)],
      );
    }

    if (paths.length == 3) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          tile(0),
          horizontalGap,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [tile(1), verticalGap, tile(2)],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [tile(0), horizontalGap, tile(1)],
          ),
        ),
        verticalGap,
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [tile(2), horizontalGap, tile(3)],
          ),
        ),
      ],
    );
  }
}
