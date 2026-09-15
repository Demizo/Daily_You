import 'package:daily_you/storage/secret_store.dart';

class InMemorySecretStore implements SecretStore {
  final Map<String, String> _values = {};

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);
}
