import 'dart:io';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/database/image_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' show extension;

class EntryImagePicker extends StatefulWidget {
  final ValueChanged<List<String>> onChangedImage;
  final bool openCamera;

  const EntryImagePicker(
      {super.key, required this.onChangedImage, this.openCamera = false});

  @override
  State<EntryImagePicker> createState() => _EntryImagePickerState();
}

class _EntryImagePickerState extends State<EntryImagePicker> {
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

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (Platform.isAndroid)
          IconButton(
              onPressed: _takePicture,
              icon: Icon(
                Icons.photo_camera_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              )),
        IconButton(
            onPressed: _choosePicture,
            icon: Icon(
              Icons.photo,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            )),
      ],
    );
  }
}
