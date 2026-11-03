import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _recordingPath;

  Stream<double> get amplitudeStream => _recorder
      .onAmplitudeChanged(const Duration(milliseconds: 200))
      .map((amplitude) => amplitude.current);

  /// Checks and requests microphone permission using the recorder plugin.
  /// This supports browser microphone permissions on Flutter Web.
  Future<bool> requestMicPermission() async {
    try {
      // Web: sử dụng cơ chế cấp quyền của package record.
      if (kIsWeb) {
        return await _recorder.hasPermission();
      }

      // Android và các nền tảng native:
      // giữ cơ chế xin quyền permission_handler ban đầu.
      final status = await Permission.microphone.request();
      return status.isGranted;
    } catch (error, stackTrace) {
      debugPrint('Microphone permission error: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> startRecording() async {
    if (await _recorder.isRecording()) {
      throw StateError('A recording is already in progress.');
    }

    if (!await requestMicPermission()) {
      throw StateError('Microphone permission was denied.');
    }

    late final String path;

    if (kIsWeb) {
      // The record Web implementation ignores this path.
      // The browser creates a Blob URL when recording stops.
      path = 'practice_${DateTime.now().microsecondsSinceEpoch}.wav';
    } else {
      final directory = await getApplicationDocumentsDirectory();
      path = join(
        directory.path,
        'practice_${DateTime.now().microsecondsSinceEpoch}.wav',
      );
    }

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        androidConfig: AndroidRecordConfig(
          useLegacy: true,
          audioSource: AndroidAudioSource.mic,
          manageBluetooth: false,
        ),
      ),
      path: path,
    );

    _recordingPath = path;
  }

  Future<String?> stopRecording() async {
    if (!await _recorder.isRecording()) return null;

    final path = await _recorder.stop() ?? _recordingPath;
    _recordingPath = null;

    if (path == null) return null;

    if (kIsWeb) {
      // On Web, this is a browser Blob URL, not a local file path.
      return path;
    }

    final file = File(path);
    if (!await file.exists()) return null;
    if (await file.length() == 0) return null;

    return path;
  }

  Future<void> dispose() => _recorder.dispose();
}
