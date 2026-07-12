import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/models/tag.dart';

class TagDao {
  static Future<List<Tag>> getAll() async {
    final db = AppDatabase.instance.database!;
    final tagRows = await db.query(tagsTable,
        orderBy: '${TagFields.sortOrder} ASC, ${TagFields.name} ASC');
    return tagRows.map((json) => Tag.fromJson(json)).toList();
  }

  static Future<Tag?> get(int id) async {
    final db = AppDatabase.instance.database!;
    final maps = await db.query(
      tagsTable,
      columns: TagFields.values,
      where: '${TagFields.id} = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Tag.fromJson(maps.first);
  }

  static Future<Tag> add(Tag tag) async {
    final db = AppDatabase.instance.database!;
    final id = await db.insert(tagsTable, tag.toJson());
    return tag.copy(id: id);
  }

  static Future<void> update(Tag tag) async {
    final db = AppDatabase.instance.database!;
    await db.update(
      tagsTable,
      tag.toJson(),
      where: '${TagFields.id} = ?',
      whereArgs: [tag.id],
    );
  }

  static Future<void> remove(int id) async {
    final db = AppDatabase.instance.database!;
    await db.delete(
      tagsTable,
      where: '${TagFields.id} = ?',
      whereArgs: [id],
    );
  }
}
