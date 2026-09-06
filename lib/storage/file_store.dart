import 'dart:io';
import 'dart:typed_data';

import 'package:daily_you/storage/local_file_store.dart';
import 'package:daily_you/storage/saf_file_store.dart';

abstract interface class FileStore {
  factory FileStore.external(String location) =>
      Platform.isAndroid ? SafFileStore(location) : LocalFileStore(location);

  Future<bool> isAvailable();

  Future<bool> exists(String name);

  Future<List<String>> list();

  Future<Uint8List?> read(String name);

  Future<bool> write(String name, Uint8List bytes);

  Future<bool> rename(String name, String newName);

  Future<bool> delete(String name);

  Future<DateTime?> modifiedTime(String name);
}
