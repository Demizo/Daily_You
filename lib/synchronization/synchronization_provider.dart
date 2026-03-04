enum SynchronizationResult {
  success,
  failure,
  conflict,
  unauthorized,
}

abstract class SynchronizationProvider {
  late final String name;
  late final List<String> requiredUrls;

  Future<SynchronizationResult> synchronize();
  Future<bool> authorize();
  Future<void> storeSecret(String key, String value);
  Future<String?> getSecret(String key);
  Future<void> deleteSecret(String key);
}