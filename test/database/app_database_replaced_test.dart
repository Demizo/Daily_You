// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/storage/external_sync_settings.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' show join;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/config_provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  useTemporaryConfig();

  late Directory root;
  late Directory supportDirectory;
  late Directory externalDirectory;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    databaseFactory = databaseFactoryFfi;
    root = await Directory.systemTemp.createTemp('app_database_replaced');
    supportDirectory = await Directory(join(root.path, 'support')).create();
    externalDirectory = await Directory(join(root.path, 'external')).create();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => switch (call.method) {
                  'getApplicationSupportDirectory' => supportDirectory.path,
                  _ => null,
                });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'), null);
    if (AppDatabase.instance.database != null) {
      await AppDatabase.instance.close();
    }
    await root.delete(recursive: true);
  });

  test('a created database counts as replaced, an existing one does not',
      () async {
    await AppDatabase.instance.init();
    expect(AppDatabase.instance.databaseReplacedThisSession, isTrue);
    await AppDatabase.instance.close();

    await AppDatabase.instance.init();

    expect(AppDatabase.instance.databaseReplacedThisSession, isFalse);
  });

  test('a database pulled from the external folder counts as replaced',
      () async {
    await AppDatabase.instance.init();
    await AppDatabase.instance.close();
    final pulled =
        await File(join(supportDirectory.path, AppDatabase.databaseFileName))
            .copy(join(externalDirectory.path, AppDatabase.databaseFileName));
    await pulled.setLastModified(DateTime.now().add(const Duration(days: 1)));
    await ExternalSyncSettings.withDefaults(externalDirectory.path).save();

    await AppDatabase.instance.init();

    expect(AppDatabase.instance.databaseReplacedThisSession, isTrue);
  });
}
