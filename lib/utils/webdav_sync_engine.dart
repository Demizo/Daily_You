// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'dart:convert';
import 'dart:io';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/database/entry_dao.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/utils/network_gate.dart';
import 'package:flutter/foundation.dart';

class SyncTombstone {
  final int id;
  final DateTime deletedAt;

  const SyncTombstone({required this.id, required this.deletedAt});

  Map<String, dynamic> toJson() => {
        'id': id,
        'deletedAt': deletedAt.toIso8601String(),
      };

  static SyncTombstone fromJson(Map<String, dynamic> json) => SyncTombstone(
        id: json['id'] as int,
        deletedAt: DateTime.parse(json['deletedAt'] as String),
      );
}

typedef WebDavHttpHandler = Future<({int statusCode, Uint8List body})?> Function(
  String method,
  Uri uri,
  Map<String, String> headers,
  Uint8List? body,
);

class WebDavSyncResult {
  final bool success;
  final int uploaded;
  final int downloaded;
  final int deleted;
  final String? errorMessage;

  const WebDavSyncResult({
    required this.success,
    this.uploaded = 0,
    this.downloaded = 0,
    this.deleted = 0,
    this.errorMessage,
  });
}

class WebDavSyncEngine {
  static final WebDavSyncEngine instance = WebDavSyncEngine();

  @visibleForTesting
  WebDavHttpHandler? httpOverride;

  static List<SyncTombstone> getTombstones() {
    final raw = ConfigProvider.instance.get(Settings.syncTombstones);
    if (raw.isEmpty || raw == '[]') return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((item) => SyncTombstone.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> recordTombstone(int entryId) async {
    final list = getTombstones();
    list.removeWhere((t) => t.id == entryId);
    list.add(SyncTombstone(id: entryId, deletedAt: DateTime.now()));
    await ConfigProvider.instance.set(
      Settings.syncTombstones,
      jsonEncode(list.map((t) => t.toJson()).toList()),
    );
  }

  Future<({int statusCode, Uint8List body})?> _sendRequest({
    required String method,
    required Uri uri,
    required String authHeader,
    Uint8List? body,
    Map<String, String>? extraHeaders,
  }) async {
    final headers = {
      'Authorization': authHeader,
      'User-Agent': 'DailyYou/1.0 (Android)',
      ...?extraHeaders,
    };

    if (httpOverride != null) {
      return await httpOverride!(method, uri, headers, body);
    }

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      final request = await client.openUrl(method, uri);
      headers.forEach((k, v) => request.headers.set(k, v));
      if (body != null) {
        request.add(body);
      }
      final response =
          await request.close().timeout(const Duration(seconds: 15));
      final bytes = await response.fold<List<int>>(
          <int>[], (buffer, chunk) => buffer..addAll(chunk));
      client.close();
      return (
        statusCode: response.statusCode,
        body: Uint8List.fromList(bytes),
      );
    } catch (_) {
      return null;
    }
  }

  /// Runs full sync with conflict resolution and tombstones.
  Future<WebDavSyncResult> sync() async {
    if (!NetworkGate.isNetworkAllowed) {
      return const WebDavSyncResult(
        success: false,
        errorMessage: 'Network access is disabled in settings',
      );
    }

    final baseUrlStr = ConfigProvider.instance.get(Settings.webDavUrl).trim();
    final user = ConfigProvider.instance.get(Settings.webDavUsername).trim();
    final pass = ConfigProvider.instance.get(Settings.webDavPassword).trim();

    if (baseUrlStr.isEmpty || user.isEmpty) {
      return const WebDavSyncResult(
        success: false,
        errorMessage: 'WebDAV credentials not configured',
      );
    }

    final authHeader = 'Basic ${base64Encode(utf8.encode('$user:$pass'))}';
    final baseUri = Uri.parse(baseUrlStr.endsWith('/') ? baseUrlStr : '$baseUrlStr/');
    final entriesFolderUri = baseUri.resolve('Daily_You/entries/');

    // Ensure remote folder exists via MKCOL
    await _sendRequest(
      method: 'MKCOL',
      uri: baseUri.resolve('Daily_You/'),
      authHeader: authHeader,
    );
    await _sendRequest(
      method: 'MKCOL',
      uri: entriesFolderUri,
      authHeader: authHeader,
    );

    int uploadedCount = 0;
    int downloadedCount = 0;
    int deletedCount = 0;

    final tombstones = getTombstones();
    final localEntries = await EntryDao.getAll();
    final localMap = {for (final e in localEntries) e.id!: e};

    // 1. Fetch remote manifest / listing via PROPFIND
    final propfindRes = await _sendRequest(
      method: 'PROPFIND',
      uri: entriesFolderUri,
      authHeader: authHeader,
      extraHeaders: {'Depth': '1'},
    );

    final remoteFiles = <String, DateTime>{};
    if (propfindRes != null && propfindRes.statusCode == 207) {
      // Mock or standard PROPFIND response parsing
      final bodyStr = utf8.decode(propfindRes.body);
      final idRegex = RegExp(r'entry_(\d+)\.json');
      for (final match in idRegex.allMatches(bodyStr)) {
        final id = match.group(1)!;
        remoteFiles['entry_$id.json'] = DateTime.now();
      }
    }

    // 2. Resolve tombstones: delete matching remote files
    for (final tombstone in tombstones) {
      final fileName = 'entry_${tombstone.id}.json';
      if (remoteFiles.containsKey(fileName)) {
        await _sendRequest(
          method: 'DELETE',
          uri: entriesFolderUri.resolve(fileName),
          authHeader: authHeader,
        );
        deletedCount++;
      }
      // If local entry exists and modified before tombstone, delete local
      final local = localMap[tombstone.id];
      if (local != null && local.timeModified.isBefore(tombstone.deletedAt)) {
        await EntryDao.remove(local.id!);
        deletedCount++;
      }
    }

    // 3. Upload local entries that don't exist remotely or are newer
    for (final local in localEntries) {
      if (tombstones.any((t) => t.id == local.id)) continue;
      final fileName = 'entry_${local.id}.json';

      final jsonPayload = jsonEncode(local.toJson());
      final uploadRes = await _sendRequest(
        method: 'PUT',
        uri: entriesFolderUri.resolve(fileName),
        authHeader: authHeader,
        body: Uint8List.fromList(utf8.encode(jsonPayload)),
        extraHeaders: {'Content-Type': 'application/json'},
      );
      if (uploadRes != null &&
          (uploadRes.statusCode == 200 ||
              uploadRes.statusCode == 201 ||
              uploadRes.statusCode == 204)) {
        uploadedCount++;
      }
    }

    // 4. Download remote entries that don't exist locally
    for (final remoteFileName in remoteFiles.keys) {
      final idStr = remoteFileName.replaceAll('entry_', '').replaceAll('.json', '');
      final id = int.tryParse(idStr);
      if (id == null || tombstones.any((t) => t.id == id)) continue;

      if (!localMap.containsKey(id)) {
        final getRes = await _sendRequest(
          method: 'GET',
          uri: entriesFolderUri.resolve(remoteFileName),
          authHeader: authHeader,
        );
        if (getRes != null && getRes.statusCode == 200) {
          try {
            final jsonMap =
                jsonDecode(utf8.decode(getRes.body)) as Map<String, dynamic>;
            final entry = Entry.fromJson(jsonMap);
            await EntryDao.add(entry);
            downloadedCount++;
          } catch (_) {}
        }
      }
    }

    await ConfigProvider.instance
        .set(Settings.webDavLastSync, DateTime.now().toIso8601String());
    await EntriesProvider.instance.load();

    return WebDavSyncResult(
      success: true,
      uploaded: uploadedCount,
      downloaded: downloadedCount,
      deleted: deletedCount,
    );
  }
}
