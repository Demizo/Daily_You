// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/config_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/config_provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  useTemporaryConfig();

  group('Calendar Streaks & Indicators (F01)', () {
    test('default calendar streaks setting is true', () {
      expect(ConfigProvider.instance.get(Settings.calendarStreaks), isTrue);
    });

    test('can toggle calendar streaks setting', () async {
      await ConfigProvider.instance.set(Settings.calendarStreaks, false);
      expect(ConfigProvider.instance.get(Settings.calendarStreaks), isFalse);

      await ConfigProvider.instance.set(Settings.calendarStreaks, true);
      expect(ConfigProvider.instance.get(Settings.calendarStreaks), isTrue);
    });
  });
}
