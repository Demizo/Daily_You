// Copyright (C) 2026 Daily You TH3 Learning English
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/models/user.dart';
import 'package:sqflite/sqflite.dart';

class UserDao {
  static Future<List<User>> getAll({DatabaseExecutor? executor}) async {
    final result = await AppDatabase.executorOr(executor).query(
      usersTable,
      orderBy: '${UserFields.timeCreate} DESC',
    );
    return result.map((json) => User.fromJson(json)).toList();
  }

  static Future<User?> get(int id, {DatabaseExecutor? executor}) async {
    final maps = await AppDatabase.executorOr(executor).query(
      usersTable,
      columns: UserFields.values,
      where: '${UserFields.id} = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return User.fromJson(maps.first);
    }
    return null;
  }

  static Future<User?> getByAuthId(String authId,
      {DatabaseExecutor? executor}) async {
    final maps = await AppDatabase.executorOr(executor).query(
      usersTable,
      columns: UserFields.values,
      where: '${UserFields.authId} = ?',
      whereArgs: [authId],
    );
    if (maps.isNotEmpty) {
      return User.fromJson(maps.first);
    }
    return null;
  }

  static Future<User?> getByEmail(String email,
      {DatabaseExecutor? executor}) async {
    final maps = await AppDatabase.executorOr(executor).query(
      usersTable,
      columns: UserFields.values,
      where: '${UserFields.email} = ?',
      whereArgs: [email],
    );
    if (maps.isNotEmpty) {
      return User.fromJson(maps.first);
    }
    return null;
  }

  static Future<User> add(User user, {DatabaseExecutor? executor}) async {
    final id = await AppDatabase.executorOr(executor).insert(
      usersTable,
      user.toJson(),
    );
    return user.copy(id: id);
  }

  static Future<void> update(User user, {DatabaseExecutor? executor}) async {
    await AppDatabase.executorOr(executor).update(
      usersTable,
      user.toJson(),
      where: '${UserFields.id} = ?',
      whereArgs: [user.id],
    );
  }

  static Future<void> remove(int id, {DatabaseExecutor? executor}) async {
    await AppDatabase.executorOr(executor).delete(
      usersTable,
      where: '${UserFields.id} = ?',
      whereArgs: [id],
    );
  }
}

