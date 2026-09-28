import 'dart:io';
import 'dart:typed_data';

import 'package:daily_you/storage/local_file_store.dart';
import 'package:daily_you/storage/saf_file_store.dart';

enum CreateResult { created, alreadyExists, failed }

class StoredFile {
  const StoredFile(this.name, this.size);

  final String name;

  /// 0 when the file is empty or the store can't report its size.
  final int size;
}

abstract interface class FileStore {
  factory FileStore.external(String location) =>
      Platform.isAndroid ? SafFileStore(location) : LocalFileStore(location);

  Future<bool> isAvailable();

  Future<bool> exists(String name);

  Future<List<String>> list();

  /// Throws on a reported listing error. A listing can still miss files
  /// silently.
  Future<List<StoredFile>> listFiles();

  Future<Uint8List?> read(String name);

  Future<bool> write(String name, Uint8List bytes);

  Future<bool> rename(String name, String newName);

  /// Never replaces an existing [name].
  Future<CreateResult> createNew(String name, Uint8List bytes);

  Future<bool> delete(String name);

  Future<DateTime?> modifiedTime(String name);
}
