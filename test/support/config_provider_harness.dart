import 'dart:io';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/storage/in_memory_secret_store.dart';
import 'package:daily_you/storage/secret_store.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' show join;
import 'package:shared_preferences/shared_preferences.dart';

void useTemporaryConfig() {
  late Directory work;

  setUp(() async {
    work = await Directory.systemTemp.createTemp('daily_you_config');
    SharedPreferences.setMockInitialValues({});
    SecretStore.instance = InMemorySecretStore();
    ConfigProvider.instance.configFilePath = join(work.path, 'config.json');
    await ConfigProvider.instance.readConfig();
    await ConfigProvider.instance.loadSecureConfig();
    await ConfigProvider.instance.loadSecretStoreConfig();
  });

  tearDown(() async {
    EasyDebounce.cancelAll();
    await work.delete(recursive: true);
  });
}
