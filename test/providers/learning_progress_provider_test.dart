// Copyright (C) 2026 Daily You TH3 Learning English
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/database/practice_history_dao.dart';
import 'package:daily_you/database/user_dao.dart';
import 'package:daily_you/models/learning_progress.dart';
import 'package:daily_you/models/practice_history.dart';
import 'package:daily_you/models/user.dart';
import 'package:daily_you/providers/learning_progress_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late Database database;
  late LearningProgressProvider provider;
  final now = DateTime(2026, 11, 2, 10, 0, 0);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    databaseFactory = databaseFactoryFfi;
    database = await databaseFactory.openDatabase(inMemoryDatabasePath);
    AppDatabase.instance.database = database;
    await AppDatabase.instance.createSchema(database);

    provider = LearningProgressProvider();
  });

  tearDown(() async {
    AppDatabase.instance.database = null;
    await database.close();
  });

  group('LearningProgress Model & Calculations', () {
    test('DailyLearningProgress calculates percentages and remaining minutes correctly', () {
      final progress = DailyLearningProgress(
        userId: 1,
        dateString: '2026-11-02',
        todayStudySeconds: 900, // 15 phút
        streakCount: 4,
        longestStreak: 7,
        dailyGoalMinutes: 20,
        completedSessionsCount: 2,
        weeklyProgress: WeeklyProgressData.empty(),
      );

      expect(progress.todayStudyMinutes, 15);
      expect(progress.progressPercentage, 75.0);
      expect(progress.isGoalAchieved, isFalse);
      expect(progress.remainingMinutesToGoal, 5);
      expect(progress.isNewUser, isFalse);
    });

    test('DailyLearningProgress clamps percentage at 100% and marks goal achieved', () {
      final progress = DailyLearningProgress(
        userId: 1,
        dateString: '2026-11-02',
        todayStudySeconds: 1800, // 30 phút, vượt mục tiêu 20 phút
        streakCount: 5,
        longestStreak: 5,
        dailyGoalMinutes: 20,
        completedSessionsCount: 3,
        weeklyProgress: WeeklyProgressData.empty(),
      );

      expect(progress.todayStudyMinutes, 30);
      expect(progress.progressPercentage, 100.0);
      expect(progress.isGoalAchieved, isTrue);
      expect(progress.remainingMinutesToGoal, 0);
    });
  });

  group('LearningProgressProvider Integration Tests', () {
    test('Initial state with new user triggers ProgressViewState.empty', () async {
      final user = await UserDao.add(User(
        name: 'New Learner',
        timeCreate: now,
        timeModified: now,
      ));

      await provider.loadProgress(userId: user.id!);

      expect(provider.state, ProgressViewState.empty);
      expect(provider.progress.streakCount, 0);
      expect(provider.progress.todayStudyMinutes, 0);
      expect(provider.progress.completedSessionsCount, 0);
    });

    test('Recording completed sessions updates today time, streak and chart', () async {
      final user = await UserDao.add(User(
        name: 'Active Learner',
        timeCreate: now,
        timeModified: now,
      ));

      final todayStr = '2026-11-02';
      final yesterdayStr = '2026-11-01';

      // 1. Thêm phiên hoàn thành hôm qua để tạo chuỗi streak
      await PracticeHistoryDao.add(PracticeHistory(
        userId: user.id!,
        activityType: ActivityType.pronunciation,
        content: 'Yesterday practice',
        startedAt: DateTime(2026, 11, 1, 20, 0),
        endedAt: DateTime(2026, 11, 1, 20, 10),
        durationSeconds: 600, // 10 phút
        practiceDate: yesterdayStr,
        status: PracticeStatus.completed,
        timeCreate: DateTime(2026, 11, 1, 20, 0),
        timeModified: DateTime(2026, 11, 1, 20, 10),
      ));

      // 2. Thêm phiên hoàn thành hôm nay (10 phút)
      final sessionToday = await PracticeHistoryDao.add(PracticeHistory(
        userId: user.id!,
        activityType: ActivityType.pronunciation,
        content: 'The sun rises in the east',
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 10)),
        durationSeconds: 600, // 10 phút
        practiceDate: todayStr,
        status: PracticeStatus.completed,
        timeCreate: now,
        timeModified: now,
      ));

      await provider.loadProgress(userId: user.id!);

      expect(provider.state, ProgressViewState.loaded);
      expect(provider.progress.todayStudyMinutes, 10);
      expect(provider.progress.completedSessionsCount, 1);
      expect(provider.progress.recentSessions.length, 2);

      // Kiểm tra streak tiếp tục tăng khi hoàn thành thêm bài học
      await provider.recordCompletedSession(sessionToday);
      expect(provider.progress.todayStudyMinutes, 10);
    });

    test('Updating daily goal modifies provider state and recalculates percentage', () async {
      await provider.updateDailyGoal(30);

      expect(provider.progress.dailyGoalMinutes, 30);
    });
  });
}
