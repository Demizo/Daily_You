// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:sqflite/sqflite.dart';

class EntryAttachmentDao {
  static Future<List<EntryAttachment>> getAll() async {
    final result = await AppDatabase.instance.database!
        .query(attachmentsTable, orderBy: '${EntryAttachmentFields.rank} DESC');

    return result.map((json) => EntryAttachment.fromJson(json)).toList();
  }

  static Future<List<EntryAttachment>> getForEntry(int entryId) async {
    List<EntryAttachment> attachments = List.empty(growable: true);

    final maps = await AppDatabase.instance.database!.query(attachmentsTable,
        where: '${EntryAttachmentFields.entryId} = ?',
        whereArgs: [entryId],
        orderBy: '${EntryAttachmentFields.rank} DESC');

    for (final map in maps) {
      attachments.add(EntryAttachment.fromJson(map));
    }

    return attachments;
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
