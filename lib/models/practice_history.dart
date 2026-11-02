// Copyright (C) 2026 Daily You TH3 Learning English
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

const String practiceHistoryTable = 'practice_history';

/// Các loại hoạt động luyện tập tiếng Anh.
///
/// Hỗ trợ mở rộng: nếu trong tương lai có thêm loại mới từ API hoặc DB,
/// [ActivityType.fromValue] sẽ fallback về [ActivityType.other] thay vì crash.
enum ActivityType {
  pronunciation,
  listening,
  vocabulary,
  speaking,
  reading,
  other;

  static ActivityType fromValue(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ActivityType.other;
    }
    final normalized = value.trim().toUpperCase();
    switch (normalized) {
      case 'PRONUNCIATION':
        return ActivityType.pronunciation;
      case 'LISTENING':
        return ActivityType.listening;
      case 'VOCABULARY':
        return ActivityType.vocabulary;
      case 'SPEAKING':
        return ActivityType.speaking;
      case 'READING':
        return ActivityType.reading;
      case 'OTHER':
      default:
        return ActivityType.other;
    }
  }

  String toValue() => name.toUpperCase();
}

/// Trạng thái của phiên luyện tập.
enum PracticeStatus {
  inProgress,
  completed,
  cancelled;

  static PracticeStatus fromValue(String? value) {
    if (value == null || value.trim().isEmpty) {
      return PracticeStatus.inProgress;
    }
    switch (value.trim().toUpperCase()) {
      case 'COMPLETED':
        return PracticeStatus.completed;
      case 'CANCELLED':
        return PracticeStatus.cancelled;
      case 'IN_PROGRESS':
      default:
        return PracticeStatus.inProgress;
    }
  }

  String toValue() {
    switch (this) {
      case PracticeStatus.inProgress:
        return 'IN_PROGRESS';
      case PracticeStatus.completed:
        return 'COMPLETED';
      case PracticeStatus.cancelled:
        return 'CANCELLED';
    }
  }
}

class PracticeHistoryFields {
  static const List<String> values = [
    id,
    userId,
    activityType,
    content,
    startedAt,
    endedAt,
    durationSeconds,
    practiceDate,
    status,
    timeCreate,
    timeModified,
  ];
  static const String id = 'id';
  static const String userId = 'user_id';
  static const String activityType = 'activity_type';
  static const String content = 'content';
  static const String startedAt = 'started_at';
  static const String endedAt = 'ended_at';
  static const String durationSeconds = 'duration_seconds';
  static const String practiceDate = 'practice_date';
  static const String status = 'status';
  static const String timeCreate = 'time_create';
  static const String timeModified = 'time_modified';
}

/// Model lưu lịch sử phiên luyện tập của người dùng.
class PracticeHistory {
  final int? id;
  final int userId;
  final ActivityType activityType;
  final String content;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? durationSeconds;

  /// Ngày luyện tập theo định dạng YYYY-MM-DD để tối ưu tìm kiếm và báo cáo.
  final String practiceDate;

  final PracticeStatus status;
  final DateTime timeCreate;
  final DateTime timeModified;

  const PracticeHistory({
    this.id,
    required this.userId,
    required this.activityType,
    required this.content,
    required this.startedAt,
    this.endedAt,
    this.durationSeconds,
    required this.practiceDate,
    required this.status,
    required this.timeCreate,
    required this.timeModified,
  });

  static const _unset = Object();

  PracticeHistory copy({
    int? id,
    int? userId,
    ActivityType? activityType,
    String? content,
    DateTime? startedAt,
    Object? endedAt = _unset,
    Object? durationSeconds = _unset,
    String? practiceDate,
    PracticeStatus? status,
    DateTime? timeCreate,
    DateTime? timeModified,
  }) =>
      PracticeHistory(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        activityType: activityType ?? this.activityType,
        content: content ?? this.content,
        startedAt: startedAt ?? this.startedAt,
        endedAt: endedAt == _unset ? this.endedAt : endedAt as DateTime?,
        durationSeconds: durationSeconds == _unset
            ? this.durationSeconds
            : durationSeconds as int?,
        practiceDate: practiceDate ?? this.practiceDate,
        status: status ?? this.status,
        timeCreate: timeCreate ?? this.timeCreate,
        timeModified: timeModified ?? this.timeModified,
      );

  static PracticeHistory fromJson(Map<String, Object?> json) =>
      PracticeHistory(
        id: json[PracticeHistoryFields.id] as int?,
        userId: json[PracticeHistoryFields.userId] as int,
        activityType: ActivityType.fromValue(
            json[PracticeHistoryFields.activityType] as String?),
        content: json[PracticeHistoryFields.content] as String,
        startedAt:
            DateTime.parse(json[PracticeHistoryFields.startedAt] as String),
        endedAt: json[PracticeHistoryFields.endedAt] != null
            ? DateTime.parse(json[PracticeHistoryFields.endedAt] as String)
            : null,
        durationSeconds:
            json[PracticeHistoryFields.durationSeconds] as int?,
        practiceDate:
            json[PracticeHistoryFields.practiceDate] as String,
        status: PracticeStatus.fromValue(
            json[PracticeHistoryFields.status] as String?),
        timeCreate:
            DateTime.parse(json[PracticeHistoryFields.timeCreate] as String),
        timeModified:
            DateTime.parse(json[PracticeHistoryFields.timeModified] as String),
      );

  Map<String, Object?> toJson() => {
        PracticeHistoryFields.id: id,
        PracticeHistoryFields.userId: userId,
        PracticeHistoryFields.activityType: activityType.toValue(),
        PracticeHistoryFields.content: content,
        PracticeHistoryFields.startedAt: startedAt.toIso8601String(),
        PracticeHistoryFields.endedAt: endedAt?.toIso8601String(),
        PracticeHistoryFields.durationSeconds: durationSeconds,
        PracticeHistoryFields.practiceDate: practiceDate,
        PracticeHistoryFields.status: status.toValue(),
        PracticeHistoryFields.timeCreate: timeCreate.toIso8601String(),
        PracticeHistoryFields.timeModified: timeModified.toIso8601String(),
      };
}
