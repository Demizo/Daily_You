import 'package:daily_you/widgets/local_image_cache.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
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
    if (_bytes != null) {
      return FractionallySizedBox(
        widthFactor: 1,
        child: Image.memory(_bytes!,
            fit: BoxFit.cover,
            cacheWidth: widget.cacheSize, errorBuilder: (_, __, ___) {
          return const Center(
            child: Icon(
              Icons.broken_image_rounded,
              size: 36,
            ),
          );
        }),
      );
    } else {
      if (_imageNotFound) {
        // Image not found
        return const Center(
          child: Icon(
            Icons.image_search_rounded,
            size: 36,
          ),
        );
      } else {
        // Placeholder while image loads
        return const SizedBox.expand();
      }
    }
  }
}
