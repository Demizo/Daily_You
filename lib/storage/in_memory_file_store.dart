import 'dart:typed_data';

import 'package:daily_you/storage/file_store.dart';

class InMemoryFileStore implements FileStore {
  InMemoryFileStore({this.reportsSizes = true});

  /// Some Android providers list every size as 0.
  final bool reportsSizes;

  final Map<String, Uint8List> _bytesByName = {};
  final Map<String, DateTime> _modifiedTimeByName = {};

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> exists(String name) async => _bytesByName.containsKey(name);

  @override
  Future<List<String>> list() async => _bytesByName.keys.toList();

  @override
  Future<List<StoredFile>> listFiles() async => [
        for (final MapEntry(key: name, value: bytes) in _bytesByName.entries)
          StoredFile(name, reportsSizes ? bytes.length : 0)
      ];

  @override
  Future<Uint8List?> read(String name) async => _bytesByName[name];

  @override
  Future<bool> write(String name, Uint8List bytes) async {
    _bytesByName[name] = Uint8List.fromList(bytes);
    _modifiedTimeByName[name] = DateTime.now();
    return true;
  }

  @override
  Future<bool> rename(String name, String newName) async {
    final bytes = _bytesByName.remove(name);
    if (bytes == null) return false;
    _bytesByName[newName] = bytes;
    _modifiedTimeByName[newName] =
        _modifiedTimeByName.remove(name) ?? DateTime.now();
    return true;
  }

  @override
  Future<bool> delete(String name) async {
    _bytesByName.remove(name);
    _modifiedTimeByName.remove(name);
    return true;
  }

  @override
  Future<DateTime?> modifiedTime(String name) async =>
      _modifiedTimeByName[name];
}
