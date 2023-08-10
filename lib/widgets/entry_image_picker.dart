import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:daily_you/entries_database.dart';
import 'package:media_scanner/media_scanner.dart';

import 'local_image_loader.dart';

class EntryImagePicker extends StatefulWidget {
  final String? imgPath;
  final ValueChanged<String?> onChangedImage;

  const EntryImagePicker(
      {super.key, this.imgPath, required this.onChangedImage});

  @override
  State<EntryImagePicker> createState() => _EntryImagePickerState();
}

class _EntryImagePickerState extends State<EntryImagePicker> {
  void _showDeleteImagePopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Photo?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Do you want to delete the photo from your device?"),
              const SizedBox(
                height: 8,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(
                      Icons.delete_rounded,
                      size: 24,
                    ),
                    label: const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Text(
                        "Delete",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    onPressed: () async {
                      final path =
                          '${await EntriesDatabase.instance.getImgDatabasePath()}/${widget.imgPath!}';
                      if (await File(path).exists()) {
                        await File(path).delete();
                      }
                      widget.onChangedImage(null);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      backgroundColor: Theme.of(context).colorScheme.background,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(
                      Icons.cancel_rounded,
                      size: 24,
                    ),
                    label: const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Text(
                        "Cancel",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.background,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _takePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      await saveImage(pickedFile);
    }
  }

  Future<void> _choosePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      await saveImage(pickedFile);
    }
  }

  Future<void> clearImage() async {
    _showDeleteImagePopup();
  }

  Future<void> saveImage(XFile pickedFile) async {
    // Save the image to a custom location defined by your app
    final imgDirectory = await EntriesDatabase.instance.getImgDatabasePath();
    final currTime = DateTime.now();
    // Don't make a copy of files already in the folder
    if (await File("$imgDirectory/${pickedFile.name}").exists()) {
      setState(() {
        widget.onChangedImage(pickedFile.name);
      });
      return;
    }
    final imageName =
        "daily_you_${currTime.month}_${currTime.day}_${currTime.year}-${currTime.hour}.${currTime.minute}.${currTime.second}.jpg";
    final imageFilePath = "$imgDirectory/$imageName";
    await pickedFile.saveTo(imageFilePath);
    if (Platform.isAndroid) {
      // Add image to media store
      MediaScanner.loadMedia(path: imageFilePath);
    }
    setState(() {
      widget.onChangedImage(imageName);
    });
    // Delete picked file from cache
    await File(pickedFile.path).delete();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imgPath != null) {
      return Stack(alignment: Alignment.center, children: [
        SizedBox(
          height: 300,
          width: 300,
          child: Card(
              clipBehavior: Clip.antiAlias,
              child: LocalImageLoader(imagePath: widget.imgPath!)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(6),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.background,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
          ),
          onPressed: clearImage,
          child: const Icon(Icons.cancel_rounded),
        ),
      ]);
    } else {
      return Center(
        child: SizedBox(
          height: 300,
          width: 300,
          child: Card(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (Platform.isAndroid)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(6),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.background,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    onPressed: _takePicture,
                    child: const Icon(Icons.photo_camera_rounded),
                  ),
                const SizedBox(
                  width: 6,
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(6),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.background,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  onPressed: _choosePicture,
                  child: const Icon(Icons.photo),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
