import 'dart:async';

import 'package:logging/logging.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechToTextService {
  static const String fallbackText =
      'Không thể nhận dạng giọng nói, vui lòng thử lại.';
  static final SpeechToText _speech = SpeechToText();
  static final Logger _logger = Logger('SpeechToTextService');
  static Completer<String>? _activeResult;
  static String _recognizedText = '';
  static void Function(String text)? _onTextUpdate;
  static bool _isRecognizing = false;

  static Future<String> recognize({
    required void Function(String text) onTextUpdate,
  }) async {
    if (_isRecognizing) return fallbackText;

    _isRecognizing = true;
    _recognizedText = '';
    _activeResult = Completer<String>();
    _onTextUpdate = onTextUpdate;

    try {
      final available = await _speech.initialize(
        onError: (error) {
          _logger.warning('Speech recognition error: ${error.errorMsg}');
          _completeResult(fallbackText);
        },
        onStatus: _handleStatus,
      );
      if (!available) return fallbackText;

      await _speech.listen(
        listenOptions: SpeechListenOptions(
          localeId: 'en_US',
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          cancelOnError: true,
        ),
        onResult: _handleResult,
      );

      return await _activeResult!.future.timeout(
        const Duration(seconds: 35),
        onTimeout: () => fallbackText,
      );
    } catch (error, stackTrace) {
      _logger.warning('Speech recognition failed.', error, stackTrace);
      return fallbackText;
    } finally {
      try {
        if (_speech.isListening) {
          await _speech.stop();
        }
      } catch (error, stackTrace) {
        _logger.warning(
            'Stopping speech recognition failed.', error, stackTrace);
      }
      _reset();
    }
  }

  static Future<void> cancel() async {
    try {
      if (_speech.isListening) {
        await _speech.cancel();
      }
    } catch (error, stackTrace) {
      _logger.warning(
          'Cancelling speech recognition failed.', error, stackTrace);
    } finally {
      _completeResult(fallbackText);
    }
  }

  static void _handleResult(SpeechRecognitionResult result) {
    _recognizedText = result.recognizedWords;
    _onTextUpdate?.call(_recognizedText);
    if (result.finalResult) {
      _completeResult(_recognizedText);
    }
  }

  static void _handleStatus(String status) {
    if (status == SpeechToText.doneStatus) {
      _completeResult(_recognizedText);
    }
  }

  static void _completeResult(String text) {
    final result = _activeResult;
    if (result == null || result.isCompleted) return;

    final recognizedText = text.trim();
    final completedText =
        recognizedText.isEmpty ? fallbackText : recognizedText;
    _onTextUpdate?.call(completedText);
    result.complete(completedText);
  }

  static void _reset() {
    _activeResult = null;
    _onTextUpdate = null;
    _recognizedText = '';
    _isRecognizing = false;
  }
}
