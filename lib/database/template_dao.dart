import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/models/template.dart';

class TemplateDao {
  static Future<List<Template>> getAll() async {
    final db = AppDatabase.instance.database!;

    final result =
        await db.query(templatesTable, orderBy: '${TemplatesFields.name} ASC');

    return result.map((json) => Template.fromJson(json)).toList();
  }

  static Future<Template?> get(int id) async {
    final db = AppDatabase.instance.database!;

    final maps = await db.query(
      templatesTable,
      columns: TemplatesFields.values,
      where: '${TemplatesFields.id} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Template.fromJson(maps.first);
    } else {
      return null;
    }
  }

  static Future<Template> add(Template template) async {
    final db = AppDatabase.instance.database!;
    final id = await db.insert(templatesTable, template.toJson());
    return template.copy(id: id);
  }

  static Future<void> update(Template template) async {
    final db = AppDatabase.instance.database!;

    await db.update(
      templatesTable,
      template.toJson(),
      where: '${TemplatesFields.id} = ?',
      whereArgs: [template.id],
    );
  }

  static Future<void> remove(int id) async {
    final db = AppDatabase.instance.database!;

    await db.delete(
      templatesTable,
      where: '${TemplatesFields.id} = ?',
      whereArgs: [id],
    );
  }
}
