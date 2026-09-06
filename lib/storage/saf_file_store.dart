import 'dart:typed_data';

import 'package:daily_you/storage/file_store.dart';
import 'package:saf_util/saf_util.dart';
import 'package:shared_storage/shared_storage.dart' as saf;

class SafFileStore implements FileStore {
  SafFileStore(this.treeUri);

  final String treeUri;

  Uri get _tree => Uri.parse(treeUri);

  Future<saf.DocumentFile?> _child(String name,
          {bool requiresWriteAccess = true}) =>
      saf.child(_tree, name, requiresWriteAccess: requiresWriteAccess);

  @override
  Future<bool> isAvailable() async {
    return await saf.exists(_tree) == true && await saf.canWrite(_tree) == true;
  }

  @override
  Future<bool> exists(String name) async =>
      await (await _child(name, requiresWriteAccess: false))?.exists() ?? false;

  @override
  Future<List<String>> list() async {
    const columns = <saf.DocumentFileColumn>[
      saf.DocumentFileColumn.displayName,
      saf.DocumentFileColumn.mimeType,
    ];

    final names = List<String>.empty(growable: true);
    await for (final document in saf.listFiles(_tree, columns: columns)) {
      if (document.isFile == true && document.name != null) {
        names.add(document.name!);
      }
    }
    return names;
  }

  @override
  Future<Uint8List?> read(String name) async {
    final document = await _child(name);
    return document != null ? await document.getContent() : null;
  }

  @override
  Future<bool> write(String name, Uint8List bytes) async {
    final document = await _child(name);
    if (document == null) {
      final created = await saf.createFileAsBytes(_tree,
          mimeType: "*/*", displayName: name, bytes: bytes);
      return created != null;
    }
    return await saf.writeToFileAsBytes(document.uri, bytes: bytes) ?? false;
  }

  @override
  Future<bool> rename(String name, String newName) async {
    final document = await _child(name);
    if (document == null) return false;
    final renamed =
        await SafUtil().rename(document.uri.toString(), false, newName);
    return renamed.name == newName;
  }

  @override
  Future<bool> delete(String name) async {
    final document = await _child(name, requiresWriteAccess: false);
    if (document == null) return true;
    return await document.delete() ?? false;
  }

  @override
  Future<DateTime?> modifiedTime(String name) async =>
      (await _child(name))?.lastModified;
}
