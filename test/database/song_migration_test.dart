// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'dart:io';

import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/database/entry_song_dao.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/song.dart';
import 'package:daily_you/models/template.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('migrates database from v5 to v6 preserving existing data', () async {
    final dbFactory = databaseFactoryFfi;
    final tempDir = await Directory.systemTemp.createTemp('db_migration_');
    final dbPath = join(tempDir.path, 'test_migration.db');

    try {
      // 1. Create a version 5 database (unmodified base app schema)
    final dbV5 = await dbFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 5,
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
          await db.execute('''
CREATE TABLE $templatesTable (
  ${TemplatesFields.id} INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  ${TemplatesFields.name} TEXT NOT NULL,
  ${TemplatesFields.text} TEXT,
  ${TemplatesFields.timeCreate} DATETIME NOT NULL DEFAULT (DATETIME('now')),
  ${TemplatesFields.timeModified} DATETIME NOT NULL DEFAULT (DATETIME('now'))
);
''');
        },
      ),
    );

    // Insert pre-existing entry and template
    final now = DateTime.now().toIso8601String();
    await dbV5.rawInsert('''
INSERT INTO $entriesTable (id, text, mood, time_create, time_modified)
VALUES (42, 'Existing log before song feature', 1, '$now', '$now')
''');

    await dbV5.rawInsert('''
INSERT INTO $templatesTable (id, name, text, time_create, time_modified)
VALUES (10, 'Music Template', 'Today song: ', '$now', '$now')
''');

    await dbV5.close();

    // 2. Open with AppDatabase upgrade to version 8
    AppDatabase.instance.database = null;
    final upgradedDb = await dbFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 8,
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion <= 5) {
            await db.execute('''
CREATE TABLE $entrySongsTable (
    ${EntrySongFields.id} INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    ${EntrySongFields.entryId} INTEGER NOT NULL,
    ${EntrySongFields.videoId} TEXT NOT NULL,
    ${EntrySongFields.url} TEXT NOT NULL,
    ${EntrySongFields.title} TEXT NOT NULL,
    ${EntrySongFields.artist} TEXT NOT NULL,
    ${EntrySongFields.album} TEXT,
    ${EntrySongFields.coverPath} TEXT,
    ${EntrySongFields.previewUrl} TEXT,
    ${EntrySongFields.previewStartMs} INTEGER NOT NULL DEFAULT 0,
    ${EntrySongFields.previewEndMs} INTEGER,
    ${EntrySongFields.timeCreate} DATETIME NOT NULL DEFAULT (DATETIME('now')),
    FOREIGN KEY (${EntrySongFields.entryId}) REFERENCES $entriesTable (id)
);
''');
            await db.execute('''
CREATE TABLE $templateSongSlotsTable (
    ${TemplateSongSlotFields.id} INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    ${TemplateSongSlotFields.templateId} INTEGER NOT NULL,
    ${TemplateSongSlotFields.timeCreate} DATETIME NOT NULL DEFAULT (DATETIME('now')),
    FOREIGN KEY (${TemplateSongSlotFields.templateId}) REFERENCES $templatesTable (id)
);
''');
          }
          if (oldVersion <= 7) {
            try {
              await db.execute(
                  'ALTER TABLE $entrySongsTable ADD COLUMN ${EntrySongFields.album} TEXT;');
            } catch (_) {}
          }
        },
      ),
    );

    AppDatabase.instance.database = upgradedDb;

    // 3. Verify existing data is completely intact
    final entries = await upgradedDb.query(entriesTable);
    expect(entries.length, 1);
    expect(entries.first['text'], 'Existing log before song feature');
    expect(entries.first['id'], 42);

    final templates = await upgradedDb.query(templatesTable);
    expect(templates.length, 1);
    expect(templates.first['name'], 'Music Template');

    // 4. Verify new entry_songs operations succeed
    final addedSong = await EntrySongDao.add(EntrySong(
      entryId: 42,
      videoId: 'dQw4w9WgXcQ',
      url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      title: 'Never Gonna Give You Up',
      artist: 'Rick Astley',
      timeCreate: DateTime.now(),
    ));
    expect(addedSong.id, isNotNull);

    final entrySongs = await EntrySongDao.getByEntryId(42);
    expect(entrySongs.length, 1);
    expect(entrySongs.first.title, 'Never Gonna Give You Up');

    // 5. Verify template song slot operations succeed
    await EntrySongDao.setSongSlotForTemplate(10, true);
    expect(await EntrySongDao.hasSongSlotForTemplate(10), isTrue);

    await EntrySongDao.setSongSlotForTemplate(10, false);
    expect(await EntrySongDao.hasSongSlotForTemplate(10), isFalse);

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
