// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:async';
import 'dart:io';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/database/attachment_storage.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/utils/duration_format.dart';
import 'package:daily_you/utils/recording_temporary_files.dart';
import 'package:daily_you/widgets/audio_waveform_decoration.dart';
import 'package:daily_you/widgets/expressive_icon_button.dart';
import 'package:daily_you/widgets/failure_dialog.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class AudioRecorderPage extends StatefulWidget {
  const AudioRecorderPage({super.key});

  @override
  State<AudioRecorderPage> createState() => _AudioRecorderPageState();
}

class _AudioRecorderPageState extends State<AudioRecorderPage>
    with WidgetsBindingObserver {
  static const Duration _confirmDiscardAfter = Duration(seconds: 3);

  static const double _secondaryButtonSize = 56;
  static const double _waveformHeight = 200;
  static const double _waveformOpacity = 0.18;

  static const Duration _minimumSaveDuration = Duration(seconds: 1);

  final Logger _logger = Logger('AudioRecorderPage');
  final AudioRecorder _recorder = AudioRecorder();
  final int _waveformSeed = DateTime.now().microsecondsSinceEpoch;
  final Stopwatch _stopwatch = Stopwatch();
  final ValueNotifier<Duration> _elapsedSeconds = ValueNotifier(Duration.zero);
  StreamSubscription<RecordState>? _stateSubscription;
  Timer? _ticker;
  String? _temporaryPath;
  bool _starting = false;
  bool _started = false;
  bool _isPaused = false;
  bool _recorderStopped = false;
  bool _finishing = false;
  bool _confirmingDiscard = false;
  bool _resetting = false;

  bool get _busy => _starting || _finishing || _resetting;

  bool get _isRecording => _started && !_isPaused && !_recorderStopped;

  bool get _canReset => _started && !_recorderStopped && !_busy;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(deleteStaleRecordings());
    _stateSubscription = _recorder.onStateChanged().listen(_applyState,
        onError: (Object error, StackTrace stackTrace) =>
            _logger.warning('Recorder state error', error, stackTrace));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _stateSubscription?.cancel();
    _elapsedSeconds.dispose();
    unawaited(_releaseRecorder());
    super.dispose();
  }

  Future<void> _releaseRecorder() async {
    await _recorder.dispose();
    await _deleteTemporary(_temporaryPath);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _isRecording && !_busy) {
      _setPaused(true);
    }
  }

  void _applyState(RecordState state) {
    if (!mounted) return;
    if (state == RecordState.record) {
      _stopwatch.start();
      _ticker ??= Timer.periodic(
          const Duration(milliseconds: 250), (_) => _updateElapsed());
    } else {
      _stopwatch.stop();
      _ticker?.cancel();
      _ticker = null;
      _updateElapsed();
    }
    setState(() {
      _isPaused = state == RecordState.pause;
      _recorderStopped =
          state == RecordState.stop && _started && !_finishing && !_resetting;
    });
  }

  void _updateElapsed() {
    _elapsedSeconds.value = Duration(seconds: _stopwatch.elapsed.inSeconds);
  }

  Future<void> _startRecording() async {
    if (_busy || _started) return;
    setState(() => _starting = true);
    try {
      if (!await _recorder.hasPermission()) {
        await _abortStart(permissionDenied: true);
        return;
      }

      await _beginRecording();
      _started = true;
      _applyState(RecordState.record);
    } catch (error, stackTrace) {
      _logger.severe('Starting the recording failed', error, stackTrace);
      await _deleteTemporary(_temporaryPath);
      await _abortStart(permissionDenied: false, error: error);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _beginRecording() async {
    final quality = ConfigProvider.instance.get(Settings.audioQualityLevel);
    final temporaryDirectory = await getTemporaryDirectory();
    final temporaryPath = join(temporaryDirectory.path,
        '$recordingTemporaryPrefix${DateTime.now().microsecondsSinceEpoch}.m4a');
    _temporaryPath = temporaryPath;

    await _recorder.start(
      RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: ConfigProvider.audioQualityBitRateMapping[quality] ?? 64000,
        sampleRate: ConfigProvider.audioSampleRate,
        numChannels: ConfigProvider.audioQualityChannelsMapping[quality] ?? 1,
      ),
      path: temporaryPath,
    );
  }

  Future<void> _abortStart(
      {required bool permissionDenied, Object? error}) async {
    if (!mounted) return;
    if (permissionDenied) {
      await _showPermissionDeniedDialog();
    } else {
      await showFailureDialog(context,
          description: AppLocalizations.of(context)!.recorderErrorDescription,
          error: error);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _showPermissionDeniedDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final openSettings = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.warningTitle),
        content: Text(l10n.recorderPermissionDenied),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.pageSettingsTitle),
          ),
        ],
      ),
    );
    if (openSettings == true) await openAppSettings();
  }

  Future<void> _togglePause() async {
    if (!_started) return _startRecording();
    if (_recorderStopped || _busy) return;
    await _setPaused(!_isPaused);
  }

  Future<void> _setPaused(bool paused) async {
    try {
      if (paused) {
        await _recorder.pause();
      } else {
        await _recorder.resume();
      }
      _applyState(paused ? RecordState.pause : RecordState.record);
    } catch (error, stackTrace) {
      _logger.warning(
          'Changing the recorder pause state failed', error, stackTrace);
    }
  }

  Future<void> _deleteTemporary(String? path) async {
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (error) {
      _logger.warning('Could not delete the temporary recording', error);
    }
  }

  Future<void> _requestDiscard() async {
    if (_busy || _confirmingDiscard) return;
    if (await _confirmDiscard() && mounted) await _finish(save: false);
  }

  Future<void> _reset() async {
    if (!_canReset || _confirmingDiscard) return;
    if (!await _confirmDiscard() || !mounted || !_canReset) return;

    setState(() => _resetting = true);
    try {
      await _recorder.stop();
      await _deleteTemporary(_temporaryPath);
      if (!mounted) return;
      _stopwatch
        ..stop()
        ..reset();
      _updateElapsed();
      _temporaryPath = null;
      setState(() {
        _started = false;
        _isPaused = false;
        _recorderStopped = false;
      });
    } catch (error, stackTrace) {
      _logger.severe('Discarding the recording failed', error, stackTrace);
      await _deleteTemporary(_temporaryPath);
      await _abortStart(permissionDenied: false, error: error);
    } finally {
      if (mounted) setState(() => _resetting = false);
    }
  }

  Future<bool> _confirmDiscard() async {
    if (_stopwatch.elapsed < _confirmDiscardAfter) return true;

    _confirmingDiscard = true;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.recorderDiscardTitle),
        content: Text(l10n.recorderDiscardDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.recorderDiscardAction),
          ),
        ],
      ),
    );
    _confirmingDiscard = false;
    return confirmed == true;
  }

  Future<void> _finish({required bool save}) async {
    if (_busy) return;
    if (!_started) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _finishing = true);

    _stopwatch.stop();
    _ticker?.cancel();
    _ticker = null;
    final keep = save && _stopwatch.elapsed >= _minimumSaveDuration;
    final l10n = AppLocalizations.of(context)!;

    NewAttachment? result;
    var failed = false;
    Object? failure;
    try {
      final recordedPath = await _recorder.stop() ?? _temporaryPath;
      if (keep && recordedPath != null) {
        final fileName = await AttachmentStorage.instance
            .createFromFile(null, File(recordedPath), AttachmentType.audio);
        if (fileName != null) {
          result =
              NewAttachment(type: AttachmentType.audio, filePath: fileName);
        }
      }
      failed = keep && result == null;
    } catch (error, stackTrace) {
      _logger.severe('Finishing the recording failed', error, stackTrace);
      failed = true;
      failure = error;
    } finally {
      await _deleteTemporary(_temporaryPath);
    }

    if (!mounted) {
      if (result != null) {
        await AttachmentStorage.instance.delete(result.filePath, result.type);
      }
      return;
    }
    if (failed) {
      await showFailureDialog(context,
          description: l10n.recorderErrorDescription, error: failure);
      if (!mounted) return;
    }
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _requestDiscard();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: _busy ? null : _requestDiscard,
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: SafeArea(
                        top: false,
                        bottom: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ExcludeSemantics(
                              child: SizedBox(
                                height: _waveformHeight,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    AudioWaveformDecoration(
                                      seed: _waveformSeed,
                                      active: _isRecording,
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: _waveformOpacity),
                                      sideInset:
                                          AudioWaveformDecoration.pageSideInset,
                                    ),
                                    Icon(
                                      Icons.mic_rounded,
                                      size: 96,
                                      color: _isRecording
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.secondary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ValueListenableBuilder<Duration>(
                              valueListenable: _elapsedSeconds,
                              builder: (context, elapsed, _) => Text(
                                formatDuration(elapsed),
                                style: theme.textTheme.headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: _buildControls(theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(ThemeData theme) {
    final colors = theme.colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 24,
      children: [
        ExpressiveIconButton(
          icon: Icons.delete_rounded,
          size: _secondaryButtonSize,
          backgroundColor: colors.secondaryContainer,
          foregroundColor: colors.onSecondaryContainer,
          onPressed: _canReset ? _reset : null,
        ),
        ExpressiveIconButton(
          icon: !_started
              ? Icons.mic_rounded
              : _isPaused
                  ? Icons.play_arrow_rounded
                  : Icons.pause_rounded,
          squared: _isRecording,
          onPressed: _busy || _recorderStopped ? null : _togglePause,
        ),
        ExpressiveIconButton(
          icon: Icons.check_rounded,
          size: _secondaryButtonSize,
          backgroundColor: colors.tertiary,
          foregroundColor: colors.onTertiary,
          onPressed: _busy || !_started ? null : () => _finish(save: true),
        ),
      ],
    );
  }
}
