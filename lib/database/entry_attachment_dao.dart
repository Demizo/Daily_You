// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:logging/logging.dart';
import 'package:sqflite/sqflite.dart';

class EntryAttachmentDao {
  static final Logger _logger = Logger('EntryAttachmentDao');

  static List<EntryAttachment> _parse(List<Map<String, Object?>> rows) {
    final attachments = <EntryAttachment>[];
    for (final row in rows) {
      final attachment = EntryAttachment.tryFromJson(row);
      if (attachment == null) {
        _logger.warning(
            'Skipping attachment ${row[EntryAttachmentFields.id]} of unknown type ${row[EntryAttachmentFields.type]}');
      } else {
        attachments.add(attachment);
      }
    }
    return attachments;
  }

  static Future<List<EntryAttachment>> getAll() async {
    final result = await AppDatabase.instance.database!
        .query(attachmentsTable, orderBy: '${EntryAttachmentFields.rank} DESC');

    return _parse(result);
  }

  static Future<List<EntryAttachment>> getForEntry(int entryId) async {
    final maps = await AppDatabase.instance.database!.query(attachmentsTable,
        where: '${EntryAttachmentFields.entryId} = ?',
        whereArgs: [entryId],
        orderBy: '${EntryAttachmentFields.rank} DESC');

    return _parse(maps);
  }

  static Future<EntryAttachment> add(EntryAttachment attachment,
      {DatabaseExecutor? executor}) async {
    final id = await AppDatabase.executorOr(executor)
        .insert(attachmentsTable, attachment.toJson());

    return attachment.copy(id: id);
  }

  static Future<void> remove(EntryAttachment attachment,
      {DatabaseExecutor? executor}) async {
    await AppDatabase.executorOr(executor).delete(
      attachmentsTable,
      where: '${EntryAttachmentFields.id} = ?',
      whereArgs: [attachment.id],
    );
  }

  static Future<void> update(EntryAttachment attachment,
      {DatabaseExecutor? executor}) async {
    await AppDatabase.executorOr(executor).update(
      attachmentsTable,
      attachment.toJson(),
      where: '${EntryAttachmentFields.id} = ?',
      whereArgs: [attachment.id],
    );
  }
}
