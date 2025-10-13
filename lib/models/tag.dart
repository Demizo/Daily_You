import 'package:daily_you/entries_database.dart';

const String tagsTable = 'tags';

class TagsFields {
  static const List<String> values = [id, name, timeCreate, timeModified];
  static const String id = 'id';
  static const String name = 'name';
  static const String type = 'type';
  static const String timeCreate = 'time_create';
  static const String timeModified = 'time_modified';
}

class TagType {
  static const String tag = "tag";
  static const String rating = "rating";
}

class BuiltInTag {
  static const String mood = "Mood";
  static const String favorite = "Favorite";
}

class Tag {
  final int? id;
  final String name;
  final String type;
  final DateTime timeCreate;
  final DateTime timeModified;

  const Tag({
    this.id,
    required this.name,
    required this.type,
    required this.timeCreate,
    required this.timeModified,
  });

  Tag copy({
    int? id,
    String? name,
    String? type,
    DateTime? timeCreate,
    DateTime? timeModified,
  }) =>
      Tag(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        timeCreate: timeCreate ?? this.timeCreate,
        timeModified: timeModified ?? this.timeModified,
      );

  static Tag fromJson(Map<String, Object?> json) => Tag(
        id: json[TagsFields.id] as int?,
        name: json[TagsFields.name] as String,
        type: json[TagsFields.type] as String,
        timeCreate: DateTime.parse(json[TagsFields.timeCreate] as String),
        timeModified: DateTime.parse(json[TagsFields.timeModified] as String),
      );

  Map<String, Object?> toJson() => {
        TagsFields.id: id,
        TagsFields.name: name,
        TagsFields.type: type,
        TagsFields.timeCreate: timeCreate.toIso8601String(),
        TagsFields.timeModified: timeModified.toIso8601String(),
      };

  // Database Interactions

  static Future createDefaultTags() async {
    await createTag(Tag(
        name: BuiltInTag.mood,
        type: TagType.rating,
        timeCreate: DateTime.now(),
        timeModified: DateTime.now()));

    await createTag(Tag(
        name: BuiltInTag.favorite,
        type: TagType.tag,
        timeCreate: DateTime.now(),
        timeModified: DateTime.now()));
  }

  static Future<Tag> createTag(Tag tag) async {
    final db = EntriesDatabase.instance.database!;

    final id = await db.insert(tagsTable, tag.toJson());
    if (EntriesDatabase.instance.usingExternalDb()) {
      await EntriesDatabase.instance.updateExternalDatabase();
    }
    return tag.copy(id: id);
  }

  static Future<Tag?> getTag(int id) async {
    final db = EntriesDatabase.instance.database!;

    final maps = await db.query(
      tagsTable,
      columns: TagsFields.values,
      where: '${TagsFields.id} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Tag.fromJson(maps.first);
    } else {
      return null;
    }
  }

  static Future<List<Tag>> getAllTags() async {
    final db = EntriesDatabase.instance.database!;

    final result =
        await db.query(tagsTable, orderBy: '${TagsFields.name} DESC');

    return result.map((json) => Tag.fromJson(json)).toList();
  }

  static Future<int> updateTag(Tag tag) async {
    final db = EntriesDatabase.instance.database!;

    final id = await db.update(
      tagsTable,
      tag.toJson(),
      where: '${TagsFields.id} = ?',
      whereArgs: [tag.id],
    );

    if (EntriesDatabase.instance.usingExternalDb()) {
      await EntriesDatabase.instance.updateExternalDatabase();
    }
    return id;
  }

  static Future<int> deleteTag(int id) async {
    final db = EntriesDatabase.instance.database!;

    final removedId = await db.delete(
      tagsTable,
      where: '${TagsFields.id} = ?',
      whereArgs: [id],
    );

    if (EntriesDatabase.instance.usingExternalDb()) {
      await EntriesDatabase.instance.updateExternalDatabase();
    }
    return removedId;
  }
}
