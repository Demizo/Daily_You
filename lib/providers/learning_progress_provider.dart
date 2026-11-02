// Copyright (C) 2026 Daily You TH3 Learning English
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/database/practice_history_dao.dart';
import 'package:daily_you/database/pronunciation_result_dao.dart';
import 'package:daily_you/models/learning_progress.dart';
import 'package:daily_you/models/practice_history.dart';
import 'package:daily_you/services/daily_reminder_service.dart';
import 'package:flutter/foundation.dart';

/// Provider quản lý State và kết nối dữ liệu tiến độ học tập (Checklist 6 - TV3).
///
/// Phối hợp trực tiếp với Model/DAO do TV1 & TV2 cung cấp:
/// - Lắng nghe và tổng hợp dữ liệu học tập thực tế từ SQLite `practice_history`.
/// - Tự động cập nhật thời gian thực (Real-time reactive update) khi người học
///   hoàn thành một bài luyện phát âm AI.
class LearningProgressProvider extends ChangeNotifier {
  static final LearningProgressProvider instance =
      LearningProgressProvider._internal();

  factory LearningProgressProvider() => instance;

  LearningProgressProvider._internal();

  int _currentUserId = 1;
  ProgressViewState _state = ProgressViewState.initial;
  String? _errorMessage;
  DailyLearningProgress _progress = DailyLearningProgress.empty();

  int get currentUserId => _currentUserId;
  ProgressViewState get state => _state;
  String? get errorMessage => _errorMessage;
  DailyLearningProgress get progress => _progress;

  bool get isLoading => _state == ProgressViewState.loading;
  bool get isEmpty => _state == ProgressViewState.empty;
  bool get hasError => _state == ProgressViewState.error;

  /// Đặt User ID hiện tại và tải lại toàn bộ tiến độ.
  void setCurrentUser(int userId) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      loadProgress(userId: userId);
    }
  }

  /// Tải dữ liệu tiến độ từ CSDL SQLite và SharedPreferences.
  Future<void> loadProgress({int? userId}) async {
    final uid = userId ?? _currentUserId;
    _currentUserId = uid;
    _state = ProgressViewState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final todayStr = _formatDate(now);

      // 1. Đọc mục tiêu hằng ngày từ cài đặt
      final dailyGoal = await DailyReminderService().getDailyGoalMinutes();

      // 2. Lấy danh sách lịch sử hôm nay
      final todayPractices =
          await PracticeHistoryDao.getByUserAndDate(uid, todayStr);

      final completedToday = todayPractices
          .where((p) => p.status == PracticeStatus.completed)
          .toList();

      final todaySeconds = completedToday.fold<int>(
        0,
        (sum, p) => sum + (p.durationSeconds ?? 0),
      );

      // 3. Tính điểm phát âm trung bình hôm nay (nếu có)
      double? averageScore;
      final todayScores = <double>[];
      for (final practice in completedToday) {
        if (practice.id != null) {
          final results =
              await PronunciationResultDao.getByPracticeId(practice.id!);
          for (final r in results) {
            if (r.overallScore != null) {
              todayScores.add(r.overallScore!);
            }
          }
        }
      }
      if (todayScores.isNotEmpty) {
        averageScore =
            todayScores.reduce((a, b) => a + b) / todayScores.length;
      }

      // 4. Lấy tất cả lịch sử để tính Streak (chuỗi ngày học liên tục)
      final allPractices = await PracticeHistoryDao.getByUserId(uid);
      final streaks = _calculateStreaks(allPractices, now: now);

      // 5. Tổng hợp dữ liệu biểu đồ 7 ngày gần nhất (Weekly Chart)
      final weeklyData =
          await _computeWeeklyProgress(uid, dailyGoal, now: now);

      // 6. Lấy 5 phiên luyện tập gần nhất
      final recentSessions = allPractices.take(5).toList();

      // Tạo đối tượng tiến độ
      _progress = DailyLearningProgress(
        userId: uid,
        dateString: todayStr,
        todayStudySeconds: todaySeconds,
        streakCount: streaks.current,
        longestStreak: streaks.longest,
        dailyGoalMinutes: dailyGoal,
        completedSessionsCount: completedToday.length,
        averagePronunciationScore: averageScore,
        weeklyProgress: weeklyData,
        recentSessions: recentSessions,
      );

      if (_progress.isNewUser) {
        _state = ProgressViewState.empty;
      } else {
        _state = ProgressViewState.loaded;
      }
    } catch (e, stack) {
      _state = ProgressViewState.error;
      _errorMessage = 'Không thể tải dữ liệu tiến độ: $e';
      debugPrint('[$runtimeType Error]: $e\n$stack');
    }

    notifyListeners();
  }

  /// Làm mới dữ liệu (Pull-to-refresh).
  Future<void> refresh() => loadProgress(userId: _currentUserId);

  /// Cập nhật mục tiêu học tập mới (phút/ngày).
  Future<void> updateDailyGoal(int newGoalMinutes) async {
    await DailyReminderService().setDailyGoalMinutes(newGoalMinutes);
    _progress = _progress.copyWith(dailyGoalMinutes: newGoalMinutes);
    notifyListeners();
  }

  /// Hook tự động gọi sau khi TV4/TV5 hoàn tất một bài luyện phát âm AI.
  ///
  /// Hàm này cập nhật ngay lập tức các chỉ số (streak, số phút học, % hoàn thành)
  /// mà không cần tải lại toàn bộ app.
  Future<void> recordCompletedSession(PracticeHistory session) async {
    // Tải lại dữ liệu đồng bộ
    await loadProgress(userId: _currentUserId);
  }

  /// Thuật toán tính Streak (số ngày liên tiếp có ít nhất 1 bài học COMPLETED).
  ({int current, int longest}) _calculateStreaks(
    List<PracticeHistory> practices, {
    required DateTime now,
  }) {
    final completedDays = <String>{};
    for (final p in practices) {
      if (p.status == PracticeStatus.completed) {
        completedDays.add(p.practiceDate);
      }
    }

    if (completedDays.isEmpty) {
      return (current: 0, longest: 0);
    }

    final todayStr = _formatDate(now);
    final yesterdayStr = _formatDate(now.subtract(const Duration(days: 1)));

    // Xác định điểm bắt đầu của current streak
    int currentStreak = 0;
    DateTime checkDate;

    if (completedDays.contains(todayStr)) {
      checkDate = now;
    } else if (completedDays.contains(yesterdayStr)) {
      checkDate = now.subtract(const Duration(days: 1));
    } else {
      checkDate = now; // Không có streak hiện tại
    }

    if (completedDays.contains(_formatDate(checkDate))) {
      while (completedDays.contains(_formatDate(checkDate))) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    }

    // Tính Longest Streak trên toàn bộ ngày đã học
    final sortedDays = completedDays.toList()..sort();
    int longest = 0;
    int tempStreak = 0;
    DateTime? prevDate;

    for (final dayStr in sortedDays) {
      final date = DateTime.parse(dayStr);
      if (prevDate == null) {
        tempStreak = 1;
      } else {
        final diff = date.difference(prevDate).inDays;
        if (diff == 1) {
          tempStreak++;
        } else if (diff > 1) {
          tempStreak = 1;
        }
      }
      if (tempStreak > longest) longest = tempStreak;
      prevDate = date;
    }

    return (current: currentStreak, longest: longest);
  }

  /// Tính dữ liệu tiến độ 7 ngày (từ 6 ngày trước đến hôm nay).
  Future<WeeklyProgressData> _computeWeeklyProgress(
    int userId,
    int dailyGoalMinutes, {
    required DateTime now,
  }) async {
    final days = <DayProgressItem>[];
    int totalWeekSeconds = 0;
    DayProgressItem? bestDay;

    // Lấy 7 ngày gần nhất
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = _formatDate(date);
      final label = _getDayOfWeekLabel(date.weekday);

      final dayPractices =
          await PracticeHistoryDao.getByUserAndDate(userId, dateStr);

      final completed = dayPractices
          .where((p) => p.status == PracticeStatus.completed)
          .toList();

      final seconds = completed.fold<int>(
        0,
        (sum, p) => sum + (p.durationSeconds ?? 0),
      );

      totalWeekSeconds += seconds;
      final isAchieved = (seconds / 60) >= dailyGoalMinutes;

      final item = DayProgressItem(
        date: date,
        dateString: dateStr,
        dayOfWeekLabel: label,
        studySeconds: seconds,
        completedSessionsCount: completed.length,
        isGoalAchieved: isAchieved,
      );

      days.add(item);

      if (bestDay == null || item.studySeconds > bestDay.studySeconds) {
        bestDay = item;
      }
    }

    final totalMinutes = (totalWeekSeconds / 60).round();
    final avgMinutes = totalMinutes / 7.0;

    return WeeklyProgressData(
      days: days,
      totalWeekMinutes: totalMinutes,
      averageDailyMinutes: avgMinutes,
      bestDay: bestDay,
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }

  String _getDayOfWeekLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'T2';
      case DateTime.tuesday:
        return 'T3';
      case DateTime.wednesday:
        return 'T4';
      case DateTime.thursday:
        return 'T5';
      case DateTime.friday:
        return 'T6';
      case DateTime.saturday:
        return 'T7';
      case DateTime.sunday:
      default:
        return 'CN';
    }
  }
}
