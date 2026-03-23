import 'package:daily_you/synchronization/encryption_provider.dart';
import 'package:daily_you/synchronization/providers/webdav_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum SynchronizationResult {
  success,
  failure,
  conflict,
  unauthorized,
}

abstract class SynchronizationProvider {
  final storage = FlutterSecureStorage();
  EncryptionProvider? _encryptionProvider;
  Future<SynchronizationResult> synchronize({bool? preferRemote});
  Future<bool> authorize();
  Future<void> storeSecret(String key, String value) {
    return storage.write(key: key, value: value);
  }
  Future<String?> getSecret(String key, {String? defaultValue}) async {
    if (await storage.containsKey(key: key)) {
      return storage.read(key: key);
    } else {
      return defaultValue;
    }
  }
  Future<void> deleteSecret(String key) {
    return storage.delete(key: key);
  }
  Future<bool> hasSecret(String key) {
    return storage.containsKey(key: key);
  }
  StatefulWidget getSettingsWidget();

  /// Null if encryption key not found
  Future<EncryptionProvider?> getEncryptionProvider() async {
    if (await storage.containsKey(key: "encryption_key")) {
      if (_encryptionProvider != null) {
        return _encryptionProvider;
      }

      _encryptionProvider = EncryptionProvider((await storage.read(key: "encryption_key"))!);
      return _encryptionProvider;
    } else {
      _encryptionProvider = null;
      return null;
    }
  }

  void setKey(String key) async {
    await storage.write(key: "encryption_key", value: key);
    _encryptionProvider = null;
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