import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/models/tag_category.dart';

class TagCategoryDao {
  static Future<List<TagCategory>> getAll() async {
    final db = AppDatabase.instance.database!;
    final rows = await db.query(tagCategoriesTable,
        orderBy:
            '${TagCategoryFields.sortOrder} ASC, ${TagCategoryFields.name} ASC');
    return rows.map((json) => TagCategory.fromJson(json)).toList();
  }

  static Future<TagCategory> add(TagCategory category) async {
    final db = AppDatabase.instance.database!;
    final id = await db.insert(tagCategoriesTable, category.toJson());
    return category.copy(id: id);
  }

  static Future<void> update(TagCategory category) async {
    final db = AppDatabase.instance.database!;
    await db.update(
      tagCategoriesTable,
      category.toJson(),
      where: '${TagCategoryFields.id} = ?',
      whereArgs: [category.id],
    );
  }

  static Future<void> remove(int id) async {
    final db = AppDatabase.instance.database!;
    await db.delete(
      tagCategoriesTable,
      where: '${TagCategoryFields.id} = ?',
      whereArgs: [id],
    );
  }
}
