import 'dart:io';

import 'package:daily_you/entries_database.dart';
import 'package:daily_you/file_layer.dart';
import 'package:daily_you/models/image.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:share_plus/share_plus.dart';

class ImageViewPage extends StatefulWidget {
  final List<EntryImage> images;
  final int index;

  const ImageViewPage({
    super.key,
    required this.images,
    required this.index,
  });

  @override
  State<ImageViewPage> createState() => _ImageViewPageState();
}

class _ImageViewPageState extends State<ImageViewPage> {
  late PageController _pageController;
  late ValueNotifier<int> _currentPageNotifier;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.index);
    _currentPageNotifier = ValueNotifier<int>(widget.index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _currentPageNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          actions: [shareButton(context), downloadButton(context)],
        ),
        body: PageView.builder(
          controller: _pageController,
          hitTestBehavior: HitTestBehavior.deferToChild,
          itemCount: widget.images.length,
          onPageChanged: (int newIndex) {
            _currentPageNotifier.value = newIndex;
          },
          itemBuilder: (context, currentIndex) {
            return FutureBuilder(
                future: EntriesDatabase.instance
                    .getImgBytes(widget.images[currentIndex].imgPath),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: SizedBox());
                  } else if (snapshot.hasError) {
                    return Text('${snapshot.error}');
                  } else if (snapshot.hasData) {
                    return ExtendedImage.memory(
                      snapshot.data!,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                      mode: ExtendedImageMode.gesture,
                      initGestureConfigHandler: (state) {
                        return GestureConfig(
                            minScale: 0.5,
                            maxScale: 4,
                            initialScale: 1,
                            inPageView: true);
                      },
                      onDoubleTap: (state) {
                        final double newScale =
                            state.gestureDetails!.totalScale == 1.0 ? 2.0 : 1.0;
                        state.handleDoubleTap(scale: newScale);
                      },
                    );
                  } else {
                    // Image not found
                    return const Center(
                      child: Icon(
                        Icons.image_search_rounded,
                        size: 36,
                      ),
                    );
                  }
                });
          },
        ));
  }

  Widget shareButton(BuildContext context) {
    if (Platform.isAndroid) {
      return ValueListenableBuilder(
        valueListenable: _currentPageNotifier,
        builder: (context, currentIndex, child) {
          return IconButton(
              icon: const Icon(Icons.share_rounded),
              onPressed: () async {
                final currentImage = widget.images[currentIndex].imgPath;
                var bytes =
                    await EntriesDatabase.instance.getImgBytes(currentImage);
                if (bytes != null) {
                  await Share.shareXFiles(
                      [XFile.fromData(bytes, mimeType: "images/*")],
                      fileNameOverrides: [currentImage]);
                }
              });
        },
      );
    }

    return Container();
  }

  Widget downloadButton(BuildContext context) {
    if (Platform.isAndroid) {
      return ValueListenableBuilder(
          valueListenable: _currentPageNotifier,
          builder: (context, currentIndex, child) {
            return IconButton(
                icon: const Icon(Icons.download_rounded),
                onPressed: () async {
                  final currentImage = widget.images[currentIndex].imgPath;
                  var bytes =
                      await EntriesDatabase.instance.getImgBytes(currentImage);
                  if (bytes != null) {
                    String? saveDir = await FileLayer.pickDirectory();
                    if (saveDir == null) return;
                    var newImageName = await FileLayer.createFile(
                        saveDir, currentImage, bytes);
                    if (newImageName != null) {
                      if (Platform.isAndroid) {
                        // Add image to media store
                        MediaScanner.loadMedia(path: newImageName);
                      }
                    }
                  }
                });
          });
    }

    return Container();
  }
}
