import 'package:daily_you/storage/platform_secret_store.dart';

abstract interface class SecretStore {
  static SecretStore instance = const PlatformSecretStore();

  Future<bool> isAvailable();

  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}
