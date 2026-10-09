// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/config_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/config_provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  useTemporaryConfig();

  group('Theme Customization & Palette Styles (F14)', () {
    test('default palette style and app font', () {
      expect(ConfigProvider.instance.get(Settings.paletteStyle), 'tonalSpot');
      expect(ConfigProvider.instance.get(Settings.appFont), 'system');
    });

    test('can configure palette style and bundled font preferences', () async {
      await ConfigProvider.instance.set(Settings.paletteStyle, 'vibrant');
      expect(ConfigProvider.instance.get(Settings.paletteStyle), 'vibrant');

      await ConfigProvider.instance.set(Settings.appFont, 'monospace');
      expect(ConfigProvider.instance.get(Settings.appFont), 'monospace');
    });
  });
}
