// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/config_provider.dart';

class NetworkDisabledException implements Exception {
  final String message;
  const NetworkDisabledException([this.message = 'Network access is disabled']);

  @override
  String toString() => 'NetworkDisabledException: $message';
}

class NetworkGate {
  static const bool isNetworkCompiledIn =
      bool.fromEnvironment('ENABLE_NETWORK', defaultValue: false);

  static bool? debugOverrideCompiledIn;

  static bool get isCompiledIn =>
      debugOverrideCompiledIn ?? isNetworkCompiledIn;

  static bool get isNetworkAllowed =>
      isCompiledIn &&
      ConfigProvider.instance.get(Settings.allowNetworkAccess);

  /// Throws [NetworkDisabledException] if network access is disallowed.
  static void ensureNetworkAllowed() {
    if (!isNetworkAllowed) {
      throw const NetworkDisabledException();
    }
  }
}
