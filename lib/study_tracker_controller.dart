import 'dart:async';

// 1. Model lưu trữ thông tin của một phiên học (Yêu cầu mục B)
class StudySession {
  final DateTime startTime;
  final DateTime endTime;
  final Duration actualStudyDuration; // Thời gian học thực tế (không tính thời gian tạm dừng)

  StudySession({
    required this.startTime,
    required this.endTime,
    required this.actualStudyDuration,
  });
}

// 2. Bộ điều khiển quản lý Timer, Streak và Mục tiêu ngày (Yêu cầu mục A, C, D)
class StudyTrackerController {
  // Biến quản lý Focus Timer
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _isRunning = false;
  bool _isPaused = false;
  
  DateTime? _sessionStartTime;
  Duration _pausedDuration = Duration.zero;
  DateTime? _pauseStartTime;

  // Kho dữ liệu lưu lịch sử và Streak
  List<StudySession> sessionHistory = [];
  int dailyGoalMinutes = 30; // Mục tiêu mặc định: 30 phút/ngày
  int currentStreak = 0;
  int longestStreak = 0;
  List<String> completedDates = []; // Lưu các ngày đã hoàn thành mục tiêu (định dạng YYYY-MM-DD)

  int get secondsElapsed => _secondsElapsed;
  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;

  // --- MỤC A: CHỨC NĂNG FOCUS TIMER ---
  
  // Bắt đầu phiên học (Start)
  void startTimer() {
    if (_isRunning) return;
    _isRunning = true;
    _isPaused = false;
    _secondsElapsed = 0;
    _pausedDuration = Duration.zero;
    _sessionStartTime = DateTime.now();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        _secondsElapsed++;
      }
    });
  }

  // Tạm dừng phiên học (Pause)
  void pauseTimer() {
    if (!_isRunning || _isPaused) return;
    _isPaused = true;
    _pauseStartTime = DateTime.now();
  }

  // Tiếp tục phiên học (Resume)
  void resumeTimer() {
    if (!_isRunning || !_isPaused) return;
    _isPaused = false;
    if (_pauseStartTime != null) {
      _pausedDuration += DateTime.now().difference(_pauseStartTime!);
    }
  }

  // Kết thúc phiên học và lưu dữ liệu (Stop)
  StudySession? stopTimer() {
    if (!_isRunning) return null;
    _timer?.cancel();
    
    DateTime endTime = DateTime.now();
    Duration totalDuration = endTime.difference(_sessionStartTime!);
    // Thời gian học thực tế = Tổng thời gian phiên - Thời gian tạm dừng
    Duration actualDuration = totalDuration - _pausedDuration;

    // Nếu phiên học bị kết thúc khi đang tạm dừng, tính nốt khoảng thời gian dừng cuối
    if (_isPaused && _pauseStartTime != null) {
      actualDuration -= endTime.difference(_pauseStartTime!);
    }

    if (actualDuration.isNegative) actualDuration = Duration.zero;

    StudySession newSession = StudySession(
      startTime: _sessionStartTime!,
      endTime: endTime,
      actualStudyDuration: actualDuration,
    );

    // --- MỤC B: LƯU LỊCH SỬ HỌC TẬP ---
    sessionHistory.add(newSession);
    
    // Cập nhật lại trạng thái hệ thống dữ liệu Streak và Mục tiêu
    updateStreakAndGoals();

    // Reset trạng thái Timer về ban đầu
    _isRunning = false;
    _isPaused = false;
    _secondsElapsed = 0;

    return newSession;
  }

  // --- MỤC C & D: TÍNH TOÁN STREAK & MỤC TIÊU HẰNG NGÀY ---

  // Tính tổng số phút đã học trong ngày hôm nay
  int getTotalStudyMinutesToday() {
    DateTime now = DateTime.now();
    int totalSeconds = 0;
    for (var session in sessionHistory) {
      if (session.startTime.year == now.year &&
          session.startTime.month == now.month &&
          session.startTime.day == now.day) {
        totalSeconds += session.actualStudyDuration.inSeconds;
      }
    }
    return totalSeconds ~/ 60;
  }

  // Tính mức độ hoàn thành mục tiêu hằng ngày (%)
  double getGoalCompletionPercentage() {
    if (dailyGoalMinutes == 0) return 100.0;
    int minutesToday = getTotalStudyMinutesToday();
    double percentage = (minutesToday / dailyGoalMinutes) * 100;
    return percentage > 100 ? 100.0 : percentage;
  }

  // Cập nhật chuỗi ngày học liên tiếp (Streak) - ĐÃ TỐI ƯU SẠCH LỖI
  void updateStreakAndGoals() {
    completedDates.clear();
    Map<String, int> minutesPerDay = {};

    // Gom tổng số phút học theo từng ngày dựa trên lịch sử
    for (var session in sessionHistory) {
      DateTime date = session.startTime;
      String mStr = date.month < 10 ? '0${date.month}' : '${date.month}';
      String dStr = date.day < 10 ? '0${date.day}' : '${date.day}';
      String dateStr = "${date.year}-$mStr-$dStr";

      minutesPerDay[dateStr] = (minutesPerDay[dateStr] ?? 0) + (session.actualStudyDuration.inSeconds ~/ 60);
    }

    // Nếu ngày nào đủ số phút mục tiêu thì thêm vào danh sách hoàn thành
    minutesPerDay.forEach((dateStr, minutes) {
      if (minutes >= dailyGoalMinutes) {
        completedDates.add(dateStr);
      }
    });

    if (completedDates.isEmpty) {
      currentStreak = 0;
      return;
    }

    // Sắp xếp danh sách các ngày tăng dần để tính toán chuỗi liên tục
    completedDates.sort();
    int tempStreak = 1;
    int maxStreak = 1;

    for (int i = 0; i < completedDates.length - 1; i++) {
      DateTime date1 = DateTime.parse(completedDates[i]);
      DateTime date2 = DateTime.parse(completedDates[i + 1]);
      
      if (date2.difference(date1).inDays == 1) {
        tempStreak++;
        if (tempStreak > maxStreak) {
          maxStreak = tempStreak;
        }
      } else if (date2.difference(date1).inDays > 1) {
        tempStreak = 1;
      }
    }

    longestStreak = maxStreak > longestStreak ? maxStreak : longestStreak;

    // Kiểm tra xem ngày hoàn thành cuối cùng có phải hôm nay hoặc hôm qua không để duy trì chuỗi
    DateTime now = DateTime.now();
    DateTime lastCompletedDate = DateTime.parse(completedDates.last);
    DateTime todayMidnight = DateTime(now.year, now.month, now.day);
    DateTime lastMidnight = DateTime(lastCompletedDate.year, lastCompletedDate.month, lastCompletedDate.day);
    int daysFromLastStudy = todayMidnight.difference(lastMidnight).inDays;
    
    if (daysFromLastStudy <= 1) {
      currentStreak = tempStreak;
    } else {
      currentStreak = 0;
    }
  }
}