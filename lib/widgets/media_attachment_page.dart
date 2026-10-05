// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:daily_you/database/attachment_storage.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/widgets/audio_waveform_decoration.dart';
import 'package:daily_you/widgets/media_error_view.dart';
import 'package:daily_you/widgets/media_playback_controls.dart';
import 'package:daily_you/widgets/playback_tap_area.dart';
import 'package:daily_you/widgets/video_thumbnail_cache.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

class MediaAttachmentPage extends StatefulWidget {
  const MediaAttachmentPage({
    super.key,
    required this.filePath,
    required this.type,
    required this.pauseRequests,
  }) : assert(type != AttachmentType.image);

  final String filePath;
  final AttachmentType type;
  final Listenable pauseRequests;

  @override
  State<MediaAttachmentPage> createState() => _MediaAttachmentPageState();
}

class _MediaAttachmentPageState extends State<MediaAttachmentPage>
    with WidgetsBindingObserver {
  final Logger _logger = Logger('MediaAttachmentPage');
  final List<StreamSubscription<void>> _subscriptions = [];
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _playing = false;
  bool _failed = false;
  bool _ended = false;
  bool _seeking = false;
  Uint8List? _thumbnail;
  bool _frameShown = false;
  String? _localPath;
  Future<void>? _restarting;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.pauseRequests.addListener(_pause);
    if (widget.type == AttachmentType.video) _loadThumbnail();
    _openMedia();
  }

  Future<void> _loadThumbnail() async {
    final cache = VideoThumbnailCache.instance;
    _thumbnail = cache.peek(widget.filePath);
    if (_thumbnail != null) return;
    final thumbnail = await cache.getThumbnail(widget.filePath);
    if (mounted && !_frameShown) setState(() => _thumbnail = thumbnail);
  }

  void _fail() {
    if (mounted && !_failed) setState(() => _failed = true);
  }

  Future<void> _openMedia() async {
    try {
      final localPath = await AttachmentStorage.instance
          .getLocalPath(widget.filePath, widget.type);
      if (!mounted) return;
      if (localPath == null) {
        _fail();
        return;
      }
      _localPath = localPath;
      if (widget.type == AttachmentType.video) {
        await _openVideo(localPath);
      } else {
        await _openAudio(localPath);
      }
    } catch (error, stackTrace) {
      _logger.warning('Opening ${widget.type.name} failed', error, stackTrace);
      _fail();
    }
  }

  Future<void> _openVideo(String localPath) async {
    final controller = _videoController = VideoPlayerController.file(
      File(localPath),
    );
    controller.addListener(_onVideoValueChanged);
    await controller.initialize().timeout(const Duration(seconds: 10));
  }

  Future<void> _reopenVideo() async {
    final previous = _videoController!;
    final next = VideoPlayerController.file(File(_localPath!));
    try {
      await next.initialize().timeout(const Duration(seconds: 10));
    } catch (_) {
      unawaited(next.dispose());
      rethrow;
    }
    if (!mounted) {
      await next.dispose();
      return;
    }
    previous.removeListener(_onVideoValueChanged);
    next.addListener(_onVideoValueChanged);
    setState(() {
      _videoController = next;
      _position = Duration.zero;
      _playing = false;
    });
    unawaited(previous.dispose());
  }

  void _onVideoValueChanged() {
    final value = _videoController!.value;
    if (value.hasError) {
      _logger.warning('Video playback error: ${value.errorDescription}');
      _fail();
      return;
    }
    if (value.isCompleted) _ended = true;
    if (value.isPlaying || value.position > Duration.zero) _frameShown = true;
    final seekingWhilePlaying =
        _playing && !value.isCompleted && (_seeking || value.isBuffering);
    setState(() {
      _position = value.position;
      _duration = value.duration;
      _playing = value.isPlaying || seekingWhilePlaying;
    });
  }

  Future<void> _openAudio(String localPath) async {
    final player = _audioPlayer = AudioPlayer();
    _subscriptions.addAll([
      player.positionStream.listen(_onAudioPosition),
      player.durationStream.listen(
          (duration) => setState(() => _duration = duration ?? Duration.zero)),
      player.playerStateStream.listen(_onAudioStateChanged),
      player.playbackEventStream.listen(null, onError: _onAudioError),
      player.errorStream.listen(_onAudioError),
    ]);
    await player.setFilePath(localPath);
  }

  void _onAudioPosition(Duration position) {
    if (_playing && position < _position) return;
    setState(() => _position = position);
  }

  void _onAudioError(Object error) {
    _logger.warning('Audio playback error: $error');
    _fail();
  }

  Future<void> _onAudioStateChanged(PlayerState state) async {
    setState(() => _playing = state.playing);
    if (!state.playing || state.processingState != ProcessingState.completed) {
      return;
    }
    _ended = true;
    await _audioPlayer!.pause();
  }

  Future<void> _restartIfEnded() async {
    if (_ended) {
      _ended = false;
      _restarting = _restart();
    }
    await _restarting;
  }

  Future<void> _restart() async {
    try {
      if (widget.type == AttachmentType.video) {
        await _reopenVideo();
      } else {
        setState(() => _position = Duration.zero);
        await _audioPlayer!.setFilePath(_localPath!);
      }
    } catch (error, stackTrace) {
      _logger.warning(
          'Restarting ${widget.type.name} failed', error, stackTrace);
      _fail();
    }
  }

  Future<void> _play() async {
    await _restartIfEnded();
    _videoController?.play();
    _audioPlayer?.play();
  }

  void _pause() {
    _seeking = false;
    if (_playing && mounted) setState(() => _playing = false);
    _videoController?.pause();
    _audioPlayer?.pause();
  }

  Future<void> _seek(Duration position) async {
    await _restartIfEnded();
    if (!mounted) return;
    setState(() => _position = position);
    final video = _videoController;
    if (video != null) unawaited(_seekVideo(video, position));
    _audioPlayer?.seek(position);
  }

  Future<void> _seekVideo(
      VideoPlayerController video, Duration position) async {
    _seeking = true;
    try {
      await video.seekTo(position);
      await Future<void>.delayed(const Duration(milliseconds: 300));
    } finally {
      _seeking = false;
      if (mounted && _videoController == video) _onVideoValueChanged();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.pauseRequests.removeListener(_pause);
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _videoController?.removeListener(_onVideoValueChanged);
    _videoController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const MediaErrorView();
    return Column(
      children: [
        Expanded(
          child: PlaybackTapArea(
            playing: _playing,
            onPlay: _play,
            onPause: _pause,
            child: _buildBody(),
          ),
        ),
        MediaPlaybackControls(
          position: _position,
          duration: _duration,
          playing: _playing,
          onPlay: _play,
          onPause: _pause,
          onSeek: _seek,
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (widget.type == AttachmentType.audio) {
      return Center(
        child: SafeArea(
          top: false,
          bottom: false,
          child: SizedBox(
            height: 240,
            child: AudioWaveformDecoration(
              seed: widget.filePath.hashCode,
              active: _playing,
              sideInset: AudioWaveformDecoration.pageSideInset,
            ),
          ),
        ),
      );
    }
    final controller = _videoController;
    final initialized = controller != null && controller.value.isInitialized;
    final thumbnail = _frameShown ? null : _thumbnail;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (initialized)
          Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),
        if (thumbnail != null)
          Image.memory(thumbnail, fit: BoxFit.contain, gaplessPlayback: true),
      ],
    );
  }
}
