// Copyright (C) 2026 Daily You TH3 Learning English
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/models/practice_history.dart';
import 'package:sqflite/sqflite.dart';

class PracticeHistoryDao {
  static Future<List<PracticeHistory>> getAll(
      {DatabaseExecutor? executor}) async {
    final result = await AppDatabase.executorOr(executor).query(
      practiceHistoryTable,
      orderBy: '${PracticeHistoryFields.startedAt} DESC',
    );
    return result.map((json) => PracticeHistory.fromJson(json)).toList();
  }

  static Future<PracticeHistory?> get(int id,
      {DatabaseExecutor? executor}) async {
    final maps = await AppDatabase.executorOr(executor).query(
      practiceHistoryTable,
      columns: PracticeHistoryFields.values,
      where: '${PracticeHistoryFields.id} = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return PracticeHistory.fromJson(maps.first);
    }
    return null;
  }

  /// Lấy danh sách lịch sử theo [userId], phân tách độc lập theo người dùng.
  static Future<List<PracticeHistory>> getByUserId(
    int userId, {
    int? limit,
    int? offset,
    DatabaseExecutor? executor,
  }) async {
    final result = await AppDatabase.executorOr(executor).query(
      practiceHistoryTable,
      where: '${PracticeHistoryFields.userId} = ?',
      whereArgs: [userId],
      orderBy: '${PracticeHistoryFields.startedAt} DESC',
      limit: limit,
      offset: offset,
    );
    return result.map((json) => PracticeHistory.fromJson(json)).toList();
  }

  /// Truy vấn lịch sử theo [userId] và ngày luyện tập [practiceDate] (định dạng YYYY-MM-DD).
  static Future<List<PracticeHistory>> getByUserAndDate(
    int userId,
    String practiceDate, {
    DatabaseExecutor? executor,
  }) async {
    final result = await AppDatabase.executorOr(executor).query(
      practiceHistoryTable,
      where:
          '${PracticeHistoryFields.userId} = ? AND ${PracticeHistoryFields.practiceDate} = ?',
      whereArgs: [userId, practiceDate],
      orderBy: '${PracticeHistoryFields.startedAt} DESC',
    );
    return result.map((json) => PracticeHistory.fromJson(json)).toList();
  }

  /// Truy vấn lịch sử trong khoảng thời gian [startDate] -> [endDate] (YYYY-MM-DD).
  static Future<List<PracticeHistory>> getByUserAndDateRange(
    int userId,
    String startDate,
    String endDate, {
    DatabaseExecutor? executor,
  }) async {
    final result = await AppDatabase.executorOr(executor).query(
      practiceHistoryTable,
      where:
          '${PracticeHistoryFields.userId} = ? AND ${PracticeHistoryFields.practiceDate} BETWEEN ? AND ?',
      whereArgs: [userId, startDate, endDate],
      orderBy: '${PracticeHistoryFields.startedAt} DESC',
    );
    return result.map((json) => PracticeHistory.fromJson(json)).toList();
  }

  /// Truy vấn theo trạng thái (IN_PROGRESS, COMPLETED, CANCELLED).
  static Future<List<PracticeHistory>> getByUserAndStatus(
    int userId,
    PracticeStatus status, {
    DatabaseExecutor? executor,
  }) async {
    final result = await AppDatabase.executorOr(executor).query(
      practiceHistoryTable,
      where:
          '${PracticeHistoryFields.userId} = ? AND ${PracticeHistoryFields.status} = ?',
      whereArgs: [userId, status.toValue()],
      orderBy: '${PracticeHistoryFields.startedAt} DESC',
    );
    return result.map((json) => PracticeHistory.fromJson(json)).toList();
  }

  static Future<PracticeHistory> add(
    PracticeHistory history, {
    DatabaseExecutor? executor,
  }) async {
    final id = await AppDatabase.executorOr(executor).insert(
      practiceHistoryTable,
      history.toJson(),
    );
    return history.copy(id: id);
  }

  static Future<void> update(
    PracticeHistory history, {
    DatabaseExecutor? executor,
  }) async {
    await AppDatabase.executorOr(executor).update(
      practiceHistoryTable,
      history.toJson(),
      where: '${PracticeHistoryFields.id} = ?',
      whereArgs: [history.id],
    );
  }

  static Future<void> remove(
    int id, {
    DatabaseExecutor? executor,
  }) async {
    await AppDatabase.executorOr(executor).delete(
      practiceHistoryTable,
      where: '${PracticeHistoryFields.id} = ?',
      whereArgs: [id],
    );
  }

  static Future<void> removeAllForUser(
    int userId, {
    DatabaseExecutor? executor,
  }) async {
    await AppDatabase.executorOr(executor).delete(
      practiceHistoryTable,
      where: '${PracticeHistoryFields.userId} = ?',
      whereArgs: [userId],
    );
  }
}

