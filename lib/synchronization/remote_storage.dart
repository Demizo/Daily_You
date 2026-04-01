import 'dart:nativewrappers/_internal/vm/lib/convert_patch.dart';

import 'package:crypto/crypto.dart';
import 'package:daily_you/synchronization/encryption_provider.dart';

/// Remote storage visitor abstraction that is used to interact with the remote storage in a platform-agnostic way.
/// This allows for different implementations of the remote storage without changing the synchronization logic.
abstract class RemoteStorageVisitor {
  /// Read the file data as bytes from the given path. The path is absolute.
  Future<List<int>> readFile(String path);

  /// List the directory at the given path and return a list of absolute paths of its contents. If the directory does not exist, returns null.
  Future<Iterable<String>?> listDirectory(String path);

  /// Write the file data as bytes to the given path. The path is absolute. If the file already exists, it should be overwritten.
  Future<void> writeFile(String path, List<int> bytes);

  /// Delete the file at the given path. The path is absolute. If the file does not exist or an error occurs, returns false. If the file is successfully deleted, returns true.
  Future<bool> deleteFile(String path);

  /// Delete the directory at the given path. The path is absolute. If the directory does not exist or an error occurs, returns false. If the directory is successfully deleted, returns true.
  Future<bool> deleteDirectory(String path) {
    return deleteFile(path);
  }

  /// Checks if a file or a directory exists.
  Future<bool> fileExists(String path);

  Future<bool> directoryExists(String path) {
    return fileExists(path);
  }

  /// Closes the connection, if required. It is always called after remote storage is no longer in use.
  Future<void> close();

  /// Creates directories
  Future<bool> mkdirs(String path);
}

/// FileData is the representation of the remote files data
class FileData {
  final List<int> bytes;
  final RemoteStorage remoteStorage;

  FileData(this.bytes, this.remoteStorage);

  Future<List<int>> getDecrypted() async {
    if (remoteStorage.encryptionProvider == null) {
      throw StateError("Encryption provider is required for decryption");
    }
    final decryptedBytes =
        await remoteStorage.encryptionProvider!.decryptBytes(bytes);
    return decryptedBytes;
  }

  List<int> getRaw() {
    return bytes;
  }
}

/// RemoteView is an abstraction for files and folders.
/// View means that by default it does not provide any data, it is simply the program looking at the file or folder and seeing the absolute path of it.
/// This model allows saving resources, as reading files requires additional bandwidth, memory and API usage.
abstract class RemoteView {
  final String path;
  final RemoteStorage remoteStorage;

  RemoteView(this.path, this.remoteStorage);

  bool isDirectory() {
    return this is DirectoryView;
  }

  Future<bool> delete() {
    return remoteStorage.visitor.deleteFile(path);
  }
}

/// A view of a file in the remote storage. It provides a method to read the file data, but does not read it by default.
class FileView extends RemoteView {
  FileView(super.path, super.remoteStorage);

  Future<FileData> readData() async {
    final bytes = await remoteStorage.visitor.readFile(path);
    return FileData(bytes, remoteStorage);
  }
}

/// A view of a directory in the remote storage. It provides a list of its contents, but does not read them by default.
class DirectoryView extends RemoteView {
  final List<RemoteView> contents;

  DirectoryView(super.path, super.remoteStorage, this.contents);
}

/// Information about the remote storage usage. Are files encrypted? When was it modified last time?
class RemoteInfo {
  final bool encrypted;
  final DateTime lastModified;

  RemoteInfo(this.encrypted, this.lastModified);
}

/// Remote storage accessor used to directly query, handle encryption and download changes
class RemoteStorage {
  static const databaseFile = "daily_you.db";
  final RemoteStorageVisitor visitor;
  final String rootPath;
  final EncryptionProvider? encryptionProvider;

  RemoteStorage(this.visitor, this.rootPath, this.encryptionProvider);

  /// Fetches the remote information: last modified time and encryption status
  Future<RemoteInfo?> getRemoteInfo() async {
    FileView? file = await getFile("dail_you_info.txt");
    if (file == null) {
      return null;
    }

    final fileData = await file.readData();
    // this file is never encrypted
    final content = String.fromCharCodes(fileData.getRaw());

    final lines = content.split('\n');

    bool? encrypted;
    DateTime? lastModified;

    for (String line in lines) {
      if (line.startsWith("#")) continue;

      final parts = line.split(':');
      if (parts.length != 2) continue;

      final key = parts[0].trim();
      final value = parts[1].trim();

      if (key == "encrypted") {
        encrypted = value.toLowerCase() == "true";
      } else if (key == "lastModified") {
        lastModified = DateTime.fromMillisecondsSinceEpoch(int.parse(value));
      }
    }

    if (lastModified != null && encrypted != null) {
      return RemoteInfo(encrypted, lastModified);
    }

    return null;
  }

  /// Returns a [FileView] of the file at the given path. If the file does not exist, returns null.
  Future<FileView?> getFile(String path) async {
    final absolutePath = _absolutizePath(path);
    if (await visitor.fileExists(absolutePath)) {
      return FileView(absolutePath, this);
    } else {
      return null;
    }
  }

  /// Lists the directory at the given path and returns a [DirectoryView] of it. If the directory does not exist, returns null.
  Future<DirectoryView?> listDirectory(String path) async {
    List<RemoteView> contents = [];
    String absolutePath = _absolutizePath(path);

    final entries = await visitor.listDirectory(absolutePath);
    if (entries == null) {
      return null;
    }

    for (String entry in entries) {
      if (entry.endsWith('/')) {
        final directoryView = await listDirectory(entry);
        if (directoryView != null) {
          contents.add(directoryView);
        }
      } else {
        contents.add(FileView(entry, this));
      }
    }

    return DirectoryView(path, this, contents);
  }

  Future<void> writeFile(String path, List<int> bytes) async {
    final absolutePath = _absolutizePath(path);

    if (encryptionProvider != null) {
      final encryptedBytes = await encryptionProvider!.encryptBytes(bytes);
      await visitor.writeFile(absolutePath, encryptedBytes);
    } else {
      await visitor.writeFile(absolutePath, bytes);
    }
  }

  /// Generates required directories
  Future<bool> setupDirectories() async {
    return await visitor.mkdirs(rootPath) && await visitor.mkdirs(_absolutizePath("images/"));
  }

  Future<bool> rootExists() {
    return visitor.directoryExists(rootPath);
  }

  String _absolutizePath(String path) {
    if (path.startsWith(rootPath)) {
      return path;
    }

    if (path.startsWith("/")) {
      path = path.substring(1);
    }

    if (rootPath.endsWith("/")) {
      return rootPath + path;
    } else {
      return "$rootPath/$path";
    }
  }

  /// Closes the remote storage and writes metadata if modified = true
  Future<void> close(bool modified) async {
    if (modified) {
      String infoContent =
          "# This file is used to store synchronization metadata."
          "#\n Do not modify or delete this file nor modify or delete contents of this folder unless you know exactly what you are doing as it may cause synchronization to break or lead to data loss."
          "\n# Thank you for showing interest, consider supporting this project by contributing to its source-code, translating or donating."
          "\n# https://github.com/Demizo/Daily_You";

      if (encryptionProvider != null) {
        infoContent += "\nencrypted: true";
      } else {
        infoContent += "\nencrypted: false";
      }

      infoContent += "\nlastModified: ${DateTime.now().millisecondsSinceEpoch}";

      await visitor.writeFile("", infoContent.codeUnits);
    }

    return visitor.close();
  }
}
