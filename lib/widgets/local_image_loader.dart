import 'dart:typed_data';
import 'package:daily_you/widgets/local_image_cache.dart';
import 'package:flutter/material.dart';

class LocalImageLoader extends StatelessWidget {
  final String imagePath;
  final int cacheSize;

  const LocalImageLoader(
      {super.key, required this.imagePath, this.cacheSize = 400});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
        future:
            LocalImageCache.instance.getResizedImageBytes(imagePath, cacheSize),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: SizedBox());
          } else if (snapshot.hasError) {
            return Text('${snapshot.error}');
          } else if (snapshot.hasData) {
            return FractionallySizedBox(
              widthFactor: 1,
              child: Image.memory(
                snapshot.data!,
                fit: BoxFit.cover,
                cacheWidth: cacheSize,
              ),
            );
          } else {
            // Image not found
            return const Center(
              child: Icon(
                Icons.image_search_rounded,
                size: 36,
              ),
            );
          }
        });
  }
}
