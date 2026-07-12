import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/models/tag.dart';

class EntryTagDao {
  static Future<List<EntryTag>> getAll() async {
    final db = AppDatabase.instance.database!;
    final result = await db.query(entryTagsTable);
    return result.map((json) => EntryTag.fromJson(json)).toList();
  }

  static Future<EntryTag> add(EntryTag entryTag) async {
    final db = AppDatabase.instance.database!;
    final id = await db.insert(entryTagsTable, entryTag.toJson());
    return entryTag.copy(id: id);
  }

  static Future<void> update(EntryTag entryTag) async {
    final db = AppDatabase.instance.database!;
    await db.update(
      entryTagsTable,
      entryTag.toJson(),
      where: '${EntryTagFields.id} = ?',
      whereArgs: [entryTag.id],
    );
  }

  static Future<void> remove(int id) async {
    final db = AppDatabase.instance.database!;
    await db.delete(
      entryTagsTable,
      where: '${EntryTagFields.id} = ?',
      whereArgs: [id],
    );
  }

  static Future<void> removeAllForEntry(int entryId) async {
    final db = AppDatabase.instance.database!;
    await db.delete(
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
