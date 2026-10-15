// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:convert';
import 'dart:io';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/storage/external_sync_settings.dart';
import 'package:daily_you/storage/in_memory_secret_store.dart';
import 'package:daily_you/storage/secret_store.dart';
import 'package:daily_you/storage/sync_item.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' show join;
import 'package:shared_preferences/shared_preferences.dart';

class _ThrowingSecretStore implements SecretStore {
  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<String?> read(String key) async =>
      throw Exception('secret store unavailable');

  @override
  Future<void> write(String key, String value) async =>
      throw Exception('secret store unavailable');

  @override
  Future<void> delete(String key) async {}
}

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
    SecretStore.instance = InMemorySecretStore();
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
    await configProvider.set(Settings.requirePassword, true);
    await configProvider.set(Settings.passwordIsPin, true);
    EasyDebounce.fire("save-config");

    await configProvider.readConfig();
    await configProvider.loadSecureConfig();

    expect(configProvider.get(Settings.requirePassword), isTrue);
    expect(configProvider.get(Settings.passwordIsPin), isTrue);
    expect(configFile.existsSync(), isFalse);
  });

  test('a secret-store setting round-trips through the secret store', () async {
    await configProvider.set(Settings.passwordHash, 'a-hash');

    await configProvider.readConfig();
    await configProvider.loadSecretStoreConfig();

    expect(configProvider.get(Settings.passwordHash), 'a-hash');
    expect(await SecretStore.instance.read(Settings.passwordHash.key),
        json.encode('a-hash'));
    expect(configFile.existsSync(), isFalse);
  });

  test('a legacy shared-preferences secret is migrated into the secret store',
      () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(Settings.passwordHash.key, json.encode('old-hash'));

    await configProvider.migrateSecretToSecretStore(Settings.passwordHash);
    await configProvider.loadSecretStoreConfig();

    expect(configProvider.get(Settings.passwordHash), 'old-hash');
    expect(prefs.getString(Settings.passwordHash.key), isNull);
  });

  test('a failed migration leaves the shared-preferences value in place',
      () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(Settings.passwordHash.key, json.encode('old-hash'));
    SecretStore.instance = _ThrowingSecretStore();

    await configProvider.migrateSecretToSecretStore(Settings.passwordHash);
    await configProvider.loadSecretStoreConfig();

    expect(configProvider.get(Settings.passwordHash), 'old-hash');
    expect(prefs.getString(Settings.passwordHash.key), json.encode('old-hash'));
  });

  group('upgrading sync settings from 3.6.1', () {
    Future<void> upgradeFrom(Map<String, Object?> stored) async {
      await configFile.writeAsString(json.encode(stored));
      await configProvider.readConfig();
      await configProvider.migrateSyncSettings();
    }

    Map<String, Object?> logAndImageFolders({
      bool logs = true,
      bool images = true,
      String logFolder = 'logs',
      String imageFolder = 'photos',
    }) =>
        {
          'useExternalDb': logs,
          'externalDbUri': logFolder,
          'useExternalImg': images,
          'externalImgUri': imageFolder,
        };

    test('a fresh install syncs nothing', () async {
      await upgradeFrom({});

      expect(ExternalSyncSettings.load(), const ExternalSyncSettings());
    });

    test('an install that never synced stays unsynced', () async {
      await upgradeFrom(logAndImageFolders(logs: false, images: false));

      expect(ExternalSyncSettings.load().isOn, isFalse);
    });

    test('logs only keeps logs and adds video and audio, not images', () async {
      await upgradeFrom(logAndImageFolders(images: false));

      final settings = ExternalSyncSettings.load();
      expect(settings.logFolderUri, 'logs');
      expect(settings.location(SyncItem.logs), (uri: 'logs', subfolder: null));
      expect(
          settings.location(SyncItem.video), (uri: 'logs', subfolder: 'Video'));
      expect(
          settings.location(SyncItem.audio), (uri: 'logs', subfolder: 'Audio'));
      expect(settings.location(SyncItem.images), isNull);
    });

    test('logs and images keep images directly in the image folder', () async {
      await upgradeFrom(logAndImageFolders());

      final settings = ExternalSyncSettings.load();
      expect(settings.location(SyncItem.logs), (uri: 'logs', subfolder: null));
      expect(
          settings.location(SyncItem.images), (uri: 'photos', subfolder: null));
      expect(
          settings.location(SyncItem.video), (uri: 'logs', subfolder: 'Video'));
    });

    test('logs and images in the same folder stay as they were', () async {
      await upgradeFrom(logAndImageFolders(imageFolder: 'logs'));

      final settings = ExternalSyncSettings.load();
      expect(settings.location(SyncItem.logs), (uri: 'logs', subfolder: null));
      expect(
          settings.location(SyncItem.images), (uri: 'logs', subfolder: null));
    });

    test('images only sync images and nothing else', () async {
      await upgradeFrom(logAndImageFolders(logs: false));

      final settings = ExternalSyncSettings.load();
      expect(settings.logFolderUri, isNull);
      expect(
          settings.location(SyncItem.images), (uri: 'photos', subfolder: null));
      expect(settings.location(SyncItem.logs), isNull);
      expect(settings.location(SyncItem.video), isNull);
      expect(settings.location(SyncItem.audio), isNull);
      expect(settings.hasLocation(SyncItem.logs), isFalse);
    });

    test('a turned off log folder left in the config is ignored', () async {
      await upgradeFrom({
        'useExternalDb': false,
        'externalDbUri': 'old-logs',
        'useExternalImg': true,
        'externalImgUri': 'photos',
      });

      final settings = ExternalSyncSettings.load();
      expect(settings.logFolderUri, isNull);
      expect(
          settings.location(SyncItem.images), (uri: 'photos', subfolder: null));
    });

    test('a turned off image folder left in the config is ignored', () async {
      await upgradeFrom(logAndImageFolders(images: false, imageFolder: 'old'));

      expect(ExternalSyncSettings.load().location(SyncItem.images), isNull);
    });

    test('an enabled folder with no address is ignored', () async {
      await upgradeFrom(logAndImageFolders(logFolder: '', imageFolder: ''));

      expect(ExternalSyncSettings.load().isOn, isFalse);
    });

    test('a folder of the wrong type is ignored', () async {
      await upgradeFrom({
        'useExternalDb': true,
        'externalDbUri': 5,
        'useExternalImg': 'yes',
        'externalImgUri': 'photos',
      });

      expect(ExternalSyncSettings.load().isOn, isFalse);
    });

    test('runs once, so later choices are kept', () async {
      await upgradeFrom(logAndImageFolders(images: false));
      await configProvider.set(Settings.syncVideo, false);

      await configProvider.migrateSyncSettings();

      expect(configProvider.get(Settings.syncVideo), isFalse);
    });

    test('does not touch other settings', () async {
      await upgradeFrom({
        ...logAndImageFolders(),
        'theme': 'amoled',
        'accentColor': 0xff112233,
      });

      expect(configProvider.get(Settings.theme), 'amoled');
      expect(configProvider.get(Settings.accentColor), 0xff112233);
    });

    group('through startup', () {
      const pathProvider = MethodChannel('plugins.flutter.io/path_provider');

      setUp(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(pathProvider, (call) async {
          if (call.method == 'getApplicationSupportDirectory') {
            return directory.path;
          }
          return null;
        });
      });

      tearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(pathProvider, null);
      });

      Future<Map<String, dynamic>> storedConfigAfterStartup() async {
        await configProvider.init();
        EasyDebounce.fire('save-config');
        for (var attempt = 0; attempt < 200; attempt++) {
          final stored = json.decode(await configFile.readAsString())
              as Map<String, dynamic>;
          if (stored['configVersion'] == '3') return stored;
          await Future.delayed(const Duration(milliseconds: 25));
        }
        fail('The migrated config was never written');
      }

      test('replaces the old keys with the new ones in the file', () async {
        await configFile.writeAsString(json.encode(logAndImageFolders()));

        final stored = await storedConfigAfterStartup();

        expect(stored.keys, isNot(contains('useExternalDb')));
        expect(stored.keys, isNot(contains('externalDbUri')));
        expect(stored.keys, isNot(contains('useExternalImg')));
        expect(stored.keys, isNot(contains('externalImgUri')));
        expect(stored['logSyncFolderUri'], 'logs');
        expect(stored['imageSyncFolderUri'], 'photos');
        expect(stored['configVersion'], '3');
      });

      test('a second launch changes nothing', () async {
        await configFile
            .writeAsString(json.encode(logAndImageFolders(images: false)));
        final first = await storedConfigAfterStartup();

        final second = await storedConfigAfterStartup();

        expect(second, first);
        expect(ExternalSyncSettings.load().location(SyncItem.images), isNull);
      });
    });
  });
}
