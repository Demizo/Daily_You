// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/config_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/config_provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  useTemporaryConfig();

  group('Editor Settings (F08, F11)', () {
    test('default settings are enabled', () {
      expect(ConfigProvider.instance.get(Settings.keyboardAutocorrect), isTrue);
      expect(
          ConfigProvider.instance.get(Settings.keyboardCapitalization), isTrue);
      expect(ConfigProvider.instance.get(Settings.markdownEnabled), isTrue);
    });

    test('can toggle editor preferences', () async {
      await ConfigProvider.instance.set(Settings.keyboardAutocorrect, false);
      expect(
          ConfigProvider.instance.get(Settings.keyboardAutocorrect), isFalse);

      await ConfigProvider.instance.set(Settings.keyboardCapitalization, false);
      expect(ConfigProvider.instance.get(Settings.keyboardCapitalization),
          isFalse);

      await ConfigProvider.instance.set(Settings.markdownEnabled, false);
      expect(ConfigProvider.instance.get(Settings.markdownEnabled), isFalse);
    });
  });
}
