// Copyright (C) 2026 Daily You TH3 Learning English
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/models/pronunciation_result.dart';
import 'package:sqflite/sqflite.dart';

class PronunciationResultDao {
  static Future<List<PronunciationResult>> getAll(
      {DatabaseExecutor? executor}) async {
    final result = await AppDatabase.executorOr(executor).query(
      pronunciationResultsTable,
      orderBy: '${PronunciationResultFields.evaluatedAt} DESC',
    );
    return result.map((json) => PronunciationResult.fromJson(json)).toList();
  }

  static Future<PronunciationResult?> get(int id,
      {DatabaseExecutor? executor}) async {
    final maps = await AppDatabase.executorOr(executor).query(
      pronunciationResultsTable,
      columns: PronunciationResultFields.values,
      where: '${PronunciationResultFields.id} = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return PronunciationResult.fromJson(maps.first);
    }
    return null;
  }

  /// Lấy toàn bộ kết quả phân tích gắn với một phiên luyện tập [practiceId].
  static Future<List<PronunciationResult>> getByPracticeId(
    int practiceId, {
    DatabaseExecutor? executor,
  }) async {
    final result = await AppDatabase.executorOr(executor).query(
      pronunciationResultsTable,
      where: '${PronunciationResultFields.practiceId} = ?',
      whereArgs: [practiceId],
      orderBy: '${PronunciationResultFields.evaluatedAt} ASC',
    );
    return result.map((json) => PronunciationResult.fromJson(json)).toList();
  }

  /// Lấy danh sách kết quả phân tích theo [userId], phân tách độc lập theo người dùng.
  static Future<List<PronunciationResult>> getByUserId(
    int userId, {
    int? limit,
    int? offset,
    DatabaseExecutor? executor,
  }) async {
    final result = await AppDatabase.executorOr(executor).query(
      pronunciationResultsTable,
      where: '${PronunciationResultFields.userId} = ?',
      whereArgs: [userId],
      orderBy: '${PronunciationResultFields.evaluatedAt} DESC',
      limit: limit,
      offset: offset,
    );
    return result.map((json) => PronunciationResult.fromJson(json)).toList();
  }

  static Future<PronunciationResult> add(
    PronunciationResult result, {
    DatabaseExecutor? executor,
  }) async {
    final id = await AppDatabase.executorOr(executor).insert(
      pronunciationResultsTable,
      result.toJson(),
    );
    return result.copy(id: id);
  }

  static Future<void> update(
    PronunciationResult result, {
    DatabaseExecutor? executor,
  }) async {
    await AppDatabase.executorOr(executor).update(
      pronunciationResultsTable,
      result.toJson(),
      where: '${PronunciationResultFields.id} = ?',
      whereArgs: [result.id],
    );
  }

  static Future<void> remove(
    int id, {
    DatabaseExecutor? executor,
  }) async {
    await AppDatabase.executorOr(executor).delete(
      pronunciationResultsTable,
      where: '${PronunciationResultFields.id} = ?',
      whereArgs: [id],
    );
  }

  static Future<void> removeAllForPractice(
    int practiceId, {
    DatabaseExecutor? executor,
  }) async {
    await AppDatabase.executorOr(executor).delete(
      pronunciationResultsTable,
      where: '${PronunciationResultFields.practiceId} = ?',
      whereArgs: [practiceId],
    );
  }

  static Future<void> removeAllForUser(
    int userId, {
    DatabaseExecutor? executor,
  }) async {
    await AppDatabase.executorOr(executor).delete(
      pronunciationResultsTable,
      where: '${PronunciationResultFields.userId} = ?',
      whereArgs: [userId],
    );
  }
}

