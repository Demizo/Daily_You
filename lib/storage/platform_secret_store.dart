import 'package:daily_you/storage/secret_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PlatformSecretStore implements SecretStore {
  const PlatformSecretStore();

  static const _storage = FlutterSecureStorage();
  static const _probeKey = '_secret_store_probe';

  @override
  Future<bool> isAvailable() async {
    try {
      await write(_probeKey, 'ok').timeout(const Duration(seconds: 2));
      final readBack =
          await read(_probeKey).timeout(const Duration(seconds: 2));
      await delete(_probeKey);
      return readBack == 'ok';
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}
