import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:daily_you/entries_database.dart';

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
  Future<void> _takePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      saveImage(pickedFile);
    }
  }

  Future<void> _choosePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      saveImage(pickedFile);
    }
  }

  void clearImage() async {
    widget.onChangedImage(null);
  }

  void saveImage(XFile pickedFile) async {
    // Save the image to a custom location defined by your app
    final imgDirectory = await EntriesDatabase.instance.getImgDatabasePath();
    final currTime = DateTime.now();
    final imageName =
        "daily_you_${currTime.month}_${currTime.day}_${currTime.year}-${currTime.hour}.${currTime.minute}.${currTime.second}.jpg";
    final imageFilePath = "$imgDirectory/$imageName";
    await pickedFile.saveTo(imageFilePath);

    setState(() {
      widget.onChangedImage(imageName);
    });
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
