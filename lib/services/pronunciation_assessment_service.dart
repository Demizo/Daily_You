import '../models/pronunciation_result.dart';

class PronunciationAssessmentService {
  /// Đánh giá mức độ giống nhau giữa câu mẫu và văn bản nhận diện.
  ///
  /// Lưu ý: Đây là đánh giá dựa trên văn bản nhận diện,
  /// chưa phải phân tích âm thanh hoặc âm vị thực tế.
  static PronunciationResult assess({
    required int userId,
    int practiceId = 0,
    required String targetSentence,
    required String recognizedText,
    String? audioFilePath,
  }) {
    final referenceWords = _tokenize(targetSentence);
    final spokenWords = _tokenize(recognizedText);

    if (referenceWords.isEmpty) {
      throw ArgumentError('Câu mẫu không được để trống.');
    }

    if (spokenWords.isEmpty) {
      throw ArgumentError('Văn bản nhận diện không được để trống.');
    }

    final alignment = _alignWords(referenceWords, spokenWords);

    final wordScores = <WordScore>[];
    final mispronouncedWords = <MispronouncedWord>[];

    var totalScore = 0.0;

    for (var i = 0; i < referenceWords.length; i++) {
      final expected = referenceWords[i];
      final actual = alignment[i];

      double score;

      if (actual == null) {
        score = 0;
        mispronouncedWords.add(
          MispronouncedWord(word: expected, errorType: 'missing_word'),
        );
      } else {
        score = _similarity(expected, actual);

        if (score < 80) {
          mispronouncedWords.add(
            MispronouncedWord(word: expected, errorType: 'word_mismatch'),
          );
        }
      }

      totalScore += score;

      wordScores.add(WordScore(word: expected, score: score));
    }

    // Trừ điểm đối với những từ thừa trong câu nhận diện.
    final extraWords = _countExtraWords(referenceWords, spokenWords);

    final averageScore = totalScore / referenceWords.length;
    final penalty = extraWords * 5.0;

    final overallScore = (averageScore - penalty).clamp(0.0, 100.0).toDouble();

    final feedback = _generateFeedback(overallScore);

    final suggestions = _generateSuggestions(
      overallScore,
      mispronouncedWords,
      extraWords,
    );

    final String suggestionsText = suggestions.join('\n');

    return PronunciationResult(
      userId: userId,
      practiceId: practiceId,
      referenceSentence: targetSentence,
      recognizedText: recognizedText,
      overallScore: overallScore,
      wordScores: wordScores,
      mispronouncedWords: mispronouncedWords,
      feedback: feedback,
      suggestions: suggestionsText,
      evaluatedAt: DateTime.now(),
      audioFilePath: audioFilePath,
      timeCreate: DateTime.now(),
    );
  }

  /// Chuẩn hóa và tách câu thành các từ.
  static List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
  }

  /// Tính độ tương đồng giữa hai từ bằng Levenshtein.
  static double _similarity(String first, String second) {
    final distance = _levenshtein(first, second);
    final maxLength =
        first.length > second.length ? first.length : second.length;

    if (maxLength == 0) return 100;

    return ((maxLength - distance) / maxLength * 100)
        .clamp(0.0, 100.0)
        .toDouble();
  }

  /// Tính khoảng cách chỉnh sửa Levenshtein.
  static int _levenshtein(String first, String second) {
    final matrix = List.generate(
      first.length + 1,
      (_) => List<int>.filled(second.length + 1, 0),
    );

    for (var i = 0; i <= first.length; i++) {
      matrix[i][0] = i;
    }

    for (var j = 0; j <= second.length; j++) {
      matrix[0][j] = j;
    }

    for (var i = 1; i <= first.length; i++) {
      for (var j = 1; j <= second.length; j++) {
        final cost = first[i - 1] == second[j - 1] ? 0 : 1;

        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[first.length][second.length];
  }

  /// Căn chỉnh từ trong câu mẫu với từ được nhận diện.
  /// Cho phép bỏ qua hoặc thay thế từ.
  static List<String?> _alignWords(
    List<String> reference,
    List<String> spoken,
  ) {
    final rows = reference.length + 1;
    final cols = spoken.length + 1;

    final dp = List.generate(rows, (_) => List<int>.filled(cols, 0));

    for (var i = 0; i < rows; i++) {
      dp[i][0] = i;
    }

    for (var j = 0; j < cols; j++) {
      dp[0][j] = j;
    }

    for (var i = 1; i < rows; i++) {
      for (var j = 1; j < cols; j++) {
        final cost = reference[i - 1] == spoken[j - 1] ? 0 : 1;

        dp[i][j] = [
          dp[i - 1][j] + 1,
          dp[i][j - 1] + 1,
          dp[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    final result = List<String?>.filled(reference.length, null);

    var i = reference.length;
    var j = spoken.length;

    while (i > 0 || j > 0) {
      if (i > 0 &&
          j > 0 &&
          dp[i][j] ==
              dp[i - 1][j - 1] + (reference[i - 1] == spoken[j - 1] ? 0 : 1)) {
        result[i - 1] = spoken[j - 1];
        i--;
        j--;
      } else if (i > 0 && dp[i][j] == dp[i - 1][j] + 1) {
        result[i - 1] = null;
        i--;
      } else {
        j--;
      }
    }

    return result;
  }

  /// Đếm số từ thừa bằng độ dài câu sau khi căn chỉnh.
  static int _countExtraWords(List<String> reference, List<String> spoken) {
    final alignment = _alignWords(reference, spoken);
    final matchedCount = alignment.where((word) => word != null).length;

    return spoken.length - matchedCount;
  }

  static String _generateFeedback(double score) {
    if (score >= 90) {
      return 'Rất tốt! Văn bản nhận diện gần như trùng khớp với câu mẫu.';
    }

    if (score >= 75) {
      return 'Khá tốt! Bạn đã đọc tương đối chính xác, hãy luyện tập thêm.';
    }

    if (score >= 50) {
      return 'Bạn cần luyện tập thêm để cải thiện độ chính xác.';
    }

    return 'Hãy nghe lại câu mẫu và luyện đọc chậm từng từ.';
  }

  static List<String> _generateSuggestions(
    double score,
    List<MispronouncedWord> errors,
    int extraWords,
  ) {
    final suggestions = <String>[];

    if (score < 90) {
      suggestions.add('Nghe kỹ câu mẫu trước khi bắt đầu đọc.');
    }

    if (errors.isNotEmpty) {
      suggestions.add(
        'Chú ý luyện đọc lại các từ chưa được nhận diện chính xác.',
      );
    }

    if (extraWords > 0) {
      suggestions.add('Cố gắng đọc đúng nội dung câu mẫu và tránh thêm từ.');
    }

    if (suggestions.isEmpty) {
      suggestions.add('Tiếp tục duy trì cách luyện tập hiện tại.');
    }

    return suggestions;
  }
}
