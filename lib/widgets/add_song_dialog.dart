// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/models/song.dart';
import 'package:daily_you/utils/audio_import_helper.dart';
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
          _titleController.text = result.title;
          _artistController.text = result.artist;
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
    return AlertDialog(
      title: const Text('Add Song'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            if (_resolved != null && !_isLoading) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _artistController,
                decoration: const InputDecoration(labelText: 'Artist'),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _resolved == null || _isLoading
              ? null
              : () {
                  final song = EntrySong(
                    entryId: -1, // Assigned by caller
                    videoId: _resolved!.videoId,
                    url: _resolved!.url,
                    title: _titleController.text.trim().isNotEmpty
                        ? _titleController.text.trim()
                        : _resolved!.title,
                    artist: _artistController.text.trim().isNotEmpty
                        ? _artistController.text.trim()
                        : _resolved!.artist,
                    coverPath: _resolved!.coverPath,
                    previewUrl: _resolved!.previewUrl,
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
