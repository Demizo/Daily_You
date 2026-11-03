// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/models/mood_scale_level.dart';
import 'package:sqflite/sqflite.dart';

class MoodScaleDao {
  static Future<List<MoodScaleLevel>> getAll() async {
    final db = AppDatabase.instance.database!;
    final rows = await db.query(moodScaleTable,
        orderBy: '${MoodScaleLevelFields.mood} ASC');
    return rows.map(MoodScaleLevel.fromJson).toList();
  }

  static Future<void> save(
    List<MoodScaleLevel> levels, {
    DatabaseExecutor? executor,
  }) async {
    final batch = AppDatabase.executorOr(executor).batch();
    for (final level in levels) {
      batch.insert(
        moodScaleTable,
        level.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
}
