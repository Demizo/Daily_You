// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/models/song.dart';
import 'package:material_ui/material_ui.dart';

class SongTrimDialog extends StatefulWidget {
  final EntrySong song;

  const SongTrimDialog({super.key, required this.song});

  static Future<EntrySong?> show(BuildContext context, EntrySong song) {
    return showDialog<EntrySong>(
      context: context,
      builder: (_) => SongTrimDialog(song: song),
    );
  }

  @override
  State<SongTrimDialog> createState() => _SongTrimDialogState();
}

class _SongTrimDialogState extends State<SongTrimDialog> {
  late double _startSeconds;
  late double _endSeconds;

  @override
  void initState() {
    super.initState();
    _startSeconds = (widget.song.previewStartMs / 1000).toDouble();
    _endSeconds = ((widget.song.previewEndMs ?? 30000) / 1000).toDouble();
    if (_endSeconds <= _startSeconds) {
      _endSeconds = _startSeconds + 30;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Trim Preview Clip'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.song.title,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(
              'Range: ${_startSeconds.toStringAsFixed(1)}s - ${_endSeconds.toStringAsFixed(1)}s'),
          const SizedBox(height: 8),
          RangeSlider(
            values: RangeValues(_startSeconds, _endSeconds),
            min: 0,
            max: 180,
            divisions: 180,
            labels: RangeLabels(
              '${_startSeconds.round()}s',
              '${_endSeconds.round()}s',
            ),
            onChanged: (values) {
              setState(() {
                _startSeconds = values.start;
                _endSeconds = values.end;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final updated = widget.song.copy(
              previewStartMs: (_startSeconds * 1000).toInt(),
              previewEndMs: (_endSeconds * 1000).toInt(),
            );
            Navigator.of(context).pop(updated);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
