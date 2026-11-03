import 'dart:io';

import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _recordingPath;

  Stream<double> get amplitudeStream => _recorder
      .onAmplitudeChanged(const Duration(milliseconds: 200))
      .map((amplitude) => amplitude.current);

  Future<bool> requestMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> startRecording() async {
    if (await _recorder.isRecording()) {
      throw StateError('A recording is already in progress.');
    }

    if (!await requestMicPermission()) {
      throw StateError('Microphone permission was denied.');
    }

    final directory = await getApplicationDocumentsDirectory();
    final path = join(
      directory.path,
      'practice_${DateTime.now().microsecondsSinceEpoch}.wav',
    );

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
    if (path == null || !await File(path).exists()) return null;
    if (await File(path).length() == 0) return null;

    return path;
  }

  Future<void> dispose() => _recorder.dispose();
}
