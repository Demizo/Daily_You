// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:typed_data';

import 'package:daily_you/storage/file_store.dart';
import 'package:logging/logging.dart';
import 'package:saf_util/saf_util.dart';
import 'package:shared_storage/shared_storage.dart' as saf;

class SafFileStore implements FileStore {
  SafFileStore(this.treeUri);

  final String treeUri;

  final Logger _logger = Logger('SafFileStore');

  Uri get _tree => Uri.parse(treeUri);

  /// Another app may rename files, so an entry is used only while it still
  /// has the listed name.
  Map<String, Uri> _listedDocuments = {};

  Future<Uri?> _listedDocument(String name) async {
    final listed = _listedDocuments[name];
    if (listed == null) return null;
    return (await saf.fromTreeUri(listed))?.name == name ? listed : null;
  }

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
  Future<List<String>> list() async =>
      [for (final file in await listFiles()) file.name];

  @override
  Future<List<StoredFile>> listFiles() async {
    const columns = <saf.DocumentFileColumn>[
      saf.DocumentFileColumn.displayName,
      saf.DocumentFileColumn.mimeType,
      saf.DocumentFileColumn.size,
      saf.DocumentFileColumn.id,
    ];

    final files = List<StoredFile>.empty(growable: true);
    final documents = <String, Uri>{};
    await for (final document in saf.listFiles(_tree, columns: columns)) {
      final name = document.name;
      if (document.isFile == true && name != null) {
        files.add(StoredFile(name, document.size ?? 0));
        documents[name] = document.uri;
      }
    }
    _listedDocuments = documents;
    return files;
  }

  @override
  Future<Uint8List?> read(String name) async {
    final listed = await _listedDocument(name);
    if (listed != null) return saf.getDocumentContent(listed);
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
  Future<CreateResult> createNew(String name, Uint8List bytes) async {
    final created = await saf.createFileAsBytes(_tree,
        mimeType: "*/*", displayName: name, bytes: bytes);
    if (created == null) return CreateResult.failed;
    final createdName = created.name;
    if (createdName == name) return CreateResult.created;
    // Without a name the outcome is unknown, so nothing is deleted
    if (createdName == null || createdName.isEmpty) return CreateResult.failed;

    // A different name means a collision occurred
    if (await saf.delete(created.uri) != true) {
      _logger.warning('could not delete $createdName after $name collided');
    }
    return CreateResult.alreadyExists;
  }

  @override
  Future<bool> delete(String name) async {
    final listed = await _listedDocument(name);
    _listedDocuments.remove(name);
    if (listed != null) return await saf.delete(listed) == true;
    final document = await _child(name, requiresWriteAccess: false);
    if (document == null) return true;
    return await document.delete() ?? false;
  }

  @override
  Future<DateTime?> modifiedTime(String name) async =>
      (await _child(name))?.lastModified;
}
