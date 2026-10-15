// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  final provider = EntryAttachmentsProvider.instance;
  final time = DateTime(2025, 6, 2, 9, 30);

  late Database database;

  EntryAttachment attachment(int entryId, AttachmentType type, int rank) =>
      EntryAttachment(
          entryId: entryId,
          type: type,
          filePath: '$entryId-$rank-${type.name}',
          rank: rank,
          timeCreate: time);

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    databaseFactory = databaseFactoryFfi;
    database = await databaseFactory.openDatabase(inMemoryDatabasePath);
    AppDatabase.instance.database = database;
    await AppDatabase.instance.createSchema(database);
    await provider.load();
  });

  tearDown(() async {
    AppDatabase.instance.database = null;
    await database.close();
  });

  test('adding keeps cover candidates ordered and skips audio', () async {
    for (final added in [
      attachment(1, AttachmentType.image, 0),
      attachment(1, AttachmentType.audio, 5),
      attachment(1, AttachmentType.video, 2),
      attachment(2, AttachmentType.image, 1),
    ]) {
      await provider.add(added, skipUpdate: true);
    }

    expect(provider.getCoverCandidatesForEntry(1).map((a) => a.rank), [2, 0]);
    expect(provider.getCoverCandidatesForEntry(2).map((a) => a.rank), [1]);
    expect(provider.getCoverCandidatesForEntry(3), isEmpty);
  });
}
