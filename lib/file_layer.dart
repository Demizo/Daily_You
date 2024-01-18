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

  static Future<Uint8List?> getFileBytes(String uri, {String? name}) async {
    if (Platform.isAndroid) {
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

  static Future<bool> writeFileBytes(String destination, Uint8List bytes,
      {String? name}) async {
    if (Platform.isAndroid) {
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
      await File(destination).writeAsBytes(bytes);
      return true;
    }
  }

  static Future<String?> createFile(
      String destination, String name, Uint8List bytes) async {
    if (Platform.isAndroid) {
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
}
