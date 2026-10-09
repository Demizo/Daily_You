// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/config_provider.dart';
import 'package:daily_you/utils/screen_protection.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/config_provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  useTemporaryConfig();

  group('ScreenProtection', () {
    const channel = MethodChannel('com.demizo.daily_you.dyf/security');
    final log = <MethodCall>[];

    setUp(() {
      ScreenProtection.isAndroidOverride = true;
      log.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        log.add(call);
        if (call.method == 'setSecureMode') {
          return true;
        }
        return null;
      });
    });

    tearDown(() {
      ScreenProtection.isAndroidOverride = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('default setting is false', () {
      expect(ConfigProvider.instance.get(Settings.screenProtection), isFalse);
    });

    test('invokes setSecureMode with enabled state', () async {
      await ConfigProvider.instance.set(Settings.screenProtection, true);
      final result = await ScreenProtection.setSecureMode(true);
      expect(result, isTrue);
      expect(log.last.method, 'setSecureMode');
      expect(log.last.arguments, {'secure': true});

      final resultDisabled = await ScreenProtection.setSecureMode(false);
      expect(resultDisabled, isTrue);
      expect(log.last.arguments, {'secure': false});
    });
  });
}
