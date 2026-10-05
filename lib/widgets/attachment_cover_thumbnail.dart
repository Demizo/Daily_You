// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:typed_data';

import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/widgets/local_image_cache.dart';
import 'package:daily_you/widgets/local_image_loader.dart';
import 'package:daily_you/widgets/video_thumbnail_cache.dart';
import 'package:material_ui/material_ui.dart';

class AttachmentCoverThumbnail extends StatefulWidget {
  const AttachmentCoverThumbnail({super.key, required this.candidates});

  final List<EntryAttachment> candidates;

  @override
  State<AttachmentCoverThumbnail> createState() =>
      _AttachmentCoverThumbnailState();
}

class _AttachmentCoverThumbnailState extends State<AttachmentCoverThumbnail> {
  Future<Uint8List?>? _thumbnail;

  EntryAttachment? get _first => widget.candidates.firstOrNull;

  @override
  void initState() {
    super.initState();
    _thumbnail = _loadThumbnail();
  }

  @override
  void didUpdateWidget(AttachmentCoverThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget.candidates.firstOrNull;
    final current = _first;
    if (old?.filePath != current?.filePath || old?.type != current?.type) {
      _thumbnail = _loadThumbnail();
    }
  }

  Future<Uint8List?>? _loadThumbnail() {
    final first = _first;
    if (first?.type != AttachmentType.video) return null;
    return VideoThumbnailCache.instance.getThumbnail(first!.filePath);
  }

  @override
  Widget build(BuildContext context) {
    final first = _first;
    if (first == null) return const SizedBox.shrink();

    if (first.type == AttachmentType.image) {
      return LocalImageLoader(
          imagePath: first.filePath, cacheSize: LocalImageCache.thumbnailWidth);
    }

    final fallback = AttachmentCoverThumbnail(
        candidates: widget.candidates.skip(1).toList());
    if (_thumbnail == null) return fallback;

    return FutureBuilder<Uint8List?>(
      future: _thumbnail,
      initialData: VideoThumbnailCache.instance.peek(first.filePath),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes != null) return Image.memory(bytes, fit: BoxFit.cover);
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        return fallback;
      },
    );
  }
}
