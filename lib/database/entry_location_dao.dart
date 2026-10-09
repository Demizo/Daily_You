// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/models/location.dart';
import 'package:sqflite/sqflite.dart';

class EntryLocationDao {
  static Future<List<EntryLocation>> getAll({DatabaseExecutor? executor}) async {
    final db = AppDatabase.executorOr(executor);
    final result = await db.query(entryLocationsTable);
    return result.map((json) => EntryLocation.fromJson(json)).toList();
  }

  static Future<EntryLocation?> getForEntry(int entryId,
      {DatabaseExecutor? executor}) async {
    final db = AppDatabase.executorOr(executor);
    final result = await db.query(
      entryLocationsTable,
      where: '${EntryLocationFields.entryId} = ?',
      whereArgs: [entryId],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return EntryLocation.fromJson(result.first);
  }

  static Future<EntryLocation> setForEntry(EntryLocation location,
      {DatabaseExecutor? executor}) async {
    final db = AppDatabase.executorOr(executor);
    await db.delete(
      entryLocationsTable,
      where: '${EntryLocationFields.entryId} = ?',
      whereArgs: [location.entryId],
    );
    final id = await db.insert(entryLocationsTable, location.toJson());
    return location.copy(id: id);
  }

  static Future<void> removeForEntry(int entryId,
      {DatabaseExecutor? executor}) async {
    final db = AppDatabase.executorOr(executor);
    await db.delete(
      entryLocationsTable,
      where: '${EntryLocationFields.entryId} = ?',
      whereArgs: [entryId],
    );
  }
}
