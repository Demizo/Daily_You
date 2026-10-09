import 'package:daily_you/database/image_storage.dart';
import 'package:daily_you/utils/media_type_utils.dart';
import 'package:daily_you/widgets/local_image_cache.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

class LocalImageLoader extends StatefulWidget {
  final String imagePath;
  final int cacheSize;

  const LocalImageLoader({
    super.key,
    required this.imagePath,
    this.cacheSize = 500,
  });

  @override
  State<LocalImageLoader> createState() => _LocalImageLoaderState();
}

class _LocalImageLoaderState extends State<LocalImageLoader> {
  Uint8List? _bytes;
  bool _imageNotFound = false;
  int _cacheVersion = ImageStorage.instance.cacheVersion.value;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant LocalImageLoader oldWidget) {
    super.didUpdateWidget(oldWidget);

    final cacheVersion = ImageStorage.instance.cacheVersion.value;
    if (oldWidget.imagePath != widget.imagePath ||
        oldWidget.cacheSize != widget.cacheSize ||
        cacheVersion != _cacheVersion) {
      _cacheVersion = cacheVersion;
      _bytes = null;
      _imageNotFound = false;
      _load();
    }
  }

  Future<void> _load() async {
    final bytes = await LocalImageCache.instance
        .getResizedImageBytes(widget.imagePath, widget.cacheSize);
    if (mounted) {
      if (bytes != null) {
        setState(() => _bytes = bytes);
      } else {
        setState(() => _imageNotFound = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = MediaTypeUtils.isVideo(widget.imagePath);

    if (_bytes != null) {
      final imgWidget = Image.memory(
        _bytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        cacheWidth: widget.cacheSize,
        errorBuilder: (_, __, ___) {
          return const Center(
            child: Icon(
              Icons.broken_image_rounded,
              size: 36,
            ),
          );
        },
      );
      if (!isVideo) return imgWidget;
      return Stack(
        fit: StackFit.expand,
        children: [
          imgWidget,
          Center(
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(120),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 28),
            ),
          ),
        ],
      );
    } else {
      if (_imageNotFound) {
        if (isVideo) {
          return Container(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            alignment: Alignment.center,
            child: const Icon(Icons.videocam_rounded, size: 36),
          );
        }
        // Image not found
        return const Center(
          child: Icon(
            Icons.image_search_rounded,
            size: 36,
          ),
        );
      } else {
        if (isVideo) {
          return Container(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            alignment: Alignment.center,
            child: const Icon(Icons.videocam_rounded, size: 36),
          );
        }
        // Placeholder while image loads
        return const SizedBox.expand();
      }
    }
  }
}
