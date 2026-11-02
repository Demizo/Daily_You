// Copyright (C) 2026 Daily You TH3 Learning English
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/practice_history.dart';

/// Trạng thái của màn hình tiến độ học tập.
enum ProgressViewState {
  initial,
  loading,
  loaded,
  empty,
  error,
}

/// Thống kê tiến độ của một ngày cụ thể (dành cho biểu đồ tuần / lịch sử).
class DayProgressItem {
  final DateTime date;
  final String dateString; // YYYY-MM-DD
  final String dayOfWeekLabel; // T2, T3, T4, T5, T6, T7, CN
  final int studySeconds;
  final int completedSessionsCount;
  final bool isGoalAchieved;

  const DayProgressItem({
    required this.date,
    required this.dateString,
    required this.dayOfWeekLabel,
    required this.studySeconds,
    required this.completedSessionsCount,
    required this.isGoalAchieved,
  });

  int get studyMinutes => (studySeconds / 60).round();

  DayProgressItem copyWith({
    DateTime? date,
    String? dateString,
    String? dayOfWeekLabel,
    int? studySeconds,
    int? completedSessionsCount,
    bool? isGoalAchieved,
  }) {
    return DayProgressItem(
      date: date ?? this.date,
      dateString: dateString ?? this.dateString,
      dayOfWeekLabel: dayOfWeekLabel ?? this.dayOfWeekLabel,
      studySeconds: studySeconds ?? this.studySeconds,
      completedSessionsCount:
          completedSessionsCount ?? this.completedSessionsCount,
      isGoalAchieved: isGoalAchieved ?? this.isGoalAchieved,
    );
  }
}

/// Dữ liệu tổng hợp tiến độ 7 ngày gần nhất (Weekly Chart).
class WeeklyProgressData {
  final List<DayProgressItem> days;
  final int totalWeekMinutes;
  final double averageDailyMinutes;
  final DayProgressItem? bestDay;

  const WeeklyProgressData({
    required this.days,
    required this.totalWeekMinutes,
    required this.averageDailyMinutes,
    this.bestDay,
  });

  factory WeeklyProgressData.empty() {
    return const WeeklyProgressData(
      days: [],
      totalWeekMinutes: 0,
      averageDailyMinutes: 0.0,
      bestDay: null,
    );
  }
}

/// Model tổng hợp toàn diện về tiến độ học tiếng Anh trong ngày.
///
/// Dữ liệu này được kết nối từ Checklist 2 (TV2) và hiển thị qua
/// Dashboard Tiến độ Checklist 6 (TV3).
class DailyLearningProgress {
  final int userId;
  final String dateString; // YYYY-MM-DD
  final int todayStudySeconds;
  final int streakCount;
  final int longestStreak;
  final int dailyGoalMinutes;
  final int completedSessionsCount;
  final double? averagePronunciationScore;
  final WeeklyProgressData weeklyProgress;
  final List<PracticeHistory> recentSessions;

  const DailyLearningProgress({
    required this.userId,
    required this.dateString,
    required this.todayStudySeconds,
    required this.streakCount,
    required this.longestStreak,
    required this.dailyGoalMinutes,
    required this.completedSessionsCount,
    this.averagePronunciationScore,
    required this.weeklyProgress,
    this.recentSessions = const [],
  });

  /// Tổng thời gian học trong ngày quy đổi ra phút.
  int get todayStudyMinutes => (todayStudySeconds / 60).round();

  /// Tỷ lệ phần trăm hoàn thành mục tiêu hằng ngày (0% -> 100%+).
  double get progressPercentage {
    if (dailyGoalMinutes <= 0) return 0.0;
    final pct = (todayStudySeconds / (dailyGoalMinutes * 60)) * 100.0;
    return pct.clamp(0.0, 100.0);
  }

  /// Kiểm tra đã hoàn thành mục tiêu ngày hôm nay chưa.
  bool get isGoalAchieved => todayStudyMinutes >= dailyGoalMinutes;

  /// Số phút còn lại cần học để chạm mục tiêu ngày.
  int get remainingMinutesToGoal {
    final diff = dailyGoalMinutes - todayStudyMinutes;
    return diff > 0 ? diff : 0;
  }

  /// Trạng thái người dùng mới / chưa có dữ liệu học tập.
  bool get isNewUser =>
      todayStudySeconds == 0 &&
      streakCount == 0 &&
      completedSessionsCount == 0 &&
      recentSessions.isEmpty;

  factory DailyLearningProgress.empty({
    int userId = 1,
    int dailyGoalMinutes = 20,
    String? dateString,
  }) {
    final today = dateString ??
        DateTime.now().toIso8601String().substring(0, 10);
    return DailyLearningProgress(
      userId: userId,
      dateString: today,
      todayStudySeconds: 0,
      streakCount: 0,
      longestStreak: 0,
      dailyGoalMinutes: dailyGoalMinutes,
      completedSessionsCount: 0,
      averagePronunciationScore: null,
      weeklyProgress: WeeklyProgressData.empty(),
      recentSessions: const [],
    );
  }

  DailyLearningProgress copyWith({
    int? userId,
    String? dateString,
    int? todayStudySeconds,
    int? streakCount,
    int? longestStreak,
    int? dailyGoalMinutes,
    int? completedSessionsCount,
    double? averagePronunciationScore,
    WeeklyProgressData? weeklyProgress,
    List<PracticeHistory>? recentSessions,
  }) {
    return DailyLearningProgress(
      userId: userId ?? this.userId,
      dateString: dateString ?? this.dateString,
      todayStudySeconds: todayStudySeconds ?? this.todayStudySeconds,
      streakCount: streakCount ?? this.streakCount,
      longestStreak: longestStreak ?? this.longestStreak,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      completedSessionsCount:
          completedSessionsCount ?? this.completedSessionsCount,
      averagePronunciationScore:
          averagePronunciationScore ?? this.averagePronunciationScore,
      weeklyProgress: weeklyProgress ?? this.weeklyProgress,
      recentSessions: recentSessions ?? this.recentSessions,
    );
  }
}
