import 'dart:typed_data';

import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/synchronization/encryption_provider.dart';
import 'package:daily_you/synchronization/providers/widgets/webdav_widget.dart';
import 'package:daily_you/synchronization/remote_storage.dart';
import 'package:daily_you/synchronization/synchronization_provider.dart';
import 'package:flutter/material.dart';
import 'package:webdav_client/webdav_client.dart';

/*
WebDav testing: docker run --rm -p 8080:8080 -v ./data:/data -e RCLONE_USER=username -e RCLONE_PASS=password rclone/rclone:1.71.2 serve webdav /data --addr :8080 --baseurl '/webdav'
 */
class WebdavProvider extends SynchronizationProvider {
  @override
  Future<bool> authorize() async {
    try {
      // Verify required credentials are present.
      final hasCredentials = await Future.wait([
        hasSecret('server_url'),
        hasSecret('username'),
        hasSecret('password'),
      ]);

      if (!hasCredentials.every((exists) => exists)) {
        return false;
      }

      final client = await _createClient();
      final path =
          await getSecret('path', defaultValue: '/daily-you/');

      try {
        await client.ping();
        await client.mkdirAll(path!);

        return true;
      } catch (e) {
        return false;
      }
    } catch (_) {
      return false;
    }
  }

  @override
  Future<RemoteStorage?> getRemoteStorage() async {
    final path = await getSecret('path', defaultValue: '/daily-you/');
    final visitor = _WebdavRemoteStorageVisitor(await _createClient());
    return RemoteStorage(visitor, path!, isEncryptionEnabled() ? await getEncryptionProvider() : null);
  }

  Future<Client> _createClient() async {
    final serverUrl = await getSecret('server_url');
    final username = await getSecret('username');
    final password = await getSecret('password');

    if (serverUrl == null || username == null || password == null) {
      throw Exception('Missing WebDAV credentials');
    }

    var client = newClient(serverUrl, user: username, password: password);
    client.setHeaders({'accept-charset': 'utf-8'});

    // Set the connection server timeout time in milliseconds.
    client.setConnectTimeout(8000);

    // Set send data timeout time in milliseconds.
    client.setSendTimeout(8000);

    // Set transfer data time in milliseconds.
    client.setReceiveTimeout(8000);
    return client;
  }

  @override
  StatefulWidget getSettingsWidget() {
    return WebdavSettingsWidget(provider: this);
  }

  @override
  String getId() {
    return "webdav";
  }
}

class _WebdavRemoteStorageVisitor extends RemoteStorageVisitor {
  final Client _client;

  _WebdavRemoteStorageVisitor(this._client);
  @override
  Future<void> close() async {
    // Do nothing, as the WebDAV client does not maintain a persistent connection that needs to be closed.
  }

  @override
  Future<bool> deleteFile(String path) async {
    try {
      await _client.remove(path);
      return true;
    } catch(err) {
      return false;
    }
  }

  @override
  Future<bool> deleteDirectory(String path) async {
    // Some WebDav services require trailing slashes for directories
    if (!path.endsWith("/")) {
      path += "/";
    }
    return deleteFile(path);
  }

  @override
  Future<bool> fileExists(String path) async {
    try {
      await _client.readProps(path);
      return true;
    } catch(err) {
      return false;
    }
  }

  @override
  Future<bool> directoryExists(String path) {
    if (!path.endsWith("/")) {
      path += "/";
    }
    return fileExists(path);
  }

  @override
  Future<Iterable<String>?> listDirectory(String path) async {
    if (!path.endsWith("/")) {
      path += "/";
    }
    if (!(await fileExists(path))) {
      return null;
    }
    try {
      final files = await _client.readDir(path);
      return files.map((f) => f.path!);
    } catch(err) {
      return null;
    }
  }

  @override
  Future<List<int>> readFile(String path) {
    return _client.read(path);
  }

  @override
  Future<void> writeFile(String path, List<int> bytes) {
    return _client.write(path, Uint8List.fromList(bytes));
  }

  @override
  Future<bool> mkdirs(String path) async {
    try {
      await _client.mkdirAll(path);
      return true;
    } catch(err) {
      return false;
    }
  }
}