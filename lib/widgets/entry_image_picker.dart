import 'dart:io';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/database/image_storage.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' show extension;

import 'local_image_loader.dart';

class EntryImagePicker extends StatefulWidget {
  final String? imgPath;
  final ValueChanged<List<String>?> onChangedImage;
  final bool openCamera;

  const EntryImagePicker(
      {super.key,
      this.imgPath,
      required this.onChangedImage,
      this.openCamera = false});

  @override
  State<EntryImagePicker> createState() => _EntryImagePickerState();
}

class _EntryImagePickerState extends State<EntryImagePicker> {
  void _showDeleteImagePopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.deletePhotoTitle),
          actions: [
            TextButton(
              child:
                  Text(MaterialLocalizations.of(context).deleteButtonTooltip),
              onPressed: () async {
                widget.onChangedImage(null);
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
              onPressed: () async {
                Navigator.pop(context);
              },
            )
          ],
          content: Text(AppLocalizations.of(context)!.deletePhotoDescription),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.openCamera) {
      _takePicture();
    }
  }

  Future<void> _takePicture() async {
    final picker = ImagePicker();
    final quality = ConfigProvider.instance.get(ConfigKey.imageQualityLevel);
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      var imageName = await ImageStorage.instance
          .create(pickedFile.name, await _compressImage(pickedFile, quality));
      if (imageName == null) return;
      setState(() {
        widget.onChangedImage([imageName]);
      });
      // Delete picked file from cache
      if (Platform.isAndroid) {
        await File(pickedFile.path).delete();
      }
    }
  }

  Future<void> _choosePicture() async {
    final picker = ImagePicker();
    final quality = ConfigProvider.instance.get(ConfigKey.imageQualityLevel);
    final pickedFiles = await picker.pickMultiImage();

    List<String> newImages = List.empty(growable: true);
    for (var file in pickedFiles) {
      var imageName = await ImageStorage.instance
          .create(file.name, await _compressImage(file, quality));
      if (imageName != null) {
        newImages.add(imageName);
      }
      // Delete picked file from cache
      if (Platform.isAndroid) {
        await File(file.path).delete();
      }
    }
    setState(() {
      widget.onChangedImage(newImages);
    });
  }

  Future<Uint8List> _compressImage(XFile image, String imageQuality) async {
    final width =
        (ConfigProvider.imageQualityMaxSizeMapping[imageQuality] ?? 1600)
            .toInt();
    final quality =
        ConfigProvider.imageQualityCompressionMapping[imageQuality] ?? 100;

    // Return raw bytes if compression is disabled or if the image is a GIF
    if ((extension(image.path).toLowerCase() == ".gif") ||
        (imageQuality == ImageQuality.noCompression)) {
      return await image.readAsBytes();
    } else {
      if (Platform.isAndroid) {
        return await FlutterImageCompress.compressWithFile(image.path,
                quality: quality, minWidth: width, minHeight: width) ??
            await image.readAsBytes();
      } else {
        final cmd = img.Command()
          ..decodeJpgFile(image.path)
          ..copyResize(width: width, interpolation: img.Interpolation.average)
          ..encodeJpgFile(image.path, quality: quality);
        await cmd.executeThread();
        return await image.readAsBytes();
      }
    }
  }

  Future<void> clearImage() async {
    _showDeleteImagePopup();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imgPath != null) {
      return Stack(alignment: Alignment.center, children: [
        SizedBox(
          height: 220,
          width: 220,
          child: Card(
              clipBehavior: Clip.antiAlias,
              child: LocalImageLoader(imagePath: widget.imgPath!)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(6),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.surface,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
          ),
          onPressed: clearImage,
          child: Icon(
            Icons.cancel_rounded,
            color: Theme.of(context).colorScheme.surface,
            size: 24,
          ),
        ),
      ]);
    } else {
      return Center(
        child: SizedBox(
          height: 220,
          width: 220,
          child: Card(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (Platform.isAndroid)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(6),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.surface,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    onPressed: _takePicture,
                    child: Icon(
                      Icons.photo_camera_rounded,
                      color: Theme.of(context).colorScheme.surface,
                      size: 24,
                    ),
                  ),
                const SizedBox(
                  width: 6,
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(6),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.surface,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  onPressed: _choosePicture,
                  child: Icon(
                    Icons.photo,
                    color: Theme.of(context).colorScheme.surface,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
