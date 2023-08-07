import 'dart:io';
import 'package:flutter/material.dart';
import 'package:daily_you/entries_database.dart';

class LocalImageLoader extends StatelessWidget {
  final String imagePath;

  const LocalImageLoader({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: EntriesDatabase.instance.getImgPath(imagePath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a loading indicator while fetching the image path
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          // Handle any error that occurred while fetching the image path
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          // Render the card with the fetched image path
          if (!File(snapshot.data!).existsSync()) {
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
          return FractionallySizedBox(
            widthFactor: 1,
            child: Image.file(
              cacheWidth: 400,
              fit: BoxFit.cover,
              File(snapshot.data!),
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
          return const Text('Image failed to load');
        }
      },
    );
  }
}
