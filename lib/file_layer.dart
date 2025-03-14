import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';
import 'package:shared_storage/shared_storage.dart' as saf;

class FileLayer {
  static Future<String?> pickDirectory() async {
    if (Platform.isAndroid) {
      // Android
      var newFolderUri = await saf.openDocumentTree();
      if (newFolderUri == null || await saf.canWrite(newFolderUri) == false) {
        return null;
      }
      return newFolderUri.toString();
    } else {
      // Desktop
      final selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory == null || selectedDirectory == "/") return null;

      return selectedDirectory;
    }
  }

  static Future<String?> pickFile() async {
    if (Platform.isAndroid) {
      // Android
      var selectedFile = await saf.openDocument(
          grantWritePermission: false, persistablePermission: false);
      if (selectedFile == null) return null;
      return selectedFile.first.toString();
    } else {
      // Desktop
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
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
}
