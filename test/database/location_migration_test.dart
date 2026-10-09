// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'dart:io';

import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/database/entry_location_dao.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/location.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('migrates database from v6 to v7 preserving existing data', () async {
    final dbFactory = databaseFactoryFfi;
    final tempDir = await Directory.systemTemp.createTemp('db_location_migration_');
    final dbPath = join(tempDir.path, 'test_location_migration.db');

    try {
      // 1. Create a version 6 database
      final dbV6 = await dbFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 6,
          onCreate: (db, version) async {
            await db.execute('''
CREATE TABLE $entriesTable (
  ${EntryFields.id} INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  ${EntryFields.text} TEXT NOT NULL,
  ${EntryFields.mood} INTEGER,
  ${EntryFields.timeCreate} DATETIME NOT NULL DEFAULT (DATETIME('now')),
  ${EntryFields.timeModified} DATETIME NOT NULL DEFAULT (DATETIME('now'))
);
''');
          },
        ),
      );

      final now = DateTime.now().toIso8601String();
      await dbV6.rawInsert('''
INSERT INTO $entriesTable (id, text, mood, time_create, time_modified)
VALUES (99, 'Log before location table', 2, '$now', '$now')
''');
      await dbV6.close();

      // 2. Open with upgrade to version 7
      final upgradedDb = await dbFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 7,
          onUpgrade: (db, oldVersion, newVersion) async {
            if (oldVersion <= 6) {
              await db.execute('''
CREATE TABLE $entryLocationsTable (
    ${EntryLocationFields.id} INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    ${EntryLocationFields.entryId} INTEGER NOT NULL,
    ${EntryLocationFields.latitude} REAL,
    ${EntryLocationFields.longitude} REAL,
    ${EntryLocationFields.placeName} TEXT,
    ${EntryLocationFields.timeCreate} DATETIME NOT NULL DEFAULT (DATETIME('now')),
    FOREIGN KEY (${EntryLocationFields.entryId}) REFERENCES $entriesTable (id)
);
''');
            }
          },
        ),
      );

      AppDatabase.instance.database = upgradedDb;

      // 3. Verify existing data preserved
      final entries = await upgradedDb.query(entriesTable);
      expect(entries.length, 1);
      expect(entries.first['text'], 'Log before location table');

      // 4. Verify entry_locations table functions properly
      final loc = await EntryLocationDao.setForEntry(EntryLocation(
        entryId: 99,
        placeName: 'Yosemite National Park',
        latitude: 37.8651,
        longitude: -119.5383,
        timeCreate: DateTime.now(),
      ));
      expect(loc.id, isNotNull);

      final fetched = await EntryLocationDao.getForEntry(99);
      expect(fetched, isNotNull);
      expect(fetched!.placeName, 'Yosemite National Park');
      expect(fetched.latitude, closeTo(37.8651, 0.0001));

      await EntryLocationDao.removeForEntry(99);
      expect(await EntryLocationDao.getForEntry(99), isNull);

      await upgradedDb.close();
    } finally {
      if (await tempDir.exists()) {
        try {
          await tempDir.delete(recursive: true);
        } catch (_) {}
      }
    }
  });
}
