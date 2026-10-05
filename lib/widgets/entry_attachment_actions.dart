// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';
import 'dart:isolate';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/database/attachment_storage.dart';
import 'package:daily_you/utils/exif_orientation.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' show extension;

class EntryAttachmentActions {
  static Future<void> takePhoto(
      ValueChanged<List<NewAttachment>> onChangedImage) async {
    final picker = ImagePicker();
    final quality = ConfigProvider.instance.get(Settings.imageQualityLevel);
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      final attachment = await _storeImage(pickedFile, quality);
      if (attachment == null) return;
      onChangedImage([attachment]);
      if (Platform.isAndroid) {
        await File(pickedFile.path).delete();
      }
    }
  }

  static Future<void> pickFromGallery(
      ValueChanged<List<NewAttachment>> onChangedImage) async {
    final picker = ImagePicker();
    final quality = ConfigProvider.instance.get(Settings.imageQualityLevel);
    final pickedFiles = await picker.pickMultiImage();

    final newAttachments = <NewAttachment>[];
    for (final file in pickedFiles) {
      final attachment = await _storeImage(file, quality);
      if (attachment != null) {
        newAttachments.add(attachment);
      }
      if (Platform.isAndroid) {
        await File(file.path).delete();
      }
    }
    onChangedImage(newAttachments);
  }

  static Future<List<NewAttachment>> importSharedImages(
      List<String> paths) async {
    final quality = ConfigProvider.instance.get(Settings.imageQualityLevel);

    final newAttachments = <NewAttachment>[];
    for (final path in paths) {
      final attachment = await _storeImage(XFile(path), quality);
      if (attachment != null) {
        newAttachments.add(attachment);
      }
    }
    return newAttachments;
  }

  static Future<NewAttachment?> _storeImage(XFile file, String quality) async {
    final fileName = await AttachmentStorage.instance.create(
        file.name, await _compressImage(file, quality), AttachmentType.image);
    return fileName != null
        ? NewAttachment(type: AttachmentType.image, filePath: fileName)
        : null;
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

          return img.encodeJpg(resizedImage, quality: quality);
        });
      }
    }
  }
}
