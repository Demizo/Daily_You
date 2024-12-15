import 'dart:typed_data';
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
            return Text('Error: ${snapshot.error}');
          } else if (snapshot.hasData) {
            // Render the card with the fetched image path

            return FractionallySizedBox(
              widthFactor: 1,
              child: Image.memory(
                snapshot.data!,
                cacheWidth: cacheSize,
                fit: BoxFit.cover,
                errorBuilder: (BuildContext context, Object exception,
                    StackTrace? stackTrace) {
                  // Image failed to load, display a different widget
                  return const Center(
                    child: Column(
                      children: [
                        Expanded(
                            child: Center(
                                child: Icon(
                          Icons.question_mark_rounded,
                          size: 70,
                        ))),
                        Text('Image failed to load'),
                      ],
                    ),
                  );
                },
              ),
            );
          } else {
            // Image not found
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                      child: Icon(
                    Icons.question_mark_rounded,
                    size: 70,
                  )),
                  Text(
                    'Image not found!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Check your image folder in settings...',
                    textAlign: TextAlign.center,
                  )
                ],
              ),
            );
          }
        });
  }
}
