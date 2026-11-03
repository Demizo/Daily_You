// Copyright (C) 2026 Daily You TH3 Learning English
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:async';
import 'dart:io';
import 'package:daily_you/database/practice_history_dao.dart';
import 'package:daily_you/database/pronunciation_result_dao.dart';
import 'package:daily_you/database/study_sentence_dao.dart';
import 'package:daily_you/models/practice_history.dart';
import 'package:daily_you/models/pronunciation_result.dart';
import 'package:daily_you/models/study_sentence.dart';
import 'package:daily_you/providers/learning_progress_provider.dart';
import 'package:daily_you/providers/user_session_provider.dart';
import 'package:daily_you/services/audio_recorder_service.dart';
import 'package:daily_you/services/speech_to_text_service.dart';
import 'package:daily_you/widgets/add_sentence_dialog.dart';
import 'package:daily_you/widgets/user_profile_bar.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

/// Màn hình Luyện phát âm tiếng Anh thực tế (Template chuẩn cho TV4 & TV5).
///
/// TÍNH NĂNG THỰC TẾ CAO:
/// - Thư viện ~24 câu mẫu thực tế phân theo 4 chủ đề giao tiếp thông dụng.
/// - Cho phép học viên TỰ THÊM câu luyện tập của riêng mình (+ Thêm câu mới).
/// - Quản lý CSDL SQLite v8 độc lập theo từng tài khoản học viên (Multi-user).
///
/// TUÂN THỦ NGUYÊN TẮC MÀU SẮC:
/// - Theme ứng dụng: Tone Periwinkle Pastel (#B1B2FF - #EEF1FF).
/// - Ngọn lửa streak: Cam/đỏ rực rỡ (#EA580C - #F97316).
/// - Kết quả đúng: Xanh lá cây (#2E7D32).
/// - Kết quả sai: Đỏ (#D32F2F).
/// - Kết quả trung bình: Cam hổ phách (#F57C00).
class PracticeSpeechPage extends StatefulWidget {
  const PracticeSpeechPage({super.key});

  @override
  State<PracticeSpeechPage> createState() => _PracticeSpeechPageState();
}

class _PracticeSpeechPageState extends State<PracticeSpeechPage> {
  String _selectedTopic = 'all';
  List<StudySentence> _sentences = [];
  int _selectedSentenceIndex = 0;
  bool _isLoadingSentences = true;

  // -------------------------------------------------------------
  // TRẠNG THÁI CỦA TV4 (GHI ÂM VÀ SPEECH API)
  // -------------------------------------------------------------
  bool _isRecording = false;
  bool _isRecognizingSpeech = false;
  int _recordingSeconds = 0;
  double _currentMicLevel = -160;
  double _peakMicLevel = -160;
  Timer? _recordingTimer;
  StreamSubscription<double>? _amplitudeSubscription;
  String? _recognizedText;
  String? _recordedAudioPath;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _loadedAudioPath;
  final AudioRecorderService _audioRecorderService = AudioRecorderService();

  // -------------------------------------------------------------
  // TRẠNG THÁI CỦA TV5 (ĐÁNH GIÁ VÀ CHẤM ĐIỂM PHÁT ÂM)
  // -------------------------------------------------------------
  bool _isScoring = false;
  PronunciationResult? _latestResult;

  final Map<String, String> _topics = {
    'all': '🌟 Tất cả',
    'daily': '☕ Giao tiếp',
    'travel': '✈️ Du lịch',
    'work': '💼 Công sở',
    'dining': '🍔 Ẩm thực',
    'custom': '⭐ Câu của tôi',
  };

  @override
  void initState() {
    super.initState();
    _loadSentences();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    unawaited(_amplitudeSubscription?.cancel());
    if (_isRecognizingSpeech) {
      unawaited(SpeechToTextService.cancel());
    }
    unawaited(_audioPlayer.dispose());
    unawaited(_audioRecorderService.dispose());
    super.dispose();
  }

  Future<void> _loadSentences({int? selectId}) async {
    setState(() => _isLoadingSentences = true);
    final session = context.read<UserSessionProvider>();
    final currentUserId = session.currentUserId;

    final list = await StudySentenceDao.getByTopic(
      _selectedTopic,
      userId: currentUserId,
    );

    if (mounted) {
      setState(() {
        _sentences = list;
        _isLoadingSentences = false;
        if (selectId != null) {
          final idx = _sentences.indexWhere((s) => s.id == selectId);
          _selectedSentenceIndex = idx != -1 ? idx : 0;
        } else if (_selectedSentenceIndex >= _sentences.length) {
          _selectedSentenceIndex = 0;
        }
        _recognizedText = null;
        _latestResult = null;
      });
    }
  }

  Future<void> _openAddSentenceDialog() async {
    final initialTopic = _selectedTopic == 'all' ? 'daily' : _selectedTopic;
    final newSentence = await AddSentenceDialog.show(
      context,
      initialTopic: initialTopic,
    );

    if (newSentence != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm câu mới: "${newSentence.sentence}"'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _loadSentences(selectId: newSentence.id);
    }
  }

  Future<void> _handleDeleteCustomSentence(StudySentence sentence) async {
    if (sentence.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa câu'),
        content: Text(
            'Bạn có chắc chắn muốn xóa câu "${sentence.sentence}" khỏi danh sách?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await StudySentenceDao.remove(sentence.id!);
      await _loadSentences();
    }
  }

  // =============================================================
  // [TV4 CODE SECTION] - GHI ÂM VÀ NHẬN DẠNG GIỌNG NÓI
  // =============================================================
  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      await _audioPlayer.stop();
      await _audioRecorderService.startRecording();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể bắt đầu ghi âm: $error')),
      );
      return;
    }

    if (!mounted) {
      await _audioRecorderService.stopRecording();
      return;
    }

    setState(() {
      _isRecording = true;
      _recordingSeconds = 0;
      _currentMicLevel = -160;
      _peakMicLevel = -160;
      _recognizedText = null;
      _recordedAudioPath = null;
      _latestResult = null;
      _loadedAudioPath = null;
    });

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _recordingSeconds++);
      }
    });
    _amplitudeSubscription =
        _audioRecorderService.amplitudeStream.listen((amplitude) {
      if (!mounted) return;
      setState(() {
        _currentMicLevel = amplitude;
        if (amplitude > _peakMicLevel) {
          _peakMicLevel = amplitude;
        }
      });
    }, onError: (Object error, StackTrace stackTrace) {
      debugPrint('Reading microphone level failed: $error');
    });
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    setState(() => _isRecording = false);

    String? audioPath;
    try {
      audioPath = await _audioRecorderService.stopRecording();
      if (audioPath == null) {
        throw StateError('No recorded audio file was produced.');
      }
      if (mounted) {
        setState(() {
          _recordedAudioPath = _peakMicLevel >= -55 ? audioPath : null;
          _recognizedText = null;
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _recordedAudioPath = audioPath);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể hoàn tất ghi âm: $error')),
      );
      return;
    }

    if (!mounted) return;
    if (_peakMicLevel < -55) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Không thu được tiếng từ micro '
            '(mức cao nhất ${_peakMicLevel.toStringAsFixed(0)} dBFS). '
            'Hãy kiểm tra đầu vào micro rồi ghi lại.',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Đã lưu bản ghi. Bạn có thể nghe lại hoặc đọc lại để nhận dạng.',
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _recognizeRecordedSpeech() async {
    if (_recordedAudioPath == null || _isRecognizingSpeech) return;

    setState(() {
      _isRecognizingSpeech = true;
      _recognizedText = null;
    });

    try {
      await _audioPlayer.stop();
      final recognizedText = await SpeechToTextService.recognize(
        onTextUpdate: (text) {
          if (mounted) setState(() => _recognizedText = text);
        },
      );
      if (mounted) setState(() => _recognizedText = recognizedText);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể chuẩn bị nhận dạng giọng nói: $error'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRecognizingSpeech = false);
    }
  }

  Future<void> _playRecordedAudio() async {
    final audioPath = _recordedAudioPath;
    if (audioPath == null) return;

    try {
      final audioFile = File(audioPath);
      if (!await audioFile.exists() || await audioFile.length() == 0) {
        throw StateError('Bản ghi không có dữ liệu âm thanh.');
      }
      if (_audioPlayer.playing) {
        await _audioPlayer.pause();
        return;
      }

      final audioSession = await AudioSession.instance;
      await audioSession.configure(const AudioSessionConfiguration.music());
      if (!await audioSession.setActive(true)) {
        throw StateError('Không thể kích hoạt đầu ra âm thanh.');
      }

      if (_loadedAudioPath != audioPath) {
        final duration = await _audioPlayer.setFilePath(audioPath);
        if (duration == null || duration <= Duration.zero) {
          throw StateError('Không thể đọc nội dung âm thanh của bản ghi.');
        }
        _loadedAudioPath = audioPath;
      }
      if (_audioPlayer.processingState == ProcessingState.completed) {
        await _audioPlayer.seek(Duration.zero);
      }
      await _audioPlayer.setVolume(1);
      await _audioPlayer.play();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể phát lại bản ghi: $error')),
      );
    }
  }

  // =============================================================
  // [TV5 CODE SECTION] - ĐÁNH GIÁ PHÁT ÂM VÀ LƯU VÀO CSDL
  // =============================================================
  Future<void> _evaluatePronunciation() async {
    if (_sentences.isEmpty) return;
    final recognizedText = _recognizedText?.trim();
    if (recognizedText == null ||
        recognizedText.isEmpty ||
        recognizedText == SpeechToTextService.fallbackText) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Hãy nhận dạng câu nói thành công trước khi gửi kết quả cho TV5.',
          ),
        ),
      );
      return;
    }
    setState(() => _isScoring = true);

    final currentUserId = context.read<UserSessionProvider>().currentUserId;
    final targetText = _sentences[_selectedSentenceIndex].sentence;
    final words = targetText
        .replaceAll('.', '')
        .replaceAll('?', '')
        .replaceAll(',', '')
        .split(' ');

    await Future.delayed(const Duration(milliseconds: 800));

    // TODO [TV5]: Thay thế logic bên dưới bằng AI Scoring API
    final wordScores = words.asMap().entries.map((entry) {
      final isNearPerfect = entry.key % 2 == 0;
      return WordScore(
        word: entry.value,
        score: isNearPerfect ? 95.0 : 75.0,
      );
    }).toList();

    final mispronounced = [
      MispronouncedWord(
        word: words.last,
        expectedPhoneme: '/t/',
        actualPhoneme: '/-/',
        errorType: 'Ending consonant reduction',
      ),
    ];

    final now = DateTime.now();

    final result = PronunciationResult(
      userId: currentUserId,
      practiceId: 0,
      referenceSentence: targetText,
      recognizedText: recognizedText,
      overallScore: 88.0,
      wordScores: wordScores,
      mispronouncedWords: mispronounced,
      feedback: 'Phát âm to, rõ ràng và trôi chảy!',
      suggestions: 'Chú ý phát âm rõ âm gió và âm bật hơi cuối từ.',
      evaluatedAt: now,
      audioFilePath: _recordedAudioPath,
      timeCreate: now,
    );

    if (mounted) {
      setState(() {
        _isScoring = false;
        _latestResult = result;
      });
    }
  }

  Future<void> _saveResultToDatabase() async {
    if (_sentences.isEmpty) return;
    final session = context.read<UserSessionProvider>();
    final currentUserId = session.currentUserId;
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final duration = _recordingSeconds > 0 ? _recordingSeconds : 30;
    final history = await PracticeHistoryDao.add(PracticeHistory(
      userId: currentUserId,
      activityType: ActivityType.pronunciation,
      content: _sentences[_selectedSentenceIndex].sentence,
      startedAt: now.subtract(Duration(seconds: duration)),
      endedAt: now,
      durationSeconds: duration,
      practiceDate: dateStr,
      status: PracticeStatus.completed,
      timeCreate: now,
      timeModified: now,
    ));

    if (_latestResult != null && history.id != null) {
      await PronunciationResultDao.add(_latestResult!.copy(
        practiceId: history.id!,
        userId: currentUserId,
      ));
    }

    if (mounted) {
      context
          .read<LearningProgressProvider>()
          .loadProgress(userId: currentUserId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã lưu kết quả thành công cho học viên: ${session.currentUser?.name ?? "ID #$currentUserId"}',
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeSentence =
        _sentences.isNotEmpty && _selectedSentenceIndex < _sentences.length
            ? _sentences[_selectedSentenceIndex]
            : null;

    return Column(
      children: [
        // ---------------------------------------------------------
        // HEADER TRANG
        // ---------------------------------------------------------
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Luyện phát âm tiếng Anh',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const UserProfileBar(isCard: false),
            ],
          ),
        ),
        const Divider(height: 1),

        // ---------------------------------------------------------
        // BODY CUỘN NỘI DUNG
        // ---------------------------------------------------------
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Thông tin học viên
              const UserProfileBar(isCard: true),
              const SizedBox(height: 14),

              // BỘ LỌC CHỦ ĐỀ & NÚT THÊM CÂU
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CHỦ ĐỀ ÔN TẬP',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                    ),
                    icon:
                        const Icon(Icons.add_circle_outline_rounded, size: 18),
                    label: const Text('+ Thêm câu mới'),
                    onPressed: _openAddSentenceDialog,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Horizontal list of Topic Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _topics.entries.map((entry) {
                    final isSelected = _selectedTopic == entry.key;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            setState(() {
                              _selectedTopic = entry.key;
                              _selectedSentenceIndex = 0;
                            });
                            _loadSentences();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outlineVariant
                                        .withAlpha(80),
                              ),
                            ),
                            child: Text(
                              entry.value,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),

              // CARD HIỂN THỊ CÂU ĐANG LUYỆN TẬP
              if (_isLoadingSentences)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_sentences.isEmpty)
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const Icon(Icons.note_alt_outlined,
                            size: 40, color: Colors.grey),
                        const SizedBox(height: 10),
                        const Text('Chưa có câu nào trong chủ đề này.'),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm câu của riêng bạn ngay'),
                          onPressed: _openAddSentenceDialog,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                        color: theme.colorScheme.outlineVariant.withAlpha(80)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Chọn câu trong danh sách
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'CÂU SỐ ${_selectedSentenceIndex + 1} / ${_sentences.length}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                            if (activeSentence != null &&
                                activeSentence.isCustom)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Câu tự tạo ⭐',
                                      style: TextStyle(
                                        color: Colors.amber.shade900,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 18, color: Color(0xFFD32F2F)),
                                    tooltip: 'Xóa câu tự tạo này',
                                    onPressed: () =>
                                        _handleDeleteCustomSentence(
                                            activeSentence),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Thanh cuộn chọn nhanh các câu
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(_sentences.length, (idx) {
                              final isSelected = _selectedSentenceIndex == idx;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6.0),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () {
                                      setState(() {
                                        _selectedSentenceIndex = idx;
                                        _recognizedText = null;
                                        _latestResult = null;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme
                                                .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        'Câu ${idx + 1}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? theme.colorScheme.onPrimary
                                              : theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Nội dung câu
                        Text(
                          activeSentence?.sentence ?? '',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (activeSentence?.ipa != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            activeSentence!.ipa!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          'Ý nghĩa: ${activeSentence?.meaning ?? ""}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // =====================================================
              // KHU VỰC TV4: THU ÂM & MICROPHONE (SPEECH API)
              // =====================================================
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: _isRecording
                        ? const Color(0xFFD32F2F)
                        : theme.colorScheme.outlineVariant.withAlpha(80),
                    width: _isRecording ? 2 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.mic_rounded,
                            color: _isRecording
                                ? const Color(0xFFD32F2F)
                                : theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Khu vực TV4: Thu âm & Nhận dạng giọng nói',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Nút Micro lớn
                      GestureDetector(
                        onTap: _isRecognizingSpeech ? null : _toggleRecording,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: _isRecording
                                ? const Color(0xFFD32F2F)
                                : theme.colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                            boxShadow: _isRecording
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFD32F2F)
                                          .withAlpha(120),
                                      blurRadius: 20,
                                      spreadRadius: 4,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            _isRecording
                                ? Icons.stop_rounded
                                : Icons.mic_rounded,
                            size: 40,
                            color: _isRecording
                                ? Colors.white
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text(
                        _isRecognizingSpeech
                            ? 'Đang nghe. Hãy đọc câu tiếng Anh để nhận dạng.'
                            : _isRecording
                                ? 'Đang ghi âm: 00:${_recordingSeconds.toString().padLeft(2, '0')} (Nhấn để dừng)'
                                : _recordedAudioPath != null
                                    ? 'Đã ghi âm. Đọc lại câu khi nhấn nút nhận dạng.'
                                    : 'Nhấn vào micro để bắt đầu ghi âm.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _isRecording || _isRecognizingSpeech
                              ? const Color(0xFFD32F2F)
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (_isRecording) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Tín hiệu micro: ${_currentMicLevel.toStringAsFixed(0)} dBFS',
                          style: theme.textTheme.bodySmall,
                        ),
                        LinearProgressIndicator(
                          value: ((_currentMicLevel + 60) / 60)
                              .clamp(0.0, 1.0)
                              .toDouble(),
                        ),
                      ],

                      if (_recordedAudioPath != null) ...[
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _isRecognizingSpeech
                              ? null
                              : _recognizeRecordedSpeech,
                          icon: _isRecognizingSpeech
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.record_voice_over),
                          label: Text(
                            _isRecognizingSpeech
                                ? 'Đang nhận dạng...'
                                : 'Đọc lại câu để nhận dạng',
                          ),
                        ),
                        const SizedBox(height: 8),
                        StreamBuilder<PlayerState>(
                          stream: _audioPlayer.playerStateStream,
                          builder: (context, snapshot) {
                            final isPlaying =
                                snapshot.data?.playing ?? _audioPlayer.playing;
                            return ElevatedButton.icon(
                              onPressed: _isRecognizingSpeech
                                  ? null
                                  : _playRecordedAudio,
                              icon: Icon(
                                isPlaying ? Icons.pause_rounded : Icons.replay,
                              ),
                              label: Text(
                                isPlaying
                                    ? 'Tạm dừng phát lại'
                                    : 'Nghe lại đoạn vừa ghi',
                              ),
                            );
                          },
                        ),
                      ],

                      if (_recognizedText != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withAlpha(100),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.record_voice_over_outlined,
                                  size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Văn bản TV4 nhận dạng: "$_recognizedText"',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // =====================================================
              // KHU VỰC TV5: ĐÁNH GIÁ PHÁT ÂM & CHẤM ĐIỂM
              // =====================================================
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withAlpha(80)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded,
                              color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Khu vực TV5: Đánh giá & Chấm điểm phát âm',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_latestResult == null) ...[
                        FilledButton.tonalIcon(
                          onPressed: _isScoring ? null : _evaluatePronunciation,
                          icon: _isScoring
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.analytics_outlined),
                          label: Text(_isScoring
                              ? 'Đang phân tích phát âm...'
                              : 'Chấm điểm phát âm (Test TV5)'),
                        ),
                      ] else ...[
                        // Điểm số tổng quát (Tuân thủ màu ngữ nghĩa: Chuẩn xanh lá, Lỗi đỏ)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32).withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFF2E7D32).withAlpha(80)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildScoreItem(
                                'Tổng điểm',
                                '${_latestResult!.overallScore?.toStringAsFixed(0) ?? "0"}/100',
                                const Color(0xFF2E7D32), // Xanh lá chuẩn
                              ),
                              _buildScoreItem(
                                'Từ chuẩn ✅',
                                '${_latestResult!.wordScores?.where((w) => (w.score ?? 0) >= 80).length ?? 0}/${_latestResult!.wordScores?.length ?? 0}',
                                const Color(0xFF2E7D32), // Xanh lá
                              ),
                              _buildScoreItem(
                                'Từ cần sửa ❌',
                                '${_latestResult!.mispronouncedWords?.length ?? 0}',
                                const Color(0xFFD32F2F), // Đỏ chuẩn
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Phân tích từng từ
                        Text(
                          'Chi tiết từng từ:',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: (_latestResult!.wordScores ?? []).map((w) {
                            final isGood = (w.score ?? 0) >= 80;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isGood
                                    ? const Color(0xFFE8F5E9) // Xanh lá nhạt
                                    : const Color(0xFFFFEBEE), // Đỏ nhạt
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isGood
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFFD32F2F),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '${w.word} (${w.score?.toInt() ?? 0}%)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isGood
                                      ? const Color(0xFF2E7D32) // Xanh lá
                                      : const Color(0xFFD32F2F), // Đỏ
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),

                        // Nhận xét & gợi ý
                        if (_latestResult!.feedback != null ||
                            _latestResult!.suggestions != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withAlpha(80),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_latestResult!.feedback != null)
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.feedback_outlined,
                                          size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _latestResult!.feedback!,
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (_latestResult!.suggestions != null) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                          Icons.tips_and_updates_outlined,
                                          size: 18,
                                          color: Color(0xFFF57C00)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _latestResult!.suggestions!,
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),

                        // Nút Lưu kết quả vào SQLite
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                icon: const Icon(Icons.save_rounded),
                                label:
                                    const Text('Lưu kết quả học tập vào CSDL'),
                                onPressed: _saveResultToDatabase,
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              child: const Text('Thử lại'),
                              onPressed: () {
                                setState(() {
                                  _latestResult = null;
                                  _recognizedText = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScoreItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }
}
