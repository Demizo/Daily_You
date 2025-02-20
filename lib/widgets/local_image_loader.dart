import 'dart:typed_data';
import 'package:cached_memory_image/cached_memory_image.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/entries_database.dart';

class LocalImageLoader extends StatelessWidget {
  final String imagePath;
  final int cacheSize;

  const LocalImageLoader(
      {super.key, required this.imagePath, this.cacheSize = 400});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
        future: EntriesDatabase.instance.getImgBytes(imagePath),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show a loading indicator while fetching the image path
            return const Center(child: SizedBox());
          } else if (snapshot.hasError) {
            // Handle any error that occurred while fetching the image path
            return Text('${snapshot.error}');
          } else if (snapshot.hasData) {
            // Render the card with the fetched image path

            return FractionallySizedBox(
              widthFactor: 1,
              child: CachedMemoryImage(
		uniqueKey: imagePath,
                bytes: snapshot.data!,
                cacheWidth: cacheSize,
                fit: BoxFit.cover,
                errorBuilder: (BuildContext context, Object exception,
                    StackTrace? stackTrace) {
                  // Image failed to load, display a different widget
                  return const Center(
                    child: Icon(
		      Icons.warning_rounded,
                      size: 36,
                    )
                  );
                },
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
