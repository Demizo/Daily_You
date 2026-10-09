// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:daily_you/database/song_storage.dart';
import 'package:daily_you/models/song.dart';
import 'package:daily_you/utils/network_gate.dart';
import 'package:daily_you/utils/youtube_url_parser.dart';
import 'package:daily_you/widgets/song_trim_dialog.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class SongCardWidget extends StatefulWidget {
  final EntrySong song;
  final VoidCallback? onDelete;
  final ValueChanged<EntrySong>? onUpdate;
  final bool compact;

  const SongCardWidget({
    super.key,
    required this.song,
    this.onDelete,
    this.onUpdate,
    this.compact = false,
  });

  @override
  State<SongCardWidget> createState() => _SongCardWidgetState();
}

class _SongCardWidgetState extends State<SongCardWidget> {
  Uint8List? _coverBytes;
  AudioPlayer? _player;
  bool _isPlaying = false;
  StreamSubscription? _playerSub;

  @override
  void initState() {
    super.initState();
    _loadCover();
  }

  @override
  void dispose() {
    _playerSub?.cancel();
    _player?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SongCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.coverPath != widget.song.coverPath) {
      _loadCover();
    }
  }

  Future<void> _togglePreview() async {
    if (widget.song.previewUrl == null) return;
    if (!NetworkGate.isNetworkAllowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network access is disabled in settings')),
      );
      return;
    }

    _player ??= AudioPlayer();
    _playerSub ??= _player!.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    if (_isPlaying) {
      await _player!.pause();
    } else {
      await _player!.play(UrlSource(widget.song.previewUrl!));
    }
  }

  Future<void> _loadCover() async {
    final path = widget.song.coverPath;
    if (path == null) {
      if (mounted) setState(() => _coverBytes = null);
      return;
    }
    final bytes = await SongStorage.instance.getBytes(path);
    if (mounted) {
      setState(() => _coverBytes = bytes);
    }
  }

  Future<void> _openYouTubeMusic() async {
    final musicUri = Uri.parse(YouTubeUrlParser.musicUrl(widget.song.videoId));
    final fallbackUri = Uri.parse(widget.song.url);
    if (await canLaunchUrl(musicUri)) {
      await launchUrl(musicUri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = widget.compact ? 48.0 : 64.0;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            // Cover Artwork
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: size,
                height: size,
                child: _coverBytes != null
                    ? Image.memory(
                        _coverBytes!,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: theme.colorScheme.primaryContainer,
                        child: Icon(
                          Icons.music_note_rounded,
                          color: theme.colorScheme.onPrimaryContainer,
                          size: size * 0.5,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Song Title and Artist
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Play/Pause 30s preview
            if (widget.song.previewUrl != null && !widget.compact)
              IconButton(
                icon: Icon(_isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded),
                tooltip: _isPlaying ? 'Pause preview' : 'Play preview',
                color: theme.colorScheme.primary,
                onPressed: _togglePreview,
              ),
            if (widget.onUpdate != null && widget.song.previewUrl != null)
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                tooltip: 'Trim preview range',
                color: theme.colorScheme.primary,
                onPressed: () async {
                  final trimmed =
                      await SongTrimDialog.show(context, widget.song);
                  if (trimmed != null) {
                    widget.onUpdate!(trimmed);
                  }
                },
              ),
            // Open in YouTube Music
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded),
              tooltip: 'Open in YouTube Music',
              color: theme.colorScheme.primary,
              onPressed: _openYouTubeMusic,
            ),
            // Optional Delete Button (in editor)
            if (widget.onDelete != null)
              IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Remove song',
                color: theme.colorScheme.error,
                onPressed: widget.onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
