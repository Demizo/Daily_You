// Copyright (C) 2026 Daily You TH3 Learning English
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

const String studySentencesTable = 'study_sentences';

class StudySentenceFields {
  static const List<String> values = [
    id,
    userId,
    topic,
    sentence,
    meaning,
    ipa,
    timeCreate,
  ];

  static const String id = 'id';
  static const String userId = 'user_id';
  static const String topic = 'topic';
  static const String sentence = 'sentence';
  static const String meaning = 'meaning';
  static const String ipa = 'ipa';
  static const String timeCreate = 'time_create';
}

/// Model lưu câu luyện tập tiếng Anh (cả câu có sẵn và câu do học viên tự tạo).
class StudySentence {
  final int? id;

  /// ID của học viên tạo câu này (null nếu là câu mẫu mặc định của hệ thống).
  final int? userId;

  /// Mã chủ đề: 'daily', 'travel', 'work', 'dining', 'custom'
  final String topic;

  /// Nội dung câu tiếng Anh cần luyện phát âm
  final String sentence;

  /// Nghĩa tiếng Việt của câu
  final String meaning;

  /// Phiên âm chuẩn IPA (tùy chọn)
  final String? ipa;

  /// Thời điểm tạo câu
  final DateTime timeCreate;

  const StudySentence({
    this.id,
    this.userId,
    required this.topic,
    required this.sentence,
    required this.meaning,
    this.ipa,
    required this.timeCreate,
  });

  bool get isCustom => userId != null;

  StudySentence copy({
    int? id,
    int? userId,
    String? topic,
    String? sentence,
    String? meaning,
    String? ipa,
    DateTime? timeCreate,
  }) {
    return StudySentence(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      topic: topic ?? this.topic,
      sentence: sentence ?? this.sentence,
      meaning: meaning ?? this.meaning,
      ipa: ipa ?? this.ipa,
      timeCreate: timeCreate ?? this.timeCreate,
    );
  }

  Map<String, dynamic> toJson() => {
        StudySentenceFields.id: id,
        StudySentenceFields.userId: userId,
        StudySentenceFields.topic: topic,
        StudySentenceFields.sentence: sentence,
        StudySentenceFields.meaning: meaning,
        StudySentenceFields.ipa: ipa,
        StudySentenceFields.timeCreate: timeCreate.toIso8601String(),
      };

  static StudySentence fromJson(Map<String, dynamic> json) => StudySentence(
        id: json[StudySentenceFields.id] as int?,
        userId: json[StudySentenceFields.userId] as int?,
        topic: json[StudySentenceFields.topic] as String? ?? 'daily',
        sentence: json[StudySentenceFields.sentence] as String? ?? '',
        meaning: json[StudySentenceFields.meaning] as String? ?? '',
        ipa: json[StudySentenceFields.ipa] as String?,
        timeCreate: json[StudySentenceFields.timeCreate] != null
            ? DateTime.parse(json[StudySentenceFields.timeCreate] as String)
            : DateTime.now(),
      );
}

