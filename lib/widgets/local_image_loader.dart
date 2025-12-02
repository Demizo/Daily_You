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
  MemoryImage? _image;
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final img = await LocalImageCache.instance
        .getCachedImage(widget.imagePath, widget.cacheSize);
    if (mounted) {
      if (img != null) {
        setState(() => _image = img);
      } else {
        final bytes = await LocalImageCache.instance
            .getImageBytes(widget.imagePath, widget.cacheSize);
        if (mounted) {
          setState(() => _bytes = bytes);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_image == null) {
      if (_bytes != null) {
        return FractionallySizedBox(
          widthFactor: 1,
          child: Image.memory(_bytes!,
              fit: BoxFit.cover, cacheWidth: widget.cacheSize),
        );
      } else {
        return const SizedBox.expand();
      }
    }

    return FractionallySizedBox(
      widthFactor: 1,
      child: Image(image: _image!, fit: BoxFit.cover),
    );
  }
}
