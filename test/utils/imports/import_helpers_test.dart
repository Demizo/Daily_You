// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:typed_data';

import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/database/attachment_storage.dart';
import 'package:daily_you/database/entry_attachment_dao.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/storage/in_memory_file_store.dart';
import 'package:daily_you/utils/imports/import_helpers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  final time = DateTime(2025, 6, 2, 9, 30);

  late Database database;
  late InMemoryFileStore internalFiles;
  late InMemoryFileStore externalFiles;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    databaseFactory = databaseFactoryFfi;
    database = await databaseFactory.openDatabase(inMemoryDatabasePath);
    AppDatabase.instance.database = database;
    await AppDatabase.instance.createSchema(database);
    await database.insert('entries', {
      'id': 1,
      'text': '',
      'time_create': time.toIso8601String(),
      'time_modified': time.toIso8601String(),
    });

    internalFiles = InMemoryFileStore();
    externalFiles = InMemoryFileStore();
    AttachmentStorage.instance.overrideStores(internalFiles, externalFiles);
  });

  tearDown(() async {
    AttachmentStorage.instance.clearStoreOverrides();
    AppDatabase.instance.database = null;
    await database.close();
  });

  test('addImportedImage stores the image and attaches it to the entry',
      () async {
    await addImportedImage(1, Uint8List.fromList([1, 2, 3]), 4, time, {});

    final attachments = await EntryAttachmentDao.getAll();
    expect(attachments, hasLength(1));
    expect(attachments.single.entryId, 1);
    expect(attachments.single.type, AttachmentType.image);
    expect(attachments.single.rank, 4);
    expect(attachments.single.timeCreate, time);
    expect(await internalFiles.read(attachments.single.filePath),
        equals([1, 2, 3]));
  });

  test('addImportedImage leaves the upload to the sync after the import',
      () async {
    await addImportedImage(1, Uint8List.fromList([1]), 0, time, {});
    await pumpEventQueue();

    expect(await externalFiles.list(), isEmpty);
  });
}
