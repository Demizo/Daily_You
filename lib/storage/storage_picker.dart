// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';
import 'dart:typed_data';

import 'package:daily_you/storage/file_store.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saf_transfer/saf_transfer.dart';
import 'package:saf_util/saf_util.dart';
import 'package:shared_storage/shared_storage.dart' as saf;

class PickedFile {
  const PickedFile(this.uri, {String? displayName, this.sizeBytes})
      : _displayName = displayName;

  final String uri;
  final String? _displayName;
  final int? sizeBytes;

  String get name => _displayName ?? basename(uri);

  Future<Uint8List?> readBytes() async {
    if (Platform.isAndroid) {
      return saf.getDocumentContent(Uri.parse(uri));
    }
    final file = File(uri);
    return await file.exists() ? file.readAsBytes() : null;
  }

  Future<bool> copyInto(String directoryPath, String fileName,
      {void Function(double percent)? onProgress}) async {
    if (Platform.isAndroid) {
      return SafTransfer.copyFromExternalLocation(
          uri, join(directoryPath, fileName),
          onProgress: onProgress);
    }
    return _streamCopy(File(uri), File(join(directoryPath, fileName)),
        onProgress: onProgress);
  }
}

class PickedDirectory {
  const PickedDirectory(this.uri);

  final String uri;

  FileStore get store => FileStore.external(uri);

  Future<bool> copyFileInto(String sourcePath, String fileName,
      {required String mimeType,
      void Function(double percent)? onProgress}) async {
    if (Platform.isAndroid) {
      return SafTransfer.copyToExternalLocation(
          sourcePath, uri, fileName, mimeType,
          onProgress: onProgress);
    }
    return _streamCopy(File(sourcePath), File(join(uri, fileName)),
        onProgress: onProgress);
  }
}

class StoragePicker {
  static String displayName(String uri) {
    try {
      final lastSegment = Uri.decodeFull(uri).split('/').last;
      return lastSegment.contains(':')
          ? lastSegment.split(':').last
          : lastSegment;
    } catch (e) {
      return uri;
    }
  }

  static Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt >= 33) return true;

    var status = await Permission.storage.status;
    if (!status.isGranted) status = await Permission.storage.request();
    return status.isGranted;
  }

  static Future<PickedDirectory?> pickDirectoryWithAccess() async {
    if (!await requestStoragePermission()) return null;
    return pickDirectory();
  }

  static Future<PickedDirectory?> pickDirectory() async {
    if (Platform.isAndroid) {
      final pickedFolder = await SafUtil()
          .pickDirectory(writePermission: true, persistablePermission: true);
      return pickedFolder != null ? PickedDirectory(pickedFolder.uri) : null;
    }

    final selectedDirectory = await FilePicker.getDirectoryPath();
    if (selectedDirectory == null || selectedDirectory == "/") return null;
    return PickedDirectory(selectedDirectory);
  }

  static Future<PickedFile?> pickFile(
      {List<String>? mimeTypes,
      List<String>? allowedExtensions,
      FileType? type}) async {
    if (Platform.isAndroid) {
      final pickedFile = await SafUtil().pickFile(mimeTypes: mimeTypes);
      return pickedFile != null
          ? PickedFile(pickedFile.uri,
              displayName: pickedFile.name, sizeBytes: pickedFile.length)
          : null;
    }

    final pickerType =
        type ?? (allowedExtensions != null ? FileType.custom : FileType.any);
    final result = await FilePicker.pickFiles(
      type: pickerType,
      allowedExtensions:
          pickerType == FileType.custom ? allowedExtensions : null,
    );
    final path = result.isEmpty ? null : result.first.path;
    return path != null
        ? PickedFile(path, sizeBytes: await File(path).length())
        : null;
  }
}

Future<bool> _streamCopy(File source, File destination,
    {void Function(double percent)? onProgress}) async {
  if (!await source.exists()) return false;

  final sourceSize = await source.length();
  if (sourceSize == 0) return false;

  final writeSink = destination.openWrite();
  var transferredSize = 0;
  var lastReportedProgress = 0.0;

  await for (final chunk in source.openRead()) {
    writeSink.add(chunk);
    transferredSize += chunk.length;

    final percent = (transferredSize / sourceSize) * 100;
    if (percent - lastReportedProgress >= 5.0 || percent >= 100.0) {
      lastReportedProgress = percent;
      onProgress?.call(percent);
    }
  }

  await writeSink.flush();
  await writeSink.close();
  return true;
}
