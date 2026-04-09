import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/models/entry.dart';
import 'package:sqflite/sqflite.dart';

class EntryDao {
  static Future<List<Entry>> getAll() async {
    return getAllFromDB(AppDatabase.instance.database!);
  }

  static Future<List<Entry>> getAllFromDB(Database database) async {
    final result = await database
        .query(entriesTable, orderBy: '${EntryFields.timeCreate} DESC');

    return result.map((json) => Entry.fromJson(json)).toList();
  }

  static Future<Entry?> get(int id) async {
    final maps = await AppDatabase.instance.database!.query(
      entriesTable,
      columns: EntryFields.values,
      where: '${EntryFields.id} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Entry.fromJson(maps.first);
    } else {
      return null;
    }
  }

  static Future<Entry?> getFromDB(int id, Database database) async {
    final maps = await database.query(
      entriesTable,
      columns: EntryFields.values,
      where: '${EntryFields.id} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Entry.fromJson(maps.first);
    } else {
      return null;
    }
  }
  static Future<Entry> add(Entry entry) async {
    return addToDB(entry, AppDatabase.instance.database!);
  }

  static Future<Entry> addToDB(Entry entry, Database database) async {
    final id = await database
        .insert(entriesTable, entry.toJson());

    return entry.copy(id: id);
  }

  static Future<void> update(Entry entry) async {
    updateOnDB(entry, AppDatabase.instance.database!);
  }
  
  static Future<void> updateOnDB(Entry entry, Database database) async {
    await database.update(
      entriesTable,
      entry.toJson(),
      where: '${EntryFields.id} = ?',
      whereArgs: [entry.id],
    );
  }

  static Future<void> remove(int id) async {
    await AppDatabase.instance.database!.delete(
      entriesTable,
      where: '${EntryFields.id} = ?',
      whereArgs: [id],
    );
  }
}
