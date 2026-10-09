// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/models/space.dart';
import 'package:sqflite/sqflite.dart';

class SpacesDao {
  static Future<List<Space>> getAll({DatabaseExecutor? executor}) async {
    final db = AppDatabase.executorOr(executor);
    final result = await db.query(spacesTable, orderBy: '${SpaceFields.name} ASC');
    return result.map((json) => Space.fromJson(json)).toList();
  }

  static Future<Space?> getById(int id, {DatabaseExecutor? executor}) async {
    final db = AppDatabase.executorOr(executor);
    final result = await db.query(
      spacesTable,
      where: '${SpaceFields.id} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Space.fromJson(result.first);
  }

  static Future<Space?> getDefault({DatabaseExecutor? executor}) async {
    final db = AppDatabase.executorOr(executor);
    final result = await db.query(
      spacesTable,
      where: '${SpaceFields.isDefault} = 1',
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Space.fromJson(result.first);
  }

  static Future<Space> add(Space space, {DatabaseExecutor? executor}) async {
    final db = AppDatabase.executorOr(executor);
    final id = await db.insert(spacesTable, space.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return space.copy(id: id);
  }

  static Future<int> update(Space space, {DatabaseExecutor? executor}) async {
    final db = AppDatabase.executorOr(executor);
    return await db.update(
      spacesTable,
      space.toJson(),
      where: '${SpaceFields.id} = ?',
      whereArgs: [space.id],
    );
  }

  static Future<int> remove(int id, {DatabaseExecutor? executor}) async {
    final db = AppDatabase.executorOr(executor);
    await db.delete(
      entrySpacesTable,
      where: '${EntrySpaceFields.spaceId} = ?',
      whereArgs: [id],
    );
    return await db.delete(
      spacesTable,
      where: '${SpaceFields.id} = ?',
      whereArgs: [id],
    );
  }

  static Future<List<EntrySpace>> getAllEntrySpaces(
      {DatabaseExecutor? executor}) async {
    final db = AppDatabase.executorOr(executor);
    final result = await db.query(entrySpacesTable);
    return result.map((json) => EntrySpace.fromJson(json)).toList();
  }

  static Future<EntrySpace?> getEntrySpaceForEntry(int entryId,
      {DatabaseExecutor? executor}) async {
    final db = AppDatabase.executorOr(executor);
    final result = await db.query(
      entrySpacesTable,
      where: '${EntrySpaceFields.entryId} = ?',
      whereArgs: [entryId],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return EntrySpace.fromJson(result.first);
  }

  static Future<void> setSpaceForEntry(int entryId, int spaceId,
      {DatabaseExecutor? executor}) async {
    final db = AppDatabase.executorOr(executor);
    await db.delete(
      entrySpacesTable,
      where: '${EntrySpaceFields.entryId} = ?',
      whereArgs: [entryId],
    );
    await db.insert(
      entrySpacesTable,
      {
        EntrySpaceFields.entryId: entryId,
        EntrySpaceFields.spaceId: spaceId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> removeForEntry(int entryId,
      {DatabaseExecutor? executor}) async {
    final db = AppDatabase.executorOr(executor);
    await db.delete(
      entrySpacesTable,
      where: '${EntrySpaceFields.entryId} = ?',
      whereArgs: [entryId],
    );
  }
}
