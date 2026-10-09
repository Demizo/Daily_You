// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/config_provider.dart';
import 'package:daily_you/utils/network_gate.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/config_provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  useTemporaryConfig();

  group('NetworkGate', () {
    tearDown(() {
      NetworkGate.debugOverrideCompiledIn = null;
    });

    test('network access is disabled by default', () {
      expect(ConfigProvider.instance.get(Settings.allowNetworkAccess), isFalse);
      expect(NetworkGate.isNetworkAllowed, isFalse);
      expect(
        () => NetworkGate.ensureNetworkAllowed(),
        throwsA(isA<NetworkDisabledException>()),
      );
    });

    test('network access requires both compiledIn and user setting', () async {
      NetworkGate.debugOverrideCompiledIn = true;
      expect(NetworkGate.isNetworkAllowed, isFalse);

      await ConfigProvider.instance.set(Settings.allowNetworkAccess, true);
      expect(NetworkGate.isNetworkAllowed, isTrue);
      expect(() => NetworkGate.ensureNetworkAllowed(), returnsNormally);

      NetworkGate.debugOverrideCompiledIn = false;
      expect(NetworkGate.isNetworkAllowed, isFalse);
      expect(
        () => NetworkGate.ensureNetworkAllowed(),
        throwsA(isA<NetworkDisabledException>()),
      );
    });
  });
}
