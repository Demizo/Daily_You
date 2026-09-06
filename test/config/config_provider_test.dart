import 'dart:convert';
import 'dart:io';

import 'package:daily_you/config_provider.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' show join;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final configProvider = ConfigProvider.instance;
  late Directory directory;
  late File configFile;

  Future<void> waitForConfigWrite() async {
    EasyDebounce.fire("save-config");
    while (!configFile.existsSync()) {
      await Future.delayed(Duration.zero);
    }
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('config_provider_test');
    configFile = File(join(directory.path, 'config.json'));
    configProvider.configFilePath = configFile.path;
    await configProvider.readConfig();
  });

  tearDown(() async {
    EasyDebounce.cancelAll();
    await directory.delete(recursive: true);
  });

  test('an unset setting returns its declared default', () {
    expect(configProvider.get(Settings.theme), 'system');
    expect(configProvider.get(Settings.accentColor), 0xff62A0EA);
    expect(configProvider.get(Settings.showFlashbacks), isTrue);
    expect(configProvider.get(Settings.calendarTagOverlay), isNull);
  });

  test('a setting round-trips with its declared type', () async {
    await configProvider.set(Settings.theme, 'amoled');
    await configProvider.set(Settings.accentColor, 0xff112233);
    await configProvider.set(Settings.showFlashbacks, false);
    await configProvider.set(Settings.calendarTagOverlay, 7);

    expect(configProvider.get(Settings.theme), 'amoled');
    expect(configProvider.get(Settings.accentColor), 0xff112233);
    expect(configProvider.get(Settings.showFlashbacks), isFalse);
    expect(configProvider.get(Settings.calendarTagOverlay), 7);
  });

  test('a setting survives a write and read of the config file', () async {
    await configProvider.set(Settings.theme, 'light');
    await configProvider.set(Settings.accentColor, 0xff445566);
    await configProvider.set(Settings.moodOverTimeSmoothing, false);
    await waitForConfigWrite();

    await configProvider.readConfig();

    expect(configProvider.get(Settings.theme), 'light');
    expect(configProvider.get(Settings.accentColor), 0xff445566);
    expect(configProvider.get(Settings.moodOverTimeSmoothing), isFalse);
  });

  test('a stored value of the wrong type falls back to the default', () async {
    await configFile.writeAsString(json.encode({
      Settings.accentColor.key: 'not a color',
      Settings.showFlashbacks.key: 'yes',
    }));

    await configProvider.readConfig();

    expect(configProvider.get(Settings.accentColor), 0xff62A0EA);
    expect(configProvider.get(Settings.showFlashbacks), isTrue);
  });

  test('a secure setting round-trips through shared preferences', () async {
    await configProvider.set(Settings.passwordHash, 'a-hash');
    await configProvider.set(Settings.passwordIsPin, true);
    EasyDebounce.fire("save-config");

    await configProvider.readConfig();
    await configProvider.loadSecureConfig();

    expect(configProvider.get(Settings.passwordHash), 'a-hash');
    expect(configProvider.get(Settings.passwordIsPin), isTrue);
    expect(configFile.existsSync(), isFalse);
  });
}
