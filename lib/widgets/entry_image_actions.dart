import 'dart:io';
import 'dart:isolate';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/database/image_storage.dart';
import 'package:daily_you/utils/exif_orientation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' show extension;

class EntryImageActions {
  static Future<void> takePhoto(
      ValueChanged<List<String>> onChangedImage) async {
    final picker = ImagePicker();
    final quality = ConfigProvider.instance.get(Settings.imageQualityLevel);
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      final imageName = await _storeCompressed(pickedFile, quality);
      if (imageName == null) return;
      onChangedImage([imageName]);
      if (Platform.isAndroid) {
        await File(pickedFile.path).delete();
      }
    }
  }

  static Future<void> pickFromGallery(
      ValueChanged<List<String>> onChangedImage) async {
    final picker = ImagePicker();
    final quality = ConfigProvider.instance.get(Settings.imageQualityLevel);
    final pickedFiles = await picker.pickMultiImage();

    final newImages = <String>[];
    for (final file in pickedFiles) {
      final imageName = await _storeCompressed(file, quality);
      if (imageName != null) {
        newImages.add(imageName);
      }
      if (Platform.isAndroid) {
        await File(file.path).delete();
      }
    }
    onChangedImage(newImages);
  }

  static Future<List<String>> importSharedImages(List<String> paths) async {
    final quality = ConfigProvider.instance.get(Settings.imageQualityLevel);

    final newImages = <String>[];
    for (final path in paths) {
      final imageName = await _storeCompressed(XFile(path), quality);
      if (imageName != null) {
        newImages.add(imageName);
      }
    }
    return newImages;
  }

  static Future<String?> _storeCompressed(XFile file, String quality) async {
    return await ImageStorage.instance
        .create(file.name, await _compressImage(file, quality));
  }

  static Future<Uint8List> _compressImage(
      XFile image, String imageQuality) async {
    final width =
        (ConfigProvider.imageQualityMaxSizeMapping[imageQuality] ?? 1600)
            .toInt();
    final quality =
        ConfigProvider.imageQualityCompressionMapping[imageQuality] ?? 100;

    if ((extension(image.path).toLowerCase() == ".gif") ||
        (imageQuality == ImageQuality.noCompression)) {
      return await image.readAsBytes();
    } else {
      if (Platform.isAndroid) {
        final orientation = ExifOrientation.read(await image.readAsBytes());
        final mirrored = ExifOrientation.isMirrored(orientation);
        final compressed = await FlutterImageCompress.compressWithFile(
            image.path,
            quality: quality,
            minWidth: width,
            minHeight: width,
            autoCorrectionAngle: !mirrored,
            keepExif: true);
        if (compressed == null) return await image.readAsBytes();
        return mirrored
            ? ExifOrientation.bake(compressed, orientation!, quality: quality)
            : compressed;
      } else {
        return await Isolate.run(() async {
          final originalImage = await img.decodeImageFile(image.path);

          if (originalImage == null) return File(image.path).readAsBytesSync();

          final resizedImage = img.copyResize(
            originalImage,
            width: width,
            interpolation: img.Interpolation.average,
          );

          resizedImage.exif = originalImage.exif;

          final compressedBytes = img.encodeJpg(resizedImage, quality: quality);

          File(image.path).writeAsBytesSync(compressedBytes);

          return compressedBytes;
        });
      }
    }
  }
}
