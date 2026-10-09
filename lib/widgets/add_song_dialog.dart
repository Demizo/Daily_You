import 'package:daily_you/models/song.dart';
import 'package:daily_you/utils/audio_import_helper.dart';
import 'package:daily_you/utils/network_gate.dart';
import 'package:daily_you/utils/song_service.dart';
import 'package:daily_you/utils/youtube_url_parser.dart';
import 'package:material_ui/material_ui.dart';

class AddSongDialog extends StatefulWidget {
  final String? initialLink;

  const AddSongDialog({super.key, this.initialLink});

  static Future<EntrySong?> show(BuildContext context,
      {String? initialLink}) {
    return showDialog<EntrySong>(
      context: context,
      builder: (context) => AddSongDialog(initialLink: initialLink),
    );
  }

  @override
  State<AddSongDialog> createState() => _AddSongDialogState();
}

class _AddSongDialogState extends State<AddSongDialog> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _artistController = TextEditingController();
  final TextEditingController _albumController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  SongFetchResult? _resolved;

  @override
  void initState() {
    super.initState();
    if (widget.initialLink != null && widget.initialLink!.isNotEmpty) {
      _urlController.text = widget.initialLink!;
      _resolveLink(widget.initialLink!);
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    super.dispose();
  }

  Future<void> _resolveLink(String input) async {
    final videoId = YouTubeUrlParser.extractVideoId(input);
    if (videoId == null) {
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
      final result = await SongService.instance.resolveSong(input);
      if (mounted) {
        setState(() {
          _resolved = result;
          if (result.title.isNotEmpty) _titleController.text = result.title;
          if (result.artist.isNotEmpty) _artistController.text = result.artist;
          if (result.album != null) _albumController.text = result.album!;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasNetwork = NetworkGate.isNetworkAllowed;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.music_note_rounded),
          SizedBox(width: 8),
          Text('Add Song'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!hasNetwork)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Offline mode. Online search disabled in settings.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'YouTube Music Link',
                hintText: 'https://music.youtube.com/watch?v=...',
                errorText: _errorMessage,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded),
                  onPressed: _isLoading
                      ? null
                      : () => _resolveLink(_urlController.text),
                ),
              ),
              onSubmitted: (val) => _resolveLink(val),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.audio_file_rounded),
              label: const Text('Import Local Audio File'),
              onPressed: () async {
                final navigator = Navigator.of(context);
                final song = await AudioImportHelper.pickAndImportLocalAudio();
                if (song != null && mounted) {
                  navigator.pop(song);
                }
              },
            ),
            if (_isLoading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Song Title',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _artistController,
              decoration: const InputDecoration(
                labelText: 'Artist',
                hintText: 'Artist Name',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _albumController,
              decoration: const InputDecoration(
                labelText: 'Album (optional)',
                hintText: 'Album Name',
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
                  final videoId =
                      YouTubeUrlParser.extractVideoId(_urlController.text.trim()) ??
                          (_resolved?.videoId ?? 'custom');
                  final normalizedUrl =
                      YouTubeUrlParser.normalizeUrl(videoId);

                  final title = _titleController.text.trim();
                  final artist = _artistController.text.trim();
                  final album = _albumController.text.trim().isNotEmpty
                      ? _albumController.text.trim()
                      : _resolved?.album;

                  if (title.isEmpty && _urlController.text.trim().isEmpty) {
                    return;
                  }

                  final song = EntrySong(
                    entryId: -1,
                    videoId: videoId,
                    url: _urlController.text.trim().isNotEmpty
                        ? normalizedUrl
                        : (_resolved?.url ?? ''),
                    title: title.isNotEmpty ? title : 'Untitled Track',
                    artist: artist.isNotEmpty ? artist : '',
                    album: album,
                    coverPath: _resolved?.coverPath,
                    previewUrl: _resolved?.previewUrl,
                    timeCreate: DateTime.now(),
                  );
                  Navigator.of(context).pop(song);
                },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
