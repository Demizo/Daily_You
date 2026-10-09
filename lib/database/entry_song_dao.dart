// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/models/song.dart';
import 'package:sqflite/sqflite.dart';

class EntrySongDao {
  static Future<List<EntrySong>> getByEntryId(int entryId,
      {DatabaseExecutor? executor}) async {
    final db = AppDatabase.executorOr(executor);
    final result = await db.query(
      entrySongsTable,
      where: '${EntrySongFields.entryId} = ?',
      whereArgs: [entryId],
      orderBy: '${EntrySongFields.id} ASC',
    );
    return result.map((json) => EntrySong.fromJson(json)).toList();
  }

  static Future<List<EntrySong>> getAll({DatabaseExecutor? executor}) async {
    final db = AppDatabase.executorOr(executor);
    final result = await db.query(
      entrySongsTable,
      orderBy: '${EntrySongFields.id} ASC',
    );
    return result.map((json) => EntrySong.fromJson(json)).toList();
  }

  static Future<EntrySong> add(EntrySong song,
      {DatabaseExecutor? executor}) async {
    final db = AppDatabase.executorOr(executor);
    final id = await db.insert(entrySongsTable, song.toJson());
    return song.copy(id: id);
  }

  static Future<void> update(EntrySong song,
      {DatabaseExecutor? executor}) async {
    final db = AppDatabase.executorOr(executor);
    await db.update(
      entrySongsTable,
      song.toJson(),
      where: '${EntrySongFields.id} = ?',
      whereArgs: [song.id],
    );
  }

  static Future<void> remove(int id, {DatabaseExecutor? executor}) async {
    final db = AppDatabase.executorOr(executor);
    await db.delete(
      entrySongsTable,
      where: '${EntrySongFields.id} = ?',
      whereArgs: [id],
    );
  }

  static Future<void> removeAllForEntry(int entryId,
      {DatabaseExecutor? executor}) async {
    final db = AppDatabase.executorOr(executor);
    await db.delete(
      entrySongsTable,
      where: '${EntrySongFields.entryId} = ?',
      whereArgs: [entryId],
    );
  }

  static Future<bool> hasSongSlotForTemplate(int templateId,
      {DatabaseExecutor? executor}) async {
    final db = AppDatabase.executorOr(executor);
    final count = Sqflite.firstIntValue(await db.query(
      templateSongSlotsTable,
      columns: ['COUNT(*)'],
      where: '${TemplateSongSlotFields.templateId} = ?',
      whereArgs: [templateId],
    ));
    return (count ?? 0) > 0;
  }

  static Future<void> setSongSlotForTemplate(int templateId, bool hasSlot,
      {DatabaseExecutor? executor}) async {
    final db = AppDatabase.executorOr(executor);
    await db.delete(
      templateSongSlotsTable,
      where: '${TemplateSongSlotFields.templateId} = ?',
      whereArgs: [templateId],
    );
    if (hasSlot) {
      await db.insert(
        templateSongSlotsTable,
        TemplateSongSlot(
          templateId: templateId,
          timeCreate: DateTime.now(),
        ).toJson(),
      );
    }
  }
}
