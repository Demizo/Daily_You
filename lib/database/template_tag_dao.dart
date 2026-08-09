import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/models/tag.dart';

class TemplateTagDao {
  static Future<List<TemplateTag>> getAll() async {
    final db = AppDatabase.instance.database!;
    final result = await db.query(templateTagsTable);
    return result.map((json) => TemplateTag.fromJson(json)).toList();
  }

  static Future<TemplateTag> add(TemplateTag templateTag) async {
    final db = AppDatabase.instance.database!;
    final id = await db.insert(templateTagsTable, templateTag.toJson());
    return templateTag.copy(id: id);
  }

  static Future<void> remove(int id) async {
    final db = AppDatabase.instance.database!;
    await db.delete(
      templateTagsTable,
      where: '${TemplateTagFields.id} = ?',
      whereArgs: [id],
    );
  }

  static Future<void> removeAllForTemplate(int templateId) async {
    final db = AppDatabase.instance.database!;
    await db.delete(
      templateTagsTable,
      where: '${TemplateTagFields.templateId} = ?',
      whereArgs: [templateId],
    );
  }

  static Future<void> removeAllForTag(int tagId) async {
    final db = AppDatabase.instance.database!;
    await db.delete(
      templateTagsTable,
      where: '${TemplateTagFields.tagId} = ?',
      whereArgs: [tagId],
    );
  }
}
