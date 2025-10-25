import 'package:daily_you/entries_database.dart';

const String templatesTable = 'templates';

class TemplatesFields {
  static const List<String> values = [id, name, text, timeCreate, timeModified];
  static const String id = 'id';
  static const String name = 'name';
  static const String text = 'text';
  static const String timeCreate = 'time_create';
  static const String timeModified = 'time_modified';
}

class Template {
  final int? id;
  final String name;
  final String? text;
  final DateTime timeCreate;
  final DateTime timeModified;

  const Template({
    this.id,
    required this.name,
    this.text,
    required this.timeCreate,
    required this.timeModified,
  });

  Template copy({
    int? id,
    String? name,
    String? text,
    DateTime? timeCreate,
    DateTime? timeModified,
  }) =>
      Template(
        id: id ?? this.id,
        name: name ?? this.name,
        text: text ?? this.text,
        timeCreate: timeCreate ?? this.timeCreate,
        timeModified: timeModified ?? this.timeModified,
      );

  static Template fromJson(Map<String, Object?> json) => Template(
        id: json[TemplatesFields.id] as int?,
        name: json[TemplatesFields.name] as String,
        text: json[TemplatesFields.text] as String?,
        timeCreate: DateTime.parse(json[TemplatesFields.timeCreate] as String),
        timeModified:
            DateTime.parse(json[TemplatesFields.timeModified] as String),
      );

  Map<String, Object?> toJson() => {
        TemplatesFields.id: id,
        TemplatesFields.name: name,
        TemplatesFields.text: text,
        TemplatesFields.timeCreate: timeCreate.toIso8601String(),
        TemplatesFields.timeModified: timeModified.toIso8601String(),
      };

  // Database Interactions

  static Future<Template> create(Template template) async {
    final db = EntriesDatabase.instance.database!;

    final id = await db.insert(templatesTable, template.toJson());
    if (EntriesDatabase.instance.usingExternalDb()) {
      await EntriesDatabase.instance.updateExternalDatabase();
    }
    return template.copy(id: id);
  }

  static Future<Template?> get(int id) async {
    final db = EntriesDatabase.instance.database!;

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

  static Future<List<Template>> getAll() async {
    final db = EntriesDatabase.instance.database!;

    final result =
        await db.query(templatesTable, orderBy: '${TemplatesFields.name} ASC');

    return result.map((json) => Template.fromJson(json)).toList();
  }

  static Future<int> update(Template template) async {
    final db = EntriesDatabase.instance.database!;

    final id = await db.update(
      templatesTable,
      template.toJson(),
      where: '${TemplatesFields.id} = ?',
      whereArgs: [template.id],
    );

    if (EntriesDatabase.instance.usingExternalDb()) {
      await EntriesDatabase.instance.updateExternalDatabase();
    }
    return id;
  }

  static Future<int> delete(int id) async {
    final db = EntriesDatabase.instance.database!;

    final removedId = await db.delete(
      templatesTable,
      where: '${TemplatesFields.id} = ?',
      whereArgs: [id],
    );

    if (EntriesDatabase.instance.usingExternalDb()) {
      await EntriesDatabase.instance.updateExternalDatabase();
    }
    return removedId;
  }
}
