// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/models/person.dart';
import 'package:sqflite/sqflite.dart';

class PeopleDao {
  static Future<List<Person>> getAll({DatabaseExecutor? executor}) async {
    final db = AppDatabase.executorOr(executor);
    final result = await db.query(peopleTable, orderBy: '${PersonFields.name} ASC');
    return result.map((json) => Person.fromJson(json)).toList();
  }

  static Future<Person?> getById(int id, {DatabaseExecutor? executor}) async {
    final db = AppDatabase.executorOr(executor);
    final result = await db.query(
      peopleTable,
      where: '${PersonFields.id} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Person.fromJson(result.first);
  }

  static Future<Person> add(Person person, {DatabaseExecutor? executor}) async {
    final db = AppDatabase.executorOr(executor);
    final id = await db.insert(peopleTable, person.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return person.copy(id: id);
  }

  static Future<int> update(Person person, {DatabaseExecutor? executor}) async {
    final db = AppDatabase.executorOr(executor);
    return await db.update(
      peopleTable,
      person.toJson(),
      where: '${PersonFields.id} = ?',
      whereArgs: [person.id],
    );
  }

  static Future<int> remove(int id, {DatabaseExecutor? executor}) async {
    final db = AppDatabase.executorOr(executor);
    await db.delete(
      entryPeopleTable,
      where: '${EntryPersonFields.personId} = ?',
      whereArgs: [id],
    );
    return await db.delete(
      peopleTable,
      where: '${PersonFields.id} = ?',
      whereArgs: [id],
    );
  }

  static Future<List<EntryPerson>> getAllEntryPeople(
      {DatabaseExecutor? executor}) async {
    final db = AppDatabase.executorOr(executor);
    final result = await db.query(entryPeopleTable);
    return result.map((json) => EntryPerson.fromJson(json)).toList();
  }

  static Future<List<int>> getPeopleForEntry(int entryId,
      {DatabaseExecutor? executor}) async {
    final db = AppDatabase.executorOr(executor);
    final result = await db.query(
      entryPeopleTable,
      where: '${EntryPersonFields.entryId} = ?',
      whereArgs: [entryId],
    );
    return result
        .map((json) => json[EntryPersonFields.personId] as int)
        .toList();
  }

  static Future<void> setPeopleForEntry(int entryId, List<int> personIds,
      {DatabaseExecutor? executor}) async {
    final db = AppDatabase.executorOr(executor);
    await db.delete(
      entryPeopleTable,
      where: '${EntryPersonFields.entryId} = ?',
      whereArgs: [entryId],
    );
    for (final personId in personIds.toSet()) {
      await db.insert(
        entryPeopleTable,
        {
          EntryPersonFields.entryId: entryId,
          EntryPersonFields.personId: personId,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  static Future<void> removeForEntry(int entryId,
      {DatabaseExecutor? executor}) async {
    final db = AppDatabase.executorOr(executor);
    await db.delete(
      entryPeopleTable,
      where: '${EntryPersonFields.entryId} = ?',
      whereArgs: [entryId],
    );
  }
}
