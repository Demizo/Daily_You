import 'dart:io';

import 'package:daily_you/database/image_storage.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/utils/file_layer.dart';
import 'package:daily_you/layouts/fast_page_view_scroll_physics.dart';
import 'package:daily_you/models/image.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  late ExtendedPageController _pageController;
  late ValueNotifier<int> _currentPageNotifier;

  @override
  void initState() {
    super.initState();
    _pageController = ExtendedPageController(initialPage: widget.index);
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
          actions: [
            infoButton(context),
            shareButton(context),
            downloadButton(context)
          ],
        ),
        body: ExtendedImageGesturePageView.builder(
          controller: _pageController,
          physics: FastPageViewScrollPhysics(),
          itemCount: widget.images.length,
          onPageChanged: (int newIndex) {
            _currentPageNotifier.value = newIndex;
          },
          itemBuilder: (context, currentIndex) {
            return FutureBuilder(
                future: ImageStorage.instance
                    .getBytes(widget.images[currentIndex].imgPath),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: SizedBox());
                  } else if (snapshot.hasError) {
                    return Text('${snapshot.error}');
                  } else if (snapshot.hasData) {
                    return ExtendedImage.memory(
                      snapshot.data!,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      mode: ExtendedImageMode.gesture,
                      initGestureConfigHandler: (state) {
                        return GestureConfig(
                            minScale: 0.5,
                            maxScale: 10,
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

  Widget infoButton(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _currentPageNotifier,
      builder: (context, currentIndex, child) {
        return IconButton(
          icon: const Icon(Icons.info_outline_rounded),
          onPressed: () async {
            final imageEntry = widget.images[currentIndex];
            final bytes =
                await ImageStorage.instance.getBytes(imageEntry.imgPath);

            if (bytes == null || !context.mounted) return;

            // Get Dimensions
            final decodedImage = await decodeImageFromList(bytes);

            // Get File Size in KB/MB
            final double sizeInMb = bytes.length / (1024 * 1024);
            final String sizeString = sizeInMb < 1
                ? "${(bytes.length / 1024).toStringAsFixed(2)} KB"
                : "${sizeInMb.toStringAsFixed(2)} MB";

            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow(Icons.label_rounded, imageEntry.imgPath),
                    const SizedBox(height: 8),
                    _infoRow(Icons.storage_rounded, sizeString),
                    const SizedBox(height: 8),
                    _infoRow(Icons.image_aspect_ratio_rounded,
                        "${decodedImage.width} x ${decodedImage.height}"),
                    const SizedBox(height: 8),
                    _infoRow(
                      Icons.schedule_rounded,
                      "${DateFormat.yMMMEd(TimeManager.currentLocale(context)).format(imageEntry.timeCreate)} ${DateFormat.jm(TimeManager.currentLocale(context)).format(imageEntry.timeCreate)}",
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                        MaterialLocalizations.of(context).closeButtonLabel),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).disabledColor),
        const SizedBox(width: 8),
        Text(value),
      ],
    );
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
                var bytes = await ImageStorage.instance.getBytes(currentImage);
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
                      await ImageStorage.instance.getBytes(currentImage);
                  if (bytes != null) {
                    String? saveDir;
                    try {
                      saveDir = await FileLayer.pickDirectory();
                    } catch (_) {
                      return;
                    }
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
