import 'dart:typed_data';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/database/entry_dao.dart';
import 'package:daily_you/database/image_storage.dart';
import 'package:daily_you/file_layer.dart';
import 'package:daily_you/synchronization/encryption_provider.dart';
import 'package:daily_you/synchronization/patching/conflict.dart';
import 'package:daily_you/synchronization/providers/webdav_provider.dart';
import 'package:daily_you/synchronization/remote_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';

enum SynchronizationResultStatus {
  success,
  failure,
  conflict,
  unauthorized,
  encryptionMismatch
}

class SynchronizationResult {
  final SynchronizationResultStatus status;
  final List<EntryConflict>? conflicts;

  SynchronizationResult(this.status, {this.conflicts});
}

abstract class SynchronizationProvider {
  final _secretStorage = FlutterSecureStorage();
  EncryptionProvider? _encryptionProvider;

  Future<RemoteStorage?> getRemoteStorage();
  Future<bool> authorize();
  Future<void> storeSecret(String key, String value) {
    return _secretStorage.write(key: "$getId()_$key", value: value);
  }
  Future<String?> getSecret(String key, {String? defaultValue}) async {
    if (await _secretStorage.containsKey(key: "$getId()_$key")) {
      return _secretStorage.read(key: key);
    } else {
      return defaultValue;
    }
  }
  Future<void> deleteSecret(String key) {
    return _secretStorage.delete(key: "$getId()_$key");
  }
  Future<bool> hasSecret(String key) {
    return _secretStorage.containsKey(key: "$getId()_$key");
  }
  StatefulWidget getSettingsWidget();

  /// An important method that should be constant and return the id of this provider.
  /// The id is used for per provider secret storage.
  String getId();

  /// Returns the [EncryptionProvider] if an encryption key is set, otherwise generates an encryption key and returns a new [EncryptionProvider] with the generated key.
  Future<EncryptionProvider?> getEncryptionProvider() async {
    if (await hasSecret("encryption_key")) {
      if (_encryptionProvider != null) {
        return _encryptionProvider;
      }

      _encryptionProvider = EncryptionProvider((await getSecret("encryption_key"))!);
      return _encryptionProvider;
    } else {
      // Generate a new encryption key and store it
      final newKey = EncryptionProvider.generateEncryptionKey();
      await _secretStorage.write(key: "encryption_key", value: newKey);
      _encryptionProvider = EncryptionProvider(newKey);
      return _encryptionProvider;
    }
  }

  Future<bool> hasEncryptionKey() {
    return _secretStorage.containsKey(key: "encryption_key");
  }

  void setKey(String key) async {
    await _secretStorage.write(key: "encryption_key", value: key);
    _encryptionProvider = null;
  }

  bool isEncryptionEnabled() {
    return ConfigProvider.instance.get(ConfigKey.syncEncryptionEnabled);
  }

  Future<SynchronizationResult> synchronize() async {
    try {
      if (!await authorize()) {
        return SynchronizationResult(SynchronizationResultStatus.unauthorized);
      }

      final remote = await getRemoteStorage();
      if (remote == null) return SynchronizationResult(SynchronizationResultStatus.failure);

      // Is this a new synchronization target whatsoever?
      bool newRemote = false;
      final rootExists = await remote.rootExists();
      if (!rootExists) {
        newRemote = true;
      }

      // Used to change how conflicts are resolved in cases of edited entries
      bool localAhead = false;
      bool encrypted = isEncryptionEnabled();
      final databaseFileView = await remote.getFile(RemoteStorage.databaseFile);

      if (!newRemote && databaseFileView != null) {
        final info = await remote.getRemoteInfo();

        if (info == null) {
          localAhead = true;
        } else {
          if (info.encrypted != isEncryptionEnabled()) {
            return SynchronizationResult(
                SynchronizationResultStatus.encryptionMismatch);
          }

          final lastSyncLocal = await getSecret("last_sync", defaultValue: "0");

          int? lastSyncLocalMillis = int.tryParse(lastSyncLocal!);

          lastSyncLocalMillis ??= 0;

          localAhead =
              DateTime.fromMillisecondsSinceEpoch(lastSyncLocalMillis).isAfter(
                  info.lastModified);
        }
      } else {
        if (!await remote.setupDirectories()) {
          return SynchronizationResult(SynchronizationResultStatus.failure);
        }

        // This is a new remote so just upload the files and that's it
        final bytes = await AppDatabase.instance.getDatabaseBytes();
        await remote.writeFile(RemoteStorage.databaseFile, bytes!);

        final imageFolderPath = await ImageStorage.instance.getInternalFolder();
        final imagePaths = await FileLayer.listFiles(imageFolderPath);

        for (String imageFileName in imagePaths) {
          await remote.writeFile("images/$imageFileName", (await FileLayer.getFileBytes("$imageFolderPath/$imageFileName"))!.toList());
        }

        await remote.close(true);
        return SynchronizationResult(SynchronizationResultStatus.success);
      }

      // Ok so this remote exists, well let's check for conflicts
      FileData databaseData = await databaseFileView.readData();
      List<int> databaseBytes;
      if (encrypted) {
        databaseBytes = await databaseData.getDecrypted();
      } else {
        databaseBytes = databaseData.getRaw();
      }

      // Write to a temp file
      final String tempFilePath = "daily_you_remote_temp.db";

      if (!await FileLayer.writeFileBytes(tempFilePath, Uint8List.fromList(databaseBytes))) {
        return SynchronizationResult(SynchronizationResultStatus.failure);
      }

      final remoteDB = await openDatabase(tempFilePath);



      // TODO: handle this correctly
      throw UnimplementedError();
    } catch(err) {
      // TODO: perhaps better error handling
      return SynchronizationResult(SynchronizationResultStatus.failure);
    }
  }
}

class ProviderFactory {
  static const List<String> supportedProviders = ['webdav', 'dropbox'];
  static SynchronizationProvider createProvider(String type) {
    switch (type) {
      case 'webdav':
        return WebdavProvider();
      case 'dropbox':
        throw UnimplementedError('DropboxProvider not implemented yet');
      default:
        throw ArgumentError('Unknown provider type: $type');
    }
  }
}