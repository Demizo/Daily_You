// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';
import 'dart:isolate';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/database/attachment_storage.dart';
import 'package:daily_you/utils/exif_orientation.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/storage/storage_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart' hide PickedFile;
import 'package:image/image.dart' as img;
import 'package:logging/logging.dart';
import 'package:path/path.dart' show basename, extension, join;
import 'package:path_provider/path_provider.dart';
import 'package:v_video_compressor/v_video_compressor.dart';

typedef _Store = Future<NewAttachment?> Function(String path);

class PendingAttachment {
  const PendingAttachment({
    required this.type,
    required this.name,
    required this.sizeBytes,
    required this.store,
    this.discard,
  });

  final AttachmentType type;
  final String name;
  final int? sizeBytes;
  final Future<NewAttachment?> Function() store;
  final Future<void> Function()? discard;

  bool get isLarge => sizeBytes != null && type.isLarge(sizeBytes!);
}

class EntryAttachmentActions {
  static final Logger _logger = Logger('EntryAttachmentActions');

  static Future<List<PendingAttachment>> takePhoto() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile == null) return const [];
    return _pendingFromPaths(
        [pickedFile.path], AttachmentType.image, _storeImagePath,
        deleteAfterwards: _pickerReturnsCopies);
  }

  static Future<List<PendingAttachment>> pickFromGallery() async {
    final pickedFiles = await ImagePicker().pickMultiImage();
    return _pendingFromPaths([for (final file in pickedFiles) file.path],
        AttachmentType.image, _storeImagePath,
        deleteAfterwards: _pickerReturnsCopies);
  }

  static Future<List<NewAttachment>> importSharedImages(List<String> paths) =>
      _storeEach(paths, AttachmentType.image, _storeImagePath);

  static Future<void> deleteStoredAttachments(
      List<NewAttachment> attachments) async {
    for (final attachment in attachments) {
      await AttachmentStorage.instance
          .delete(attachment.filePath, attachment.type);
    }
  }

  static Future<void> discardAll(Iterable<PendingAttachment> pending) async {
    for (final attachment in pending) {
      await attachment.discard?.call();
    }
  }

  static Future<List<NewAttachment>> storeAll(List<PendingAttachment> pending,
      {bool Function()? isCancelled}) async {
    bool cancelled() => isCancelled?.call() ?? false;
    final attachments = <NewAttachment>[];
    var next = 0;
    try {
      while (next < pending.length && !cancelled()) {
        final stored = await pending[next++].store();
        if (stored != null) attachments.add(stored);
      }
    } catch (_) {
      await deleteStoredAttachments(attachments);
      rethrow;
    } finally {
      await discardAll(pending.skip(next));
    }
    if (cancelled()) {
      await deleteStoredAttachments(attachments);
      return const [];
    }
    return attachments;
  }

  static Future<List<NewAttachment>> _storeEach(
          List<String> paths, AttachmentType type, _Store store) async =>
      storeAll(
          await _pendingFromPaths(paths, type, store, deleteAfterwards: false));

  static Future<List<PendingAttachment>> takeVideo() async {
    final pickedFile =
        await ImagePicker().pickVideo(source: ImageSource.camera);
    if (pickedFile == null) return const [];
    return _pendingFromPaths(
        [pickedFile.path], AttachmentType.video, _storeVideo,
        deleteAfterwards: _pickerReturnsCopies);
  }

  static Future<List<PendingAttachment>> pickVideosFromGallery() async {
    final pickedFiles = await ImagePicker().pickMultiVideo();
    return _pendingFromPaths([for (final file in pickedFiles) file.path],
        AttachmentType.video, _storeVideo,
        deleteAfterwards: _pickerReturnsCopies);
  }

  static Future<List<PendingAttachment>> pickAudioFile() =>
      _pickFile(AttachmentType.audio, FileType.audio, _storeAudio);

  static bool get _pickerReturnsCopies => Platform.isAndroid;

  static Future<List<PendingAttachment>> _pendingFromPaths(
    List<String> paths,
    AttachmentType type,
    _Store store, {
    required bool deleteAfterwards,
  }) async =>
      [
        for (final path in paths)
          PendingAttachment(
            type: type,
            name: basename(path),
            sizeBytes: await File(path).length(),
            store: () =>
                _storeThenDelete(path, () => store(path), deleteAfterwards),
            discard: deleteAfterwards ? () => _deleteQuietly(path) : null,
          )
      ];

  static Future<List<PendingAttachment>> _pickFile(
      AttachmentType type, FileType fileType, _Store store) async {
    final picked = await StoragePicker.pickFile(
        mimeTypes: [type.mimePattern], type: fileType);
    if (picked == null) return const [];

    return [
      PendingAttachment(
        type: type,
        name: picked.name,
        sizeBytes: picked.sizeBytes,
        store: () async {
          final temporaryPath = await _copyToTemporaryFile(picked, type);
          if (temporaryPath == null) return null;
          return _storeThenDelete(
              temporaryPath, () => store(temporaryPath), true);
        },
      )
    ];
  }

  static Future<NewAttachment?> _storeThenDelete(String path,
      Future<NewAttachment?> Function() store, bool deleteAfterwards) async {
    try {
      return await store();
    } finally {
      if (deleteAfterwards) await _deleteQuietly(path);
    }
  }

  static Future<NewAttachment?> _storeAudio(String sourcePath) async {
    final fileName = await AttachmentStorage.instance.createFromFile(
        basename(sourcePath), File(sourcePath), AttachmentType.audio);
    return fileName != null
        ? NewAttachment(type: AttachmentType.audio, filePath: fileName)
        : null;
  }

  static Future<NewAttachment?> _storeVideo(String sourcePath) async {
    String? compressedPath;
    try {
      if (Platform.isAndroid) {
        try {
          final quality =
              ConfigProvider.instance.get(Settings.videoQualityLevel);
          final result = await VVideoCompressor().compressVideo(
            sourcePath,
            VVideoCompressionConfig(quality: _videoCompressQuality(quality)),
          );
          compressedPath = result?.compressedFilePath;
        } catch (error, stackTrace) {
          _logger.warning('Video compression failed, storing the original',
              error, stackTrace);
        }
      }

      final storedPath = compressedPath ?? sourcePath;
      final fileName = await AttachmentStorage.instance.createFromFile(
          basename(storedPath), File(storedPath), AttachmentType.video);
      return fileName != null
          ? NewAttachment(type: AttachmentType.video, filePath: fileName)
          : null;
    } finally {
      if (compressedPath != null && compressedPath != sourcePath) {
        await _deleteQuietly(compressedPath);
      }
    }
  }

  static VVideoCompressQuality _videoCompressQuality(String setting) =>
      switch (setting) {
        VideoQuality.low => VVideoCompressQuality.low,
        VideoQuality.high => VVideoCompressQuality.high,
        _ => VVideoCompressQuality.medium,
      };

  static Future<void> _deleteQuietly(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (error) {
      _logger.warning('Could not delete temporary file $path', error);
    }
  }

  static Future<String?> _copyToTemporaryFile(
      PickedFile picked, AttachmentType type) async {
    final pickedExtension = extension(picked.name);
    final temporaryDirectory = await getTemporaryDirectory();
    final temporaryName =
        'daily_you_import_${DateTime.now().microsecondsSinceEpoch}${pickedExtension.isNotEmpty ? pickedExtension : type.defaultExtension}';
    final copied =
        await picked.copyInto(temporaryDirectory.path, temporaryName);
    final temporaryPath = join(temporaryDirectory.path, temporaryName);
    if (!copied) {
      await _deleteQuietly(temporaryPath);
      return null;
    }
    return temporaryPath;
  }

  static Future<NewAttachment?> _storeImagePath(String path) {
    final quality = ConfigProvider.instance.get(Settings.imageQualityLevel);
    return _storeImage(XFile(path), quality);
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
