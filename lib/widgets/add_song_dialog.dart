// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:daily_you/config_provider.dart';
import 'package:daily_you/database/song_storage.dart';
import 'package:daily_you/models/song.dart';
import 'package:daily_you/utils/audio_import_helper.dart';
import 'package:daily_you/utils/network_gate.dart';
import 'package:daily_you/utils/song_service.dart';
import 'package:daily_you/utils/youtube_url_parser.dart';
import 'package:material_ui/material_ui.dart';

class AddSongDialog extends StatefulWidget {
  final String? initialLink;
  final EntrySong? initialSong;

  const AddSongDialog({
    super.key,
    this.initialLink,
    this.initialSong,
  });

  static Future<EntrySong?> show(
    BuildContext context, {
    String? initialLink,
    EntrySong? initialSong,
  }) {
    return showDialog<EntrySong>(
      context: context,
      builder: (context) => AddSongDialog(
        initialLink: initialLink,
        initialSong: initialSong,
      ),
    );
  }

  @override
  State<AddSongDialog> createState() => _AddSongDialogState();
}

class _AddSongDialogState extends State<AddSongDialog> {
  late final TextEditingController _urlController;
  late final TextEditingController _titleController;
  late final TextEditingController _artistController;
  late final TextEditingController _albumController;

  bool _isLoading = false;
  String? _errorMessage;
  SongFetchResult? _resolved;
  String? _coverPath;
  String? _previewUrl;

  AudioPlayer? _player;
  bool _isPlaying = false;
  StreamSubscription? _playerSub;
  Uint8List? _coverBytes;

  @override
  void initState() {
    super.initState();
    final song = widget.initialSong;
    _urlController = TextEditingController(text: song?.url ?? widget.initialLink ?? '');
    _titleController = TextEditingController(text: song?.title ?? '');
    _artistController = TextEditingController(text: song?.artist ?? '');
    _albumController = TextEditingController(text: song?.album ?? '');
    _coverPath = song?.coverPath;
    _previewUrl = song?.previewUrl;

    _titleController.addListener(() => setState(() {}));
    _artistController.addListener(() => setState(() {}));
    _albumController.addListener(() => setState(() {}));

    if (_coverPath != null) {
      _loadCoverBytes(_coverPath!);
    }

    if (song == null && widget.initialLink != null && widget.initialLink!.isNotEmpty) {
      _resolveLink(widget.initialLink!);
    }
  }

  @override
  void dispose() {
    _playerSub?.cancel();
    _player?.dispose();
    _urlController.dispose();
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    super.dispose();
  }

  Future<void> _loadCoverBytes(String path) async {
    final bytes = await SongStorage.instance.getBytes(path);
    if (mounted) {
      setState(() => _coverBytes = bytes);
    }
  }

  Future<void> _togglePreview() async {
    final url = _previewUrl ?? _resolved?.previewUrl;
    if (url == null || url.isEmpty) return;

    final isLocal = url.startsWith('audio_') || (_urlController.text.startsWith('file://'));
    if (!isLocal && !NetworkGate.isNetworkAllowed) {
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
      if (isLocal) {
        final localBytes = await SongStorage.instance.getBytes(url);
        if (localBytes != null) {
          await _player!.play(BytesSource(localBytes));
        }
      } else {
        await _player!.play(UrlSource(url));
      }
    }
  }

  Future<void> _resolveLink(String input) async {
    final cleanInput = input.trim();
    if (cleanInput.isEmpty) return;

    final videoId = YouTubeUrlParser.extractVideoId(cleanInput);
    if (videoId == null && !cleanInput.contains('http')) {
      setState(() {
        _errorMessage = 'Invalid YouTube or YouTube Music link';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await SongService.instance.resolveSong(cleanInput);
      if (mounted) {
        setState(() {
          _resolved = result;
          if (result.title.isNotEmpty) _titleController.text = result.title;
          if (result.artist.isNotEmpty) _artistController.text = result.artist;
          if (result.album != null) _albumController.text = result.album!;
          _coverPath = result.coverPath ?? _coverPath;
          _previewUrl = result.previewUrl ?? _previewUrl;
          _isLoading = false;
        });
        if (_coverPath != null) {
          _loadCoverBytes(_coverPath!);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _enableNetworkAndRetry() async {
    await ConfigProvider.instance.set(Settings.allowNetworkAccess, true);
    setState(() {});
    if (_urlController.text.trim().isNotEmpty) {
      _resolveLink(_urlController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasNetwork = NetworkGate.isNetworkAllowed;
    final isEditing = widget.initialSong != null;

    final currentTitle = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : (_resolved?.title.isNotEmpty == true ? _resolved!.title : 'Song Title');
    final currentArtist = _artistController.text.trim().isNotEmpty
        ? _artistController.text.trim()
        : (_resolved?.artist.isNotEmpty == true ? _resolved!.artist : 'Artist');
    final currentAlbum = _albumController.text.trim().isNotEmpty
        ? _albumController.text.trim()
        : _resolved?.album;

    final hasPreviewAudio = (_previewUrl != null && _previewUrl!.isNotEmpty) ||
        (_resolved?.previewUrl != null && _resolved!.previewUrl!.isNotEmpty);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.music_note_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(isEditing ? 'Edit Song' : 'Add Song'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Network disabled banner
            if (!hasNetwork)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withAlpha(120),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.error.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off_rounded,
                        size: 20, color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Online search is disabled in settings.',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _enableNetworkAndRetry,
                      child: const Text('Enable', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

            // Live Preview Card
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: _coverBytes != null
                            ? Image.memory(_coverBytes!, fit: BoxFit.cover)
                            : Container(
                                color: theme.colorScheme.primaryContainer,
                                child: Icon(
                                  Icons.music_note_rounded,
                                  color: theme.colorScheme.onPrimaryContainer,
                                  size: 28,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentAlbum != null && currentAlbum.isNotEmpty
                                ? '$currentArtist • $currentAlbum'
                                : currentArtist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasPreviewAudio)
                      IconButton.filledTonal(
                        icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                        tooltip: _isPlaying ? 'Pause preview' : 'Play 30s preview',
                        onPressed: _togglePreview,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // URL input with action buttons
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'YouTube Music / Audio Link',
                hintText: 'https://music.youtube.com/watch?v=...',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.link_rounded),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_urlController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        tooltip: 'Clear link',
                        onPressed: () {
                          _urlController.clear();
                          setState(() {});
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded),
                      tooltip: 'Fetch song metadata',
                      onPressed: _isLoading
                          ? null
                          : () => _resolveLink(_urlController.text.trim()),
                    ),
                  ],
                ),
              ),
              onSubmitted: (val) => _resolveLink(val.trim()),
            ),
            const SizedBox(height: 8),

            // Local audio option
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.audio_file_rounded, size: 18),
                label: const Text('Import Local Audio File'),
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final song = await AudioImportHelper.pickAndImportLocalAudio();
                  if (song != null && mounted) {
                    navigator.pop(song);
                  }
                },
              ),
            ),

            // Loading indicator
            if (_isLoading) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Fetching song metadata & artwork…',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Error banner with retry
            if (_errorMessage != null && !_isLoading) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 20, color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _resolveLink(_urlController.text.trim()),
                      child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // Editable title, artist, album
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Track Title',
                prefixIcon: Icon(Icons.title_rounded),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _artistController,
              decoration: const InputDecoration(
                labelText: 'Artist',
                hintText: 'Artist Name',
                prefixIcon: Icon(Icons.person_rounded),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _albumController,
              decoration: const InputDecoration(
                labelText: 'Album (optional)',
                hintText: 'Album Name',
                prefixIcon: Icon(Icons.album_rounded),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading
              ? null
              : () {
                  final rawUrl = _urlController.text.trim();
                  final videoId = YouTubeUrlParser.extractVideoId(rawUrl) ??
                      widget.initialSong?.videoId ??
                      _resolved?.videoId ??
                      'custom';
                  final normalizedUrl = YouTubeUrlParser.extractVideoId(rawUrl) != null
                      ? YouTubeUrlParser.normalizeUrl(videoId)
                      : (rawUrl.isNotEmpty ? rawUrl : (widget.initialSong?.url ?? ''));

                  final title = _titleController.text.trim();
                  final artist = _artistController.text.trim();
                  final album = _albumController.text.trim().isNotEmpty
                      ? _albumController.text.trim()
                      : (_resolved?.album ?? widget.initialSong?.album);

                  if (title.isEmpty && rawUrl.isEmpty) {
                    return;
                  }

                  final song = EntrySong(
                    id: widget.initialSong?.id,
                    entryId: widget.initialSong?.entryId ?? -1,
                    videoId: videoId,
                    url: normalizedUrl,
                    title: title.isNotEmpty ? title : 'Untitled Track',
                    artist: artist.isNotEmpty ? artist : '',
                    album: album,
                    coverPath: _coverPath ?? _resolved?.coverPath ?? widget.initialSong?.coverPath,
                    previewUrl: _previewUrl ?? _resolved?.previewUrl ?? widget.initialSong?.previewUrl,
                    previewStartMs: widget.initialSong?.previewStartMs ?? 0,
                    previewEndMs: widget.initialSong?.previewEndMs,
                    timeCreate: widget.initialSong?.timeCreate ?? DateTime.now(),
                  );
                  Navigator.of(context).pop(song);
                },
          child: Text(isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
