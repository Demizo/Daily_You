import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';
import 'package:saf_stream/saf_stream.dart';
import 'package:saf_stream/saf_stream_platform_interface.dart';
import 'package:saf_util/saf_util.dart';
import 'package:shared_storage/shared_storage.dart' as saf;

class FileLayerWriteStream {
  final bool useSaf;
  final SafWriteStreamInfo? safStream;
  final IOSink? sink;

  const FileLayerWriteStream({required this.useSaf, this.safStream, this.sink});
}

class FileLayer {
  static Future<String?> pickDirectory() async {
    if (Platform.isAndroid) {
      // Android
      var pickedFolder = await SafUtil()
          .pickDirectory(writePermission: true, persistablePermission: true);
      return pickedFolder?.uri;
    } else {
      // Desktop
      final selectedDirectory = await FilePicker.platform.getDirectoryPath();
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
      FilePickerResult? result = await FilePicker.platform.pickFiles(
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

  static Future<Stream<List<int>>?> readFileStream(String uri,
      {String? name, useExternalPath = true}) async {
    if (Platform.isAndroid && useExternalPath) {
      // Android
      return await SafStream().readFileStream(uri);
    } else {
      // Desktop
      var targetFile = File(join(uri, name));
      return await targetFile.exists() ? targetFile.openRead() : null;
    }
  }

  static Future<FileLayerWriteStream?> openFileWriteStream(
      String uri, String name,
      {overwrite = true, useExternalPath = true}) async {
    if (Platform.isAndroid && useExternalPath) {
      // Android
      var stream =
          await SafStream().startWriteStream(uri, name, 'application/zip');
      return FileLayerWriteStream(useSaf: true, safStream: stream);
    } else {
      // Desktop
      var targetFile = File(join(uri, name));
      return FileLayerWriteStream(useSaf: false, sink: targetFile.openWrite());
    }
  }

  static Future<void> writeFileWriteStreamChunk(
      FileLayerWriteStream stream, Uint8List data) async {
    if (stream.useSaf) {
      await SafStream().writeChunk(stream.safStream!.session, data);
    } else {
      stream.sink!.add(data);
      await stream.sink!.flush();
    }
  }

  static Future<void> closeFileWriteStream(FileLayerWriteStream stream) async {
    if (stream.useSaf) {
      await SafStream().endWriteStream(stream.safStream!.session);
    } else {
      await stream.sink!.close();
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
}
