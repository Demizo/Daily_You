// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'dart:io';

import 'package:daily_you/storage/file_store.dart';
import 'package:daily_you/storage/local_file_store.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class SongStorage {
  static final SongStorage instance = SongStorage._init();
  SongStorage._init();

  FileStore? _store;

  @visibleForTesting
  void overrideStore(FileStore store) {
    _store = store;
  }

  @visibleForTesting
  void clearStoreOverride() {
    _store = null;
  }

  Future<FileStore> store() async {
    return _store ??= LocalFileStore(await getInternalFolder());
  }

  Future<String> getInternalFolder() async {
    final basePath = await getApplicationSupportDirectory();
    final coversDir = Directory(join(basePath.path, 'SongCovers'));
    if (!coversDir.existsSync()) coversDir.createSync(recursive: true);
    return coversDir.path;
  }

  Future<String?> saveCover(String fileName, Uint8List bytes) async {
    try {
      final s = await store();
      await s.write(fileName, bytes);
      return fileName;
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> getBytes(String fileName) async {
    try {
      final s = await store();
      return await s.read(fileName);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteCover(String fileName) async {
    try {
      final s = await store();
      await s.delete(fileName);
    } catch (_) {}
  }
}
