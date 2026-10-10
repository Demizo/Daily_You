// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:typed_data';

import 'package:daily_you/storage/file_store.dart';

class InMemoryFileStore implements FileStore {
  InMemoryFileStore(
      {this.reportsSizes = true, this.uniqueNamesOnCollision = false});

  /// Some Android providers list every size as 0.
  final bool reportsSizes;

  /// Creating onto a taken name picks a unique name.
  final bool uniqueNamesOnCollision;

  /// Writes keep this many bytes, then throw.
  int? writesStopAfter;

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
    final limit = writesStopAfter;
    final stops = limit != null && limit < bytes.length;
    _bytesByName[name] =
        Uint8List.fromList(stops ? bytes.sublist(0, limit) : bytes);
    _modifiedTimeByName[name] = DateTime.now();
    if (stops) throw Exception('write of $name stopped after $limit bytes');
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
  Future<CreateResult> createNew(String name, Uint8List bytes) async {
    final createdName = _freeName(name);
    if (_bytesByName.containsKey(createdName)) {
      return CreateResult.alreadyExists;
    }
    if (!await write(createdName, bytes)) return CreateResult.failed;
    if (createdName == name) return CreateResult.created;
    await delete(createdName);
    return CreateResult.alreadyExists;
  }

  String _freeName(String name) {
    if (!uniqueNamesOnCollision) return name;
    var candidate = name;
    for (var counter = 1; _bytesByName.containsKey(candidate); counter++) {
      candidate = '$name ($counter)';
    }
    return candidate;
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
