// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:daily_you/database/app_database.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' show join;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/config_provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  useTemporaryConfig();

  late Directory supportDirectory;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    databaseFactory = databaseFactoryFfi;
    supportDirectory =
        await Directory.systemTemp.createTemp('app_database_newer_version');
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
    AppDatabase.instance.database = null;
    await supportDirectory.delete(recursive: true);
  });

  test('refuses to open a database saved by a newer app version', () async {
    final newerVersion = AppDatabase.schemaVersion + 1;
    final path = join(supportDirectory.path, AppDatabase.databaseFileName);
    final newerDatabase = await databaseFactory.openDatabase(path,
        options: OpenDatabaseOptions(
            version: newerVersion,
            onCreate: (db, _) =>
                db.execute('CREATE TABLE future (id INTEGER)')));
    await newerDatabase.close();

    await expectLater(
        AppDatabase.instance.init(allowMigration: false),
        throwsA(isA<DatabaseNewerThanAppException>().having(
            (e) => e.databaseVersion, 'databaseVersion', newerVersion)));

    expect(AppDatabase.instance.database, isNull);
    final untouched = await databaseFactory.openDatabase(path);
    expect(await untouched.getVersion(), newerVersion);
    await untouched.close();
  });

  group('canOpen', () {
    Future<String> databaseAt(String name, int version) async {
      final path = join(supportDirectory.path, name);
      final database = await databaseFactory.openDatabase(path,
          options: OpenDatabaseOptions(
              version: version,
              onCreate: (db, _) =>
                  db.execute('CREATE TABLE entries (id INTEGER)')));
      await database.close();
      return path;
    }

    test('accepts a database from this or an older app version', () async {
      expect(
          await AppDatabase.instance.canOpen(
              await databaseAt('current.db', AppDatabase.schemaVersion)),
          isTrue);
      expect(
          await AppDatabase.instance.canOpen(await databaseAt('older.db', 1)),
          isTrue);
    });

    test('refuses a database saved by a newer app version', () async {
      final path = await databaseAt('newer.db', AppDatabase.schemaVersion + 1);

      await expectLater(AppDatabase.instance.canOpen(path),
          throwsA(isA<DatabaseNewerThanAppException>()));
    });

    test('rejects an empty file', () async {
      final path = join(supportDirectory.path, 'empty.db');
      await File(path).create();

      expect(await AppDatabase.instance.canOpen(path), isFalse);
    });

    test('rejects a database that was never set up', () async {
      final path = join(supportDirectory.path, 'unset.db');
      final database = await databaseFactory.openDatabase(path);
      await database.execute('CREATE TABLE entries (id INTEGER)');
      await database.close();

      expect(await AppDatabase.instance.canOpen(path), isFalse);
    });

    test('rejects a database without entries', () async {
      final path = join(supportDirectory.path, 'other.db');
      final database = await databaseFactory.openDatabase(path,
          options: OpenDatabaseOptions(
              version: AppDatabase.schemaVersion,
              onCreate: (db, _) => db.execute('CREATE TABLE t (id INTEGER)')));
      await database.close();

      expect(await AppDatabase.instance.canOpen(path), isFalse);
    });

    test('rejects a file that is not a database', () async {
      final path = join(supportDirectory.path, 'garbage.db');
      await File(path).writeAsString('not a database' * 100);

      expect(await AppDatabase.instance.canOpen(path), isFalse);
    });
  });
}
