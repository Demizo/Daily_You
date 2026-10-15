// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' show join;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

typedef _Image = (int id, int entryId, String? path, int rank, String time);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory directory;
  late String path;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    databaseFactory = databaseFactoryFfi;
    directory = await Directory.systemTemp.createTemp('app_database_migration');
    path = join(directory.path, 'daily_you.db');
  });

  tearDown(() async {
    AppDatabase.instance.database = null;
    await directory.delete(recursive: true);
  });

  const entriesWithImagePath = '''
CREATE TABLE entries (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  text TEXT NOT NULL,
  img_path TEXT,
  mood INTEGER,
  time_create DATETIME NOT NULL DEFAULT (DATETIME('now')),
  time_modified DATETIME NOT NULL DEFAULT (DATETIME('now'))
)''';

  const entries = '''
CREATE TABLE entries (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  text TEXT NOT NULL,
  mood INTEGER,
  time_create DATETIME NOT NULL DEFAULT (DATETIME('now')),
  time_modified DATETIME NOT NULL DEFAULT (DATETIME('now'))
)''';

  const templates = '''
CREATE TABLE templates (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  text TEXT,
  time_create DATETIME NOT NULL DEFAULT (DATETIME('now')),
  time_modified DATETIME NOT NULL DEFAULT (DATETIME('now'))
)''';

  const entryImagesWithNullablePath = '''
CREATE TABLE entry_images (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    entry_id INTEGER NOT NULL,
    img_path TEXT NOY NULL,
    img_rank INTEGER NOT NULL,
    time_create DATETIME NOT NULL DEFAULT (DATETIME('now')),
    FOREIGN KEY (entry_id) REFERENCES entries (id)
)''';

  const entryImages = '''
CREATE TABLE entry_images (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    entry_id INTEGER NOT NULL,
    img_path TEXT NOT NULL,
    img_rank INTEGER NOT NULL,
    time_create DATETIME NOT NULL DEFAULT (DATETIME('now')),
    FOREIGN KEY (entry_id) REFERENCES entries (id)
)''';

  String tagTables({required bool nullableColor}) => '''
CREATE TABLE tag_categories (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    icon TEXT,
    icon_type INTEGER NOT NULL DEFAULT 0,
    name TEXT NOT NULL,
    color INTEGER,
    sort_order INTEGER NOT NULL DEFAULT 0,
    time_create DATETIME NOT NULL DEFAULT (DATETIME('now')),
    time_modified DATETIME NOT NULL DEFAULT (DATETIME('now'))
);
CREATE TABLE tags (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    category_id INTEGER,
    icon TEXT,
    icon_type INTEGER NOT NULL DEFAULT 0,
    name TEXT NOT NULL,
    tag_type INTEGER NOT NULL,
    color INTEGER${nullableColor ? '' : ' NOT NULL'},
    sort_order INTEGER NOT NULL DEFAULT 0,
    time_create DATETIME NOT NULL DEFAULT (DATETIME('now')),
    time_modified DATETIME NOT NULL DEFAULT (DATETIME('now')),
    FOREIGN KEY (category_id) REFERENCES tag_categories (id)
);
CREATE TABLE entry_tags (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    entry_id INTEGER NOT NULL,
    tag_id INTEGER NOT NULL,
    value TEXT,
    time_create DATETIME NOT NULL DEFAULT (DATETIME('now')),
    FOREIGN KEY (entry_id) REFERENCES entries (id),
    FOREIGN KEY (tag_id) REFERENCES tags (id)
)''';

  const templateTags = '''
CREATE TABLE template_tags (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    template_id INTEGER NOT NULL,
    tag_id INTEGER NOT NULL,
    time_create DATETIME NOT NULL DEFAULT (DATETIME('now')),
    FOREIGN KEY (template_id) REFERENCES templates (id),
    FOREIGN KEY (tag_id) REFERENCES tags (id)
)''';

  Future<void> executeAll(Database db, String statements) async {
    for (final statement in statements.split(';\n')) {
      await db.execute(statement);
    }
  }

  Future<void> insertImages(Database db, List<_Image> images) async {
    for (final (id, entryId, imagePath, rank, time) in images) {
      await db.insert('entry_images', {
        'id': id,
        'entry_id': entryId,
        'img_path': imagePath,
        'img_rank': rank,
        'time_create': time,
      });
    }
  }

  Future<Database> upgrade() => databaseFactory.openDatabase(path,
      options: OpenDatabaseOptions(
          version: AppDatabase.schemaVersion,
          onUpgrade: AppDatabase.instance.onUpgrade));

  Future<void> expectEveryTable(Database db) async {
    final tables = (await db.query('sqlite_master',
            columns: ['name'], where: "type = 'table'"))
        .map((table) => table['name'])
        .toSet();
    expect(
        tables,
        containsAll([
          'entries',
          'templates',
          'entry_attachments',
          'tag_categories',
          'tags',
          'entry_tags',
          'template_tags'
        ]));
    expect(tables, isNot(contains('entry_images')));
    expect(tables, isNot(contains('old_entries')));
  }

  Future<void> expectAttachments(Database db, List<_Image> expected) async {
    final rows = await db.query(attachmentsTable, orderBy: 'id');
    final attachments = rows.map(EntryAttachment.fromJson).toList();

    expect([
      for (final a in attachments)
        (a.id!, a.entryId!, a.filePath, a.rank, a.timeCreate.toIso8601String())
    ], [
      for (final (id, entryId, imagePath, rank, time) in expected)
        (id, entryId, imagePath, rank, DateTime.parse(time).toIso8601String())
    ]);
    expect(attachments.map((a) => a.type), everyElement(AttachmentType.image));
  }

  Future<void> expectNextAttachmentId(Database db, int expected) async {
    final id = await db.insert(attachmentsTable, {
      'entry_id': 1,
      'type': 'image',
      'file_path': 'next.jpg',
      'rank': 0,
    });
    expect(id, expected);
  }

  final imagesWithGaps = <_Image>[
    (1, 1, 'a.jpg', 1, '2025-06-02T09:30:00.000'),
    (2, 1, 'b.png', 0, '2025-06-02T09:31:00.000'),
    (4, 2, 'c.jpg', 0, '2025-06-03T10:00:00.000'),
    (5, 4, 'd.webp', 2, '2025-06-04T10:00:00.000'),
    (6, 4, 'e.webp', 2, '2025-06-04T10:01:00.000'),
    (7, 4, 'f.webp', 0, '2025-06-04T10:02:00.000'),
    (8, 99, 'orphan.jpg', 0, '2025-06-05T10:00:00.000'),
    (10, 2, 'g.heic', 1, '2025-06-06T10:00:00.000'),
  ];

  Future<void> insertEntries(Database db) async {
    await db.insert('entries', {'id': 1, 'text': 'one', 'mood': 2});
    await db.insert('entries', {'id': 2, 'text': 'two'});
    await db.insert('entries', {'id': 4, 'text': 'four', 'mood': 0});
  }

  Future<void> createImageDatabase(
      {required int version,
      required String entryImagesDdl,
      String extraTables = ''}) async {
    final old = await databaseFactory.openDatabase(path,
        options: OpenDatabaseOptions(
            version: version,
            onCreate: (db, _) async {
              await db.execute(entries);
              await db.execute(templates);
              await db.execute(entryImagesDdl);
              if (extraTables.isNotEmpty) await executeAll(db, extraTables);
            }));
    await insertEntries(old);
    await insertImages(old, [
      ...imagesWithGaps,
      (11, 4, 'tail.jpg', 3, '2025-06-07T10:00:00.000'),
      (12, 4, 'deleted-last.jpg', 4, '2025-06-08T10:00:00.000'),
    ]);
    await old.delete('entry_images', where: 'id IN (11, 12)');
    await old.close();
  }

  group('from schema version 6', () {
    Future<void> createVersion6(List<int?> moods) async {
      final old = await databaseFactory.openDatabase(path,
          options: OpenDatabaseOptions(
              version: 6, onCreate: (db, _) => db.execute(entries)));
      for (final (index, mood) in moods.indexed) {
        await old.insert('entries', {
          'id': index + 1,
          'text': 'entry $index',
          'mood': mood,
        });
      }
      await old.close();
    }

    test('moves each mood from the old scale onto the new one', () async {
      await createVersion6([-2, -1, 0, 1, 2, null]);

      final db = await upgrade();

      final rows = await db.query('entries', orderBy: 'id');
      expect(rows.map((row) => row['mood']), [1, 2, 3, 4, 5, null]);
      await db.close();
    });
  });

  group('from schema version 5', () {
    Future<void> createVersion5(String entryImagesDdl) => createImageDatabase(
        version: 5,
        entryImagesDdl: entryImagesDdl,
        extraTables: '${tagTables(nullableColor: true)};\n$templateTags');

    for (final (label, ddl) in [
      ('with a required path', entryImages),
      ('with a nullable path', entryImagesWithNullablePath)
    ]) {
      test('keeps every image row, id and rank $label', () async {
        await createVersion5(ddl);

        final db = await upgrade();

        await expectAttachments(db, imagesWithGaps);
        await expectEveryTable(db);
        expect(await db.query('entries'), hasLength(3));
        await db.close();
      });

      test('keeps retiring ids of deleted rows $label', () async {
        await createVersion5(ddl);

        final db = await upgrade();

        await expectNextAttachmentId(db, 13);
        await db.close();
      });
    }

    test('leaves out rows without a file name', () async {
      await createVersion5(entryImagesWithNullablePath);
      final old = await databaseFactory.openDatabase(path);
      await old.insert('entry_images', {
        'id': 13,
        'entry_id': 1,
        'img_path': null,
        'img_rank': 0,
        'time_create': '2025-06-09T10:00:00.000',
      });
      await old.insert('entry_images', {
        'id': 14,
        'entry_id': 1,
        'img_path': '',
        'img_rank': 0,
        'time_create': '2025-06-09T10:00:00.000',
      });
      await old.close();

      final db = await upgrade();

      await expectAttachments(db, imagesWithGaps);
      await expectNextAttachmentId(db, 15);
      await db.close();
    });

    test('keeps rows that share a rank', () async {
      await createVersion5(entryImages);

      final db = await upgrade();

      final ranks = await db.query(attachmentsTable,
          columns: ['rank'], where: 'entry_id = 4 AND rank = 2');
      expect(ranks, hasLength(2));
      await db.close();
    });

    test('upgrading a database without images leaves attachments empty',
        () async {
      final old = await databaseFactory.openDatabase(path,
          options: OpenDatabaseOptions(
              version: 5,
              onCreate: (db, _) async {
                await db.execute(entries);
                await db.execute(templates);
                await db.execute(entryImages);
                await executeAll(
                    db, '${tagTables(nullableColor: true)};\n$templateTags');
              }));
      await old.close();

      final db = await upgrade();

      expect(await db.query(attachmentsTable), isEmpty);
      await expectNextAttachmentId(db, 1);
      await db.close();
    });

    test('a database with many images upgrades in one pass', () async {
      final old = await databaseFactory.openDatabase(path,
          options: OpenDatabaseOptions(
              version: 5,
              onCreate: (db, _) async {
                await db.execute(entries);
                await db.execute(templates);
                await db.execute(entryImages);
                await executeAll(
                    db, '${tagTables(nullableColor: true)};\n$templateTags');
              }));
      await old.insert('entries', {'id': 1, 'text': 'one'});
      final batch = old.batch();
      for (var id = 1; id <= 20000; id++) {
        batch.insert('entry_images', {
          'id': id * 2,
          'entry_id': 1,
          'img_path': 'image_$id.jpg',
          'img_rank': id,
          'time_create': '2025-06-02T09:30:00.000',
        });
      }
      await batch.commit(noResult: true);
      await old.close();

      final db = await upgrade();

      final count =
          await db.rawQuery('SELECT COUNT(*) AS n FROM entry_attachments');
      expect(count.single['n'], 20000);
      await expectNextAttachmentId(db, 40001);
      await db.close();
    });

    test('rolls back completely and keeps the old version when a step fails',
        () async {
      await createVersion5(entryImages);
      final old = await databaseFactory.openDatabase(path);
      await old.execute('ALTER TABLE entry_images DROP COLUMN img_rank');
      await old.close();

      await expectLater(upgrade(), throwsA(anything));

      final db = await databaseFactory.openDatabase(path);
      expect(await db.getVersion(), 5);
      expect(
          await db.query('sqlite_master', where: "name = 'entry_attachments'"),
          isEmpty);
      expect(await db.query('entry_images'), hasLength(imagesWithGaps.length));
      await db.close();
    });

    test('opens a current database an older app relabelled as version 5',
        () async {
      await createVersion5(entryImages);
      final upgraded = await upgrade();
      await upgraded.close();
      final relabelled = await databaseFactory.openDatabase(path);
      await relabelled.setVersion(5);
      await relabelled.close();

      final db = await upgrade();

      await expectAttachments(db, imagesWithGaps);
      await expectEveryTable(db);
      expect(await db.getVersion(), AppDatabase.schemaVersion);
      await db.close();
    });
  });

  group('from schema version 4', () {
    test('keeps every image row, id and rank', () async {
      await createImageDatabase(
          version: 4,
          entryImagesDdl: entryImagesWithNullablePath,
          extraTables: tagTables(nullableColor: false));

      final db = await upgrade();

      await expectAttachments(db, imagesWithGaps);
      await expectEveryTable(db);
      await expectNextAttachmentId(db, 13);
      await db.close();
    });
  });

  group('from schema version 3', () {
    test('keeps every image row, id and rank', () async {
      await createImageDatabase(
          version: 3, entryImagesDdl: entryImagesWithNullablePath);

      final db = await upgrade();

      await expectAttachments(db, imagesWithGaps);
      await expectEveryTable(db);
      expect(await db.query('entries'), hasLength(3));
      expect(await db.query('tags'), isNotEmpty);
      await expectNextAttachmentId(db, 13);
      await db.close();
    });

    test('leaves out a row without a file name', () async {
      await createImageDatabase(
          version: 3, entryImagesDdl: entryImagesWithNullablePath);
      final old = await databaseFactory.openDatabase(path);
      await old.insert('entry_images', {
        'id': 13,
        'entry_id': 1,
        'img_path': null,
        'img_rank': 0,
      });
      await old.close();

      final db = await upgrade();

      await expectAttachments(db, imagesWithGaps);
      await db.close();
    });
  });

  group('from schema version 2', () {
    Future<void> createVersion2() async {
      final old = await databaseFactory.openDatabase(path,
          options: OpenDatabaseOptions(
              version: 2,
              onCreate: (db, _) async {
                await db.execute(entriesWithImagePath);
                await db.execute(templates);
              }));
      await old.insert('templates', {'id': 1, 'name': 'Mine', 'text': 'body'});
      await old.insert('entries', {
        'id': 1,
        'text': 'one',
        'img_path': 'a.jpg',
        'mood': 1,
        'time_create': '2024-03-02T09:30:00.000',
        'time_modified': '2024-03-02T09:31:00.000',
      });
      await old.insert('entries', {
        'id': 2,
        'text': 'two',
        'time_create': '2024-03-03T09:30:00.000',
      });
      await old.insert('entries', {
        'id': 5,
        'text': 'five',
        'img_path': 'b.png',
        'time_create': '2024-03-04T09:30:00.000',
      });
      await old.insert('entries', {
        'id': 6,
        'text': 'six',
        'img_path': '',
        'time_create': '2024-03-05T09:30:00.000',
      });
      await old.close();
    }

    test('turns each entry image path into an attachment', () async {
      await createVersion2();

      final db = await upgrade();

      await expectAttachments(db, [
        (1, 1, 'a.jpg', 0, '2024-03-02T09:30:00.000'),
        (2, 5, 'b.png', 0, '2024-03-04T09:30:00.000'),
      ]);
      await expectEveryTable(db);
      expect(await db.query('entries', orderBy: 'id'), [
        {
          'id': 1,
          'text': 'one',
          'mood': 4,
          'time_create': '2024-03-02T09:30:00.000',
          'time_modified': '2024-03-02T09:31:00.000',
        },
        {
          'id': 2,
          'text': 'two',
          'mood': null,
          'time_create': '2024-03-03T09:30:00.000',
          'time_modified': isA<String>(),
        },
        {
          'id': 5,
          'text': 'five',
          'mood': null,
          'time_create': '2024-03-04T09:30:00.000',
          'time_modified': isA<String>(),
        },
        {
          'id': 6,
          'text': 'six',
          'mood': null,
          'time_create': '2024-03-05T09:30:00.000',
          'time_modified': isA<String>(),
        },
      ]);
      expect(await db.query('templates', where: "name = 'Mine'"), hasLength(1));
      await db.close();
    });
  });

  group('from schema version 1', () {
    test('adds templates, then turns image paths into attachments', () async {
      final old = await databaseFactory.openDatabase(path,
          options: OpenDatabaseOptions(
              version: 1,
              onCreate: (db, _) => db.execute(entriesWithImagePath)));
      await old.insert('entries', {
        'id': 3,
        'text': 'three',
        'img_path': 'a.jpg',
        'time_create': '2023-07-02T09:30:00.000',
      });
      await old.insert('entries', {'id': 4, 'text': 'four'});
      await old.close();

      final db = await upgrade();

      await expectAttachments(db, [
        (1, 3, 'a.jpg', 0, '2023-07-02T09:30:00.000'),
      ]);
      await expectEveryTable(db);
      expect(await db.query('templates'), isNotEmpty);
      expect(await db.query('entries'), hasLength(2));
      await db.close();
    });
  });
}
