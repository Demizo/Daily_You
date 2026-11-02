// Copyright (C) 2026 Daily You TH3 Learning English
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:convert';

const String pronunciationResultsTable = 'pronunciation_results';

/// Điểm phát âm từng từ/âm (hỗ trợ trường hợp API không trả điểm hoặc trả rỗng).
class WordScore {
  final String word;

  /// Điểm số từ 0..100 hoặc thang điểm tương ứng (nullable nếu API không trả).
  final double? score;

  /// Điểm chi tiết từng âm (phonemes) nếu API có hỗ trợ.
  final Map<String, double>? phonemeScores;

  const WordScore({
    required this.word,
    this.score,
    this.phonemeScores,
  });

  static WordScore fromJson(Map<String, dynamic> json) {
    Map<String, double>? phonemes;
    if (json['phoneme_scores'] is Map) {
      phonemes = (json['phoneme_scores'] as Map).map(
        (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
      );
    }
    return WordScore(
      word: (json['word'] as String?) ?? '',
      score: (json['score'] as num?)?.toDouble(),
      phonemeScores: phonemes,
    );
  }

  Map<String, dynamic> toJson() => {
        'word': word,
        'score': score,
        if (phonemeScores != null) 'phoneme_scores': phonemeScores,
      };
}

/// Thông tin từ/âm phát âm sai (nullable nếu API không trả).
class MispronouncedWord {
  final String word;
  final String? expectedPhoneme;
  final String? actualPhoneme;
  final String? errorType;

  const MispronouncedWord({
    required this.word,
    this.expectedPhoneme,
    this.actualPhoneme,
    this.errorType,
  });

  static MispronouncedWord fromJson(Map<String, dynamic> json) =>
      MispronouncedWord(
        word: (json['word'] as String?) ?? '',
        expectedPhoneme: json['expected'] as String?,
        actualPhoneme: json['actual'] as String?,
        errorType: json['error_type'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'word': word,
        'expected': expectedPhoneme,
        'actual': actualPhoneme,
        if (errorType != null) 'error_type': errorType,
      };
}

class PronunciationResultFields {
  static const List<String> values = [
    id,
    userId,
    practiceId,
    referenceSentence,
    recognizedText,
    overallScore,
    wordScores,
    mispronouncedWords,
    feedback,
    suggestions,
    evaluatedAt,
    audioFilePath,
    timeCreate,
  ];
  static const String id = 'id';
  static const String userId = 'user_id';
  static const String practiceId = 'practice_id';
  static const String referenceSentence = 'reference_sentence';
  static const String recognizedText = 'recognized_text';
  static const String overallScore = 'overall_score';
  static const String wordScores = 'word_scores';
  static const String mispronouncedWords = 'mispronounced_words';
  static const String feedback = 'feedback';
  static const String suggestions = 'suggestions';
  static const String evaluatedAt = 'evaluated_at';
  static const String audioFilePath = 'audio_file_path';
  static const String timeCreate = 'time_create';
}

/// Model lưu kết quả phân tích phát âm.
///
/// Các trường điểm số, nhận diện và từ sai đều có thể null nếu API không trả.
class PronunciationResult {
  final int? id;
  final int userId;
  final int practiceId;

  /// Câu mẫu cần luyện tập.
  final String referenceSentence;

  /// Văn bản nhận diện được từ giọng nói (null nếu API chưa hỗ trợ nhận diện).
  final String? recognizedText;

  /// Điểm tổng (null nếu API không cung cấp điểm).
  final double? overallScore;

  /// Danh sách điểm từng từ/âm (null hoặc rỗng nếu API không hỗ trợ).
  final List<WordScore>? wordScores;

  /// Danh sách từ/âm phát âm sai (null hoặc rỗng nếu không phát hiện hoặc API không hỗ trợ).
  final List<MispronouncedWord>? mispronouncedWords;

  /// Nhận xét đánh giá từ API hoặc hệ thống.
  final String? feedback;

  /// Gợi ý cải thiện phát âm.
  final String? suggestions;

  /// Thời điểm thực hiện đánh giá.
  final DateTime evaluatedAt;

  /// Đường dẫn lưu file ghi âm (nếu có).
  final String? audioFilePath;

  final DateTime timeCreate;

  const PronunciationResult({
    this.id,
    required this.userId,
    required this.practiceId,
    required this.referenceSentence,
    this.recognizedText,
    this.overallScore,
    this.wordScores,
    this.mispronouncedWords,
    this.feedback,
    this.suggestions,
    required this.evaluatedAt,
    this.audioFilePath,
    required this.timeCreate,
  });

  static const _unset = Object();

  PronunciationResult copy({
    int? id,
    int? userId,
    int? practiceId,
    String? referenceSentence,
    Object? recognizedText = _unset,
    Object? overallScore = _unset,
    Object? wordScores = _unset,
    Object? mispronouncedWords = _unset,
    Object? feedback = _unset,
    Object? suggestions = _unset,
    DateTime? evaluatedAt,
    Object? audioFilePath = _unset,
    DateTime? timeCreate,
  }) =>
      PronunciationResult(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        practiceId: practiceId ?? this.practiceId,
        referenceSentence: referenceSentence ?? this.referenceSentence,
        recognizedText: recognizedText == _unset
            ? this.recognizedText
            : recognizedText as String?,
        overallScore: overallScore == _unset
            ? this.overallScore
            : overallScore as double?,
        wordScores: wordScores == _unset
            ? this.wordScores
            : wordScores as List<WordScore>?,
        mispronouncedWords: mispronouncedWords == _unset
            ? this.mispronouncedWords
            : mispronouncedWords as List<MispronouncedWord>?,
        feedback:
            feedback == _unset ? this.feedback : feedback as String?,
        suggestions: suggestions == _unset
            ? this.suggestions
            : suggestions as String?,
        evaluatedAt: evaluatedAt ?? this.evaluatedAt,
        audioFilePath: audioFilePath == _unset
            ? this.audioFilePath
            : audioFilePath as String?,
        timeCreate: timeCreate ?? this.timeCreate,
      );

  static PronunciationResult fromJson(Map<String, Object?> json) {
    final wordScoresRaw =
        json[PronunciationResultFields.wordScores] as String?;
    final mispronouncedRaw =
        json[PronunciationResultFields.mispronouncedWords] as String?;

    List<WordScore>? parsedWordScores;
    if (wordScoresRaw != null && wordScoresRaw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(wordScoresRaw);
        if (decoded is List) {
          parsedWordScores = decoded
              .whereType<Map<String, dynamic>>()
              .map((e) => WordScore.fromJson(e))
              .toList();
        }
      } catch (_) {
        parsedWordScores = null;
      }
    }

    List<MispronouncedWord>? parsedMispronounced;
    if (mispronouncedRaw != null && mispronouncedRaw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(mispronouncedRaw);
        if (decoded is List) {
          parsedMispronounced = decoded
              .whereType<Map<String, dynamic>>()
              .map((e) => MispronouncedWord.fromJson(e))
              .toList();
        }
      } catch (_) {
        parsedMispronounced = null;
      }
    }

    return PronunciationResult(
      id: json[PronunciationResultFields.id] as int?,
      userId: json[PronunciationResultFields.userId] as int,
      practiceId: json[PronunciationResultFields.practiceId] as int,
      referenceSentence:
          json[PronunciationResultFields.referenceSentence] as String,
      recognizedText:
          json[PronunciationResultFields.recognizedText] as String?,
      overallScore:
          (json[PronunciationResultFields.overallScore] as num?)?.toDouble(),
      wordScores: parsedWordScores,
      mispronouncedWords: parsedMispronounced,
      feedback: json[PronunciationResultFields.feedback] as String?,
      suggestions: json[PronunciationResultFields.suggestions] as String?,
      evaluatedAt: DateTime.parse(
          json[PronunciationResultFields.evaluatedAt] as String),
      audioFilePath:
          json[PronunciationResultFields.audioFilePath] as String?,
      timeCreate: DateTime.parse(
          json[PronunciationResultFields.timeCreate] as String),
    );
  }

  Map<String, Object?> toJson() => {
        PronunciationResultFields.id: id,
        PronunciationResultFields.userId: userId,
        PronunciationResultFields.practiceId: practiceId,
        PronunciationResultFields.referenceSentence: referenceSentence,
        PronunciationResultFields.recognizedText: recognizedText,
        PronunciationResultFields.overallScore: overallScore,
        PronunciationResultFields.wordScores: wordScores != null
            ? jsonEncode(wordScores!.map((e) => e.toJson()).toList())
            : null,
        PronunciationResultFields.mispronouncedWords:
            mispronouncedWords != null
                ? jsonEncode(
                    mispronouncedWords!.map((e) => e.toJson()).toList())
                : null,
        PronunciationResultFields.feedback: feedback,
        PronunciationResultFields.suggestions: suggestions,
        PronunciationResultFields.evaluatedAt:
            evaluatedAt.toIso8601String(),
        PronunciationResultFields.audioFilePath: audioFilePath,
        PronunciationResultFields.timeCreate: timeCreate.toIso8601String(),
      };
}
