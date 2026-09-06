import 'dart:io';
import 'dart:typed_data';

import 'package:daily_you/storage/file_store.dart';
import 'package:path/path.dart';

class LocalFileStore implements FileStore {
  LocalFileStore(this.directoryPath);

  final String directoryPath;

  File _fileFor(String name) => File(join(directoryPath, name));

  @override
  Future<bool> isAvailable() => Directory(directoryPath).exists();

  @override
  Future<bool> exists(String name) => _fileFor(name).exists();

  @override
  Future<List<String>> list() async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) return List.empty(growable: true);

    final names = List<String>.empty(growable: true);
    await for (final entity in directory.list()) {
      if (entity is File) names.add(basename(entity.path));
    }
    return names;
  }

  @override
  Future<Uint8List?> read(String name) async {
    final file = _fileFor(name);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  @override
  Future<bool> write(String name, Uint8List bytes) async {
    await _fileFor(name).writeAsBytes(bytes, flush: true);
    return true;
  }

  @override
  Future<bool> rename(String name, String newName) async {
    final file = _fileFor(name);
    if (!await file.exists()) return false;
    await file.rename(join(directoryPath, newName));
    return true;
  }

  @override
  Future<bool> delete(String name) async {
    final file = _fileFor(name);
    if (await file.exists()) await file.delete();
    return true;
  }

  @override
  Future<DateTime?> modifiedTime(String name) async {
    final file = _fileFor(name);
    if (!await file.exists()) return null;
    return file.lastModified();
  }
}
