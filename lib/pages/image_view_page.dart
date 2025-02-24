import 'dart:io';
import 'dart:typed_data';

import 'package:daily_you/entries_database.dart';
import 'package:daily_you/file_layer.dart';
import 'package:flutter/material.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';

class ImageViewPage extends StatefulWidget {
  final String imgName;

  const ImageViewPage({
    super.key,
    required this.imgName,
  });

  @override
  State<ImageViewPage> createState() => _ImageViewPageState();
}

class _ImageViewPageState extends State<ImageViewPage> {
  late String imgName;
  late bool isLoading = true;
  Uint8List? imgBytes;
  @override
  void initState() {
    super.initState();
    imgName = widget.imgName;
    imgBytes = null;
    isLoading = true;
    fetchImagePath();
  }

  void fetchImagePath() async {
    imgBytes = await EntriesDatabase.instance.getImgBytes(imgName);
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          actions:
              isLoading ? [] : [shareButton(context), downloadButton(context)],
        ),
        body: isLoading
            ? const SizedBox()
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: PhotoView(
                    minScale: 0.1,
                    maxScale: 50.0,
                    backgroundDecoration:
                        const BoxDecoration(color: Colors.transparent),
                    imageProvider: MemoryImage(imgBytes!),
                  ),
                ),
              ));
  }

  Widget shareButton(BuildContext context) {
    if (Platform.isAndroid) {
      return IconButton(
          icon: const Icon(Icons.share_rounded),
          onPressed: () async {
            if (imgBytes != null) {
              await Share.shareXFiles(
                  [XFile.fromData(imgBytes!, mimeType: "images/*")],
                  fileNameOverrides: [imgName]);
            }
          });
    }

    return Container();
  }

  Widget downloadButton(BuildContext context) {
    if (Platform.isAndroid) {
      return IconButton(
          icon: const Icon(Icons.download_rounded),
          onPressed: () async {
            if (imgBytes != null) {
              String? saveDir = await FileLayer.pickDirectory();
              if (saveDir == null) return;
              var newImageName =
                  await FileLayer.createFile(saveDir, imgName, imgBytes!);
              if (newImageName != null) {
                if (Platform.isAndroid) {
                  // Add image to media store
                  MediaScanner.loadMedia(path: newImageName);
                }
              }
            }
          });
    }

    return Container();
  }
}
