// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/config_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/config_provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  useTemporaryConfig();

  group('Flexible Reminders & Launch Preferences (F06)', () {
    test('default settings', () {
      expect(ConfigProvider.instance.get(Settings.reminderDays), '1,2,3,4,5,6,7');
      expect(ConfigProvider.instance.get(Settings.alwaysOpenNewLog), isFalse);
    });

    test('can configure specific reminder weekdays', () async {
      await ConfigProvider.instance.set(Settings.reminderDays, '1,3,5');
      expect(ConfigProvider.instance.get(Settings.reminderDays), '1,3,5');

      final days = ConfigProvider.instance
          .get(Settings.reminderDays)
          .split(',')
          .map(int.parse)
          .toList();
      expect(days, [1, 3, 5]);
    });

    test('can toggle alwaysOpenNewLog', () async {
      await ConfigProvider.instance.set(Settings.alwaysOpenNewLog, true);
      expect(ConfigProvider.instance.get(Settings.alwaysOpenNewLog), isTrue);
    });
  });
}
