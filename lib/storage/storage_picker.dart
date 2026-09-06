import 'dart:io';
import 'dart:typed_data';

import 'package:daily_you/storage/file_store.dart';
import 'package:daily_you/utils/saf_transfer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';
import 'package:saf_util/saf_util.dart';
import 'package:shared_storage/shared_storage.dart' as saf;

class PickedFile {
  const PickedFile(this.uri);

  final String uri;

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
      {List<String>? mimeTypes, List<String>? allowedExtensions}) async {
    if (Platform.isAndroid) {
      final pickedFile = await SafUtil().pickFile(mimeTypes: mimeTypes);
      return pickedFile != null ? PickedFile(pickedFile.uri) : null;
    }

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );
    final path = result?.files.first.path;
    return path != null ? PickedFile(path) : null;
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
