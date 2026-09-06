import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/models/tag.dart';
import 'package:sqflite/sqflite.dart';

class EntryTagDao {
  static Future<List<EntryTag>> getAll() async {
    final db = AppDatabase.instance.database!;
    final result = await db.query(entryTagsTable);
    return result.map((json) => EntryTag.fromJson(json)).toList();
  }

  static Future<EntryTag> add(EntryTag entryTag,
      {DatabaseExecutor? executor}) async {
    final id = await AppDatabase.executorOr(executor)
        .insert(entryTagsTable, entryTag.toJson());
    return entryTag.copy(id: id);
  }

  static Future<void> update(EntryTag entryTag,
      {DatabaseExecutor? executor}) async {
    await AppDatabase.executorOr(executor).update(
      entryTagsTable,
      entryTag.toJson(),
      where: '${EntryTagFields.id} = ?',
      whereArgs: [entryTag.id],
    );
  }

  static Future<void> remove(int id, {DatabaseExecutor? executor}) async {
    await AppDatabase.executorOr(executor).delete(
      entryTagsTable,
      where: '${EntryTagFields.id} = ?',
      whereArgs: [id],
    );
  }

  static Future<void> removeAllForEntry(int entryId,
      {DatabaseExecutor? executor}) async {
    await AppDatabase.executorOr(executor).delete(
      entryTagsTable,
      where: '${EntryTagFields.entryId} = ?',
      whereArgs: [entryId],
    );
  }

  static Future<void> removeAllForTag(int tagId) async {
    final db = AppDatabase.instance.database!;
    await db.delete(
      entryTagsTable,
      where: '${EntryTagFields.tagId} = ?',
      whereArgs: [tagId],
    );
  }
}
