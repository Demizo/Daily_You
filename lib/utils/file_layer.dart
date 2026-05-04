import 'dart:io';
import 'dart:typed_data';
import 'package:daily_you/utils/saf_transfer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';
import 'package:saf_util/saf_util.dart';
import 'package:shared_storage/shared_storage.dart' as saf;

class FileLayer {
  static Future<String?> pickDirectory() async {
    if (Platform.isAndroid) {
      // Android
      var pickedFolder = await SafUtil()
          .pickDirectory(writePermission: true, persistablePermission: true);
      return pickedFolder?.uri;
    } else {
      // Desktop
      final selectedDirectory = await FilePicker.getDirectoryPath();
      if (selectedDirectory == null || selectedDirectory == "/") return null;

      return selectedDirectory;
    }
  }

  static Future<String?> pickFile(
      {List<String>? mimeTypes, List<String>? allowedExtensions}) async {
    if (Platform.isAndroid) {
      // Android
      var pickedFile = await SafUtil().pickFile(mimeTypes: mimeTypes);
      return pickedFile?.uri;
    } else {
      // Desktop
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
      );
      if (result == null) return null;
      return result.files.first.path;
    }
  }

  static Future<bool> hasPermission(String uri) async {
    if (Platform.isAndroid) {
      if (await saf.exists(Uri.parse(uri)) == true &&
          await saf.canWrite(Uri.parse(uri)) == true) {
        return true;
      } else {
        return false;
      }
    } else {
      return await Directory(uri).exists();
    }
  }

  static Future<bool> exists(String uri,
      {String? name, useExternalPath = true}) async {
    if (Platform.isAndroid && useExternalPath) {
      if (name != null) {
        var target = await saf.child(Uri.parse(uri), name);
        return await target?.exists() ?? false;
      } else {
        return await saf.exists(Uri.parse(uri)) ?? false;
      }
    } else {
      if (name != null) {
        return await File(join(uri, name)).exists();
      } else {
        return await Directory(uri).exists();
      }
    }
  }

  static Future<Uint8List?> getFileBytes(String uri,
      {String? name, bool useExternalPath = true}) async {
    if (Platform.isAndroid && useExternalPath) {
      // Android
      if (name != null) {
        // Find file in directory
        var targetFile =
            await saf.child(Uri.parse(uri), name, requiresWriteAccess: true);
        return targetFile != null ? await targetFile.getContent() : null;
      } else {
        // Get the file directly
        return await saf.getDocumentContent(Uri.parse(uri));
      }
    } else {
      // Desktop
      var targetFile = File(join(uri, name));
      return await targetFile.exists() ? await targetFile.readAsBytes() : null;
    }
  }

  static Future<void> renameFile(String uri, String newName,
      {String? oldName, useExternalPath = true}) async {
    if (Platform.isAndroid && useExternalPath) {
      await SafUtil().rename(uri, false, newName);
    } else {
      await File(join(uri, oldName)).rename(newName);
    }
  }

  static Future<DateTime?> getFileModifiedTime(String uri,
      {String? name, useExternalPath = true}) async {
    if (Platform.isAndroid && useExternalPath) {
      // Android
      if (name != null) {
        // Find file in directory
        var targetFile =
            await saf.child(Uri.parse(uri), name, requiresWriteAccess: true);
        return targetFile?.lastModified;
      } else {
        // Get the file directly
        var targetFile = await saf.fromTreeUri(Uri.parse(uri));
        return targetFile?.lastModified;
      }
    } else {
      // Desktop
      var targetFile = File(join(uri, name));
      return await targetFile.exists() ? await targetFile.lastModified() : null;
    }
  }

  static Future<int?> getFileSize(String uri,
      {String? name, useExternalPath = true}) async {
    if (Platform.isAndroid && useExternalPath) {
      // Android
      if (name != null) {
        // Find file in directory
        var targetFile =
            await saf.child(Uri.parse(uri), name, requiresWriteAccess: true);
        return targetFile?.size;
      } else {
        // Get the file directly
        var targetFile = await saf.fromTreeUri(Uri.parse(uri));
        return targetFile?.size;
      }
    } else {
      // Desktop
      var targetFile = File(join(uri, name));
      return await targetFile.exists() ? await targetFile.length() : null;
    }
  }

  static Future<bool> writeFileBytes(String destination, Uint8List bytes,
      {String? name, useExternalPath = true}) async {
    if (Platform.isAndroid && useExternalPath) {
      // Android
      Uri targetUri;
      if (name == null) {
        targetUri = Uri.parse(destination);
      } else {
        var targetFile = await saf.child(Uri.parse(destination), name,
            requiresWriteAccess: true);
        if (targetFile == null) return false;
        targetUri = targetFile.uri;
      }
      return await saf.writeToFileAsBytes(targetUri, bytes: bytes) ?? false;
    } else {
      // Desktop
      await File(join(destination, name)).writeAsBytes(bytes);
      return true;
    }
  }

  static Future<String?> createFile(
      String destination, String name, Uint8List bytes,
      {bool useExternalPath = true}) async {
    if (Platform.isAndroid && useExternalPath) {
      // Android
      var newFile = await saf.createFileAsBytes(Uri.parse(destination),
          mimeType: "*/*", displayName: name, bytes: bytes);
      return newFile?.uri.toString();
    } else {
      // Desktop
      var newFile = await File(join(destination, name)).writeAsBytes(bytes);
      return newFile.path;
    }
  }

  static Future<bool> deleteFile(String destination,
      {String? name, bool useExternalPath = true}) async {
    if (Platform.isAndroid && useExternalPath) {
      // Android
      if (name == null) {
        return await saf.delete(Uri.parse(destination)) ?? false;
      } else {
        var targetFile = await saf.child(Uri.parse(destination), name);
        if (targetFile == null) return false;
        return await targetFile.delete() ?? false;
      }
    } else {
      // Desktop
      if (await File(join(destination, name)).exists()) {
        await File(join(destination, name)).delete();
      }
      return true;
    }
  }

  static Future<List<String>> listFiles(String destination,
      {useExternalPath = true}) async {
    List<String> fileNames = List.empty(growable: true);
    if (Platform.isAndroid && useExternalPath) {
      // Android
      const List<saf.DocumentFileColumn> columns = <saf.DocumentFileColumn>[
        saf.DocumentFileColumn.displayName,
        saf.DocumentFileColumn.mimeType,
      ];

      var fileList = saf.listFiles(Uri.parse(destination), columns: columns);

      await for (saf.DocumentFile file in fileList) {
        if (file.isFile != null && file.isFile!) {
          if (file.name != null) {
            fileNames.add(file.name!);
          }
        }
      }
    } else {
      // Desktop
      var files = Directory(destination).list();
      await for (FileSystemEntity fileEntity in files) {
        if (fileEntity is File) {
          fileNames.add(basename(fileEntity.path));
        }
      }
    }
    return fileNames;
  }

  static Future<bool> copyFromExternalLocation(
      String externalFile, String internalFolder, String outputFile,
      {Function(double percent)? onProgress}) async {
    if (Platform.isAndroid) {
      return await SafTransfer.copyFromExternalLocation(
          externalFile, join(internalFolder, outputFile),
          onProgress: onProgress);
    } else {
      // Desktop file streaming
      final sourceFile = File(externalFile);
      if (!await sourceFile.exists()) return false;

      final fileSize = await sourceFile.length();
      if (fileSize == 0) return false;

      final destFile = File(join(internalFolder, outputFile));
      final writeSink = destFile.openWrite();

      var transferredSize = 0;
      var lastReportedProgress = 0.0;

      await for (List<int> chunk in sourceFile.openRead()) {
        writeSink.add(chunk);
        transferredSize += chunk.length;

        var percent = (transferredSize / fileSize) * 100;
        if (percent - lastReportedProgress >= 5.0 || percent >= 100.0) {
          lastReportedProgress = percent;
          if (onProgress != null) {
            onProgress(percent);
          }
        }
      }

      await writeSink.flush();
      await writeSink.close();
      return true;
    }
  }

  static Future<bool> copyToExternalLocation(
      String localFile, String externalFolder, String outputFile,
      {Function(double percent)? onProgress}) async {
    if (Platform.isAndroid) {
      return await SafTransfer.copyToExternalLocation(
          localFile, externalFolder, outputFile, "application/zip",
          onProgress: onProgress);
    } else {
      final sourceFile = File(localFile);
      if (!await sourceFile.exists()) return false;

      final fileSize = await sourceFile.length();
      if (fileSize == 0) return false;

      final destFile = File(join(externalFolder, outputFile));
      final writeSink = destFile.openWrite();

      var transferredSize = 0;
      var lastReportedProgress = 0.0;

      await for (List<int> chunk in sourceFile.openRead()) {
        writeSink.add(chunk);
        transferredSize += chunk.length;

        var percent = (transferredSize / fileSize) * 100;
        if (percent - lastReportedProgress >= 5.0 || percent >= 100.0) {
          lastReportedProgress = percent;
          if (onProgress != null) {
            onProgress(percent);
          }
        }
      }

      await writeSink.flush();
      await writeSink.close();
      return true;
    }
  }
}
