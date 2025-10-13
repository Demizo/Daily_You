import 'package:daily_you/entries_database.dart';

const String entryTagsTable = 'entryTags';

class EntryTagsFields {
  static const List<String> values = [
    id,
    entryId,
    tagId,
    value,
    timeCreate,
    timeModified
  ];
  static const String id = 'id';
  static const String entryId = 'entry_id';
  static const String tagId = 'tag_id';
  static const String value = 'value';
  static const String timeCreate = 'time_create';
  static const String timeModified = 'time_modified';
}

class EntryTag {
  final int? id;
  final int entryId;
  final int tagId;
  final int? value;
  final DateTime timeCreate;
  final DateTime timeModified;

  const EntryTag({
    this.id,
    required this.entryId,
    required this.tagId,
    this.value,
    required this.timeCreate,
    required this.timeModified,
  });

  EntryTag copy({
    int? id,
    int? entryId,
    int? tagId,
    int? value,
    DateTime? timeCreate,
    DateTime? timeModified,
  }) =>
      EntryTag(
        id: id ?? this.id,
        entryId: entryId ?? this.entryId,
        tagId: tagId ?? this.tagId,
        value: value ?? this.value,
        timeCreate: timeCreate ?? this.timeCreate,
        timeModified: timeModified ?? this.timeModified,
      );

  static EntryTag fromJson(Map<String, Object?> json) => EntryTag(
        id: json[EntryTagsFields.id] as int?,
        entryId: json[EntryTagsFields.entryId] as int,
        tagId: json[EntryTagsFields.tagId] as int,
        value: json[EntryTagsFields.value] as int?,
        timeCreate: DateTime.parse(json[EntryTagsFields.timeCreate] as String),
        timeModified:
            DateTime.parse(json[EntryTagsFields.timeModified] as String),
      );

  Map<String, Object?> toJson() => {
        EntryTagsFields.id: id,
        EntryTagsFields.entryId: entryId,
        EntryTagsFields.tagId: tagId,
        EntryTagsFields.value: value,
        EntryTagsFields.timeCreate: timeCreate.toIso8601String(),
        EntryTagsFields.timeModified: timeModified.toIso8601String(),
      };

  // Database Interactions

  static Future<EntryTag> create(EntryTag entryTag) async {
    final db = EntriesDatabase.instance.database!;

    final id = await db.insert(entryTagsTable, entryTag.toJson());
    if (EntriesDatabase.instance.usingExternalDb()) {
      await EntriesDatabase.instance.updateExternalDatabase();
    }
    return entryTag.copy(id: id);
  }

  static Future<EntryTag?> get(int id) async {
    final db = EntriesDatabase.instance.database!;

    final maps = await db.query(
      entryTagsTable,
      columns: EntryTagsFields.values,
      where: '${EntryTagsFields.id} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return EntryTag.fromJson(maps.first);
    } else {
      return null;
    }
  }

  static Future<List<EntryTag>> getAll() async {
    final db = EntriesDatabase.instance.database!;

    final result = await db.query(entryTagsTable,
        orderBy: '${EntryTagsFields.timeCreate} DESC');

    return result.map((json) => EntryTag.fromJson(json)).toList();
  }

  static Future<int> update(EntryTag entryTag) async {
    final db = EntriesDatabase.instance.database!;

    final id = await db.update(
      entryTagsTable,
      entryTag.toJson(),
      where: '${EntryTagsFields.id} = ?',
      whereArgs: [entryTag.id],
    );

    if (EntriesDatabase.instance.usingExternalDb()) {
      await EntriesDatabase.instance.updateExternalDatabase();
    }
    return id;
  }

  static Future<int> delete(int id) async {
    final db = EntriesDatabase.instance.database!;

    final removedId = await db.delete(
      entryTagsTable,
      where: '${EntryTagsFields.id} = ?',
      whereArgs: [id],
    );

    if (EntriesDatabase.instance.usingExternalDb()) {
      await EntriesDatabase.instance.updateExternalDatabase();
    }
    return removedId;
  }
}
