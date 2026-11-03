import 'package:flutter_test/flutter_test.dart';
import 'package:daily_you/study_tracker_controller.dart';

void main() {
  group('Kiểm thử hệ thống Quản lý học tập tự động (Checklist 2 - TV2)', () {
    late StudyTrackerController controller;

    setUp(() {
      controller = StudyTrackerController();
    });

    test('1. Kiểm thử chu trình: Bắt đầu (Start) -> Tạm dừng (Pause) -> Tiếp tục (Resume) -> Kết thúc (Stop)', () {
      expect(controller.isRunning, isFalse);
      expect(controller.isPaused, isFalse);

      controller.startTimer();
      expect(controller.isRunning, isTrue);
      expect(controller.isPaused, isFalse);

      controller.pauseTimer();
      expect(controller.isRunning, isTrue);
      expect(controller.isPaused, isTrue);

      controller.resumeTimer();
      expect(controller.isRunning, isTrue);
      expect(controller.isPaused, isFalse);

      final session = controller.stopTimer();
      expect(controller.isRunning, isFalse);
      expect(controller.isPaused, isFalse);
      expect(session, isNotNull);
      expect(controller.sessionHistory.length, 1);
    });

    test('2. Kiểm thử logic tính chuỗi ngày học liên tiếp (Current & Longest Streak)', () {
      controller.dailyGoalMinutes = 30;

      // Giả lập phiên học đạt mục tiêu ngày hôm nay
      controller.sessionHistory.add(StudySession(
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(minutes: 40)),
        actualStudyDuration: const Duration(minutes: 40),
      ));

      // Giả lập phiên học đạt mục tiêu ngày hôm qua
      DateTime yesterday = DateTime.now().subtract(const Duration(days: 1));
      controller.sessionHistory.add(StudySession(
        startTime: yesterday,
        endTime: yesterday.add(const Duration(minutes: 35)),
        actualStudyDuration: const Duration(minutes: 35),
      ));

      controller.updateStreakAndGoals();

      expect(controller.currentStreak, 2);
      expect(controller.longestStreak, 2);
    });

    test('3. Kiểm thử tiến độ mức độ phần trăm (%) hoàn thành mục tiêu ngày', () {
      controller.dailyGoalMinutes = 60;

      controller.sessionHistory.add(StudySession(
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(minutes: 30)),
        actualStudyDuration: const Duration(minutes: 30),
      ));

      double percentage = controller.getGoalCompletionPercentage();
      expect(percentage, 50.0);
    });
  });
}