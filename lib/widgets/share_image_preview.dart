import 'dart:io';
import 'dart:typed_data';

import 'package:daily_you/services/share_intent_service.dart';
import 'package:flutter/material.dart';

/// Displays a scrollable horizontal (or single-item) preview of images that
/// are being shared into the app.
///
/// [paths] may be `content://` URIs (from Android) or plain file paths.
/// `content://` URIs are read via the native MethodChannel so they render
/// correctly without needing a temporary file copy.
class ShareImagePreview extends StatelessWidget {
  final List<String> paths;

  const ShareImagePreview({super.key, required this.paths});

  @override
  Widget build(BuildContext context) {
    if (paths.isEmpty) return const SizedBox.shrink();

    final isSingle = paths.length == 1;

    return SizedBox(
      height: isSingle ? 240 : 180,
      child: isSingle
          ? _SharedImage(uri: paths.first, fit: BoxFit.contain)
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: paths.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _SharedImage(uri: paths[index], fit: BoxFit.cover),
                ),
              ),
            ),
    );
  }
}

/// Renders a single shared image from either a `content://` URI or a plain
/// file path.
///
/// For `content://` URIs the bytes are fetched asynchronously via
/// [ShareIntentService.readUriBytes] so that Android's `ContentResolver` is
/// used instead of the `File` API (which cannot open content URIs).
class _SharedImage extends StatelessWidget {
  final String uri;
  final BoxFit fit;

  const _SharedImage({required this.uri, required this.fit});

  bool get _isContentUri => uri.startsWith('content://');

  Widget _brokenIcon(BuildContext context, Object? _, StackTrace? __) =>
      Center(
        child: Icon(
          Icons.broken_image_rounded,
          size: 36,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (!_isContentUri) {
      // Plain file path — use Image.file directly (no async needed).
      return Image.file(
        File(uri),
        fit: fit,
        errorBuilder: _brokenIcon,
      );
    }

    // content:// URI — read bytes via the MethodChannel.
    return FutureBuilder<Uint8List?>(
      future: ShareIntentService.instance.readUriBytes(uri),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) {
          return _brokenIcon(context, null, null);
        }
        return Image.memory(bytes, fit: fit, errorBuilder: _brokenIcon);
      },
    );
  }
}
