// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:typed_data';

import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/widgets/attachment_type_presentation.dart';
import 'package:daily_you/widgets/audio_waveform_decoration.dart';
import 'package:daily_you/widgets/local_image_loader.dart';
import 'package:daily_you/widgets/video_thumbnail_cache.dart';
import 'package:material_ui/material_ui.dart';

class AttachmentTileBackground extends StatelessWidget {
  const AttachmentTileBackground({super.key, required this.attachment});

  final EntryAttachment attachment;

  @override
  Widget build(BuildContext context) {
    return switch (attachment.type) {
      AttachmentType.image => LocalImageLoader(imagePath: attachment.filePath),
      AttachmentType.video => VideoTileBackground(
          id: attachment.filePath,
          peek: () => VideoThumbnailCache.instance.peek(attachment.filePath),
          load: () =>
              VideoThumbnailCache.instance.getThumbnail(attachment.filePath),
        ),
      AttachmentType.audio =>
        AudioTileBackground(seed: attachment.filePath.hashCode),
    };
  }
}

class VideoTileBackground extends StatefulWidget {
  const VideoTileBackground({
    super.key,
    required this.id,
    required this.peek,
    required this.load,
  });

  final String id;
  final Uint8List? Function() peek;
  final Future<Uint8List?> Function() load;

  @override
  State<VideoTileBackground> createState() => _VideoTileBackgroundState();
}

class _VideoTileBackgroundState extends State<VideoTileBackground> {
  late Future<Uint8List?> _thumbnail;

  @override
  void initState() {
    super.initState();
    _thumbnail = widget.load();
  }

  @override
  void didUpdateWidget(VideoTileBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _thumbnail = widget.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _thumbnail,
      initialData: widget.peek(),
      builder: (context, snapshot) {
        final thumbnail = snapshot.data;
        return Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: [
            if (thumbnail != null)
              Image.memory(thumbnail, fit: BoxFit.cover)
            else
              Container(
                color: Theme.of(context).colorScheme.surfaceContainer,
                child: Icon(AttachmentType.video.icon,
                    size: 36, color: Theme.of(context).disabledColor),
              ),
            if (thumbnail != null)
              Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 28),
                ),
              ),
          ],
        );
      },
    );
  }
}

class AudioTileBackground extends StatelessWidget {
  const AudioTileBackground({super.key, required this.seed});

  final int seed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      fit: StackFit.expand,
      children: [
        Container(color: Theme.of(context).colorScheme.surfaceContainer),
        AudioWaveformDecoration(seed: seed),
      ],
    );
  }
}
