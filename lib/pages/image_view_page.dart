import 'dart:io';

import 'package:daily_you/entries_database.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class ImageViewPage extends StatefulWidget {
  final String imgName;

  const ImageViewPage({
    Key? key,
    required this.imgName,
  }) : super(key: key);

  @override
  _ImageViewPageState createState() => _ImageViewPageState();
}

class _ImageViewPageState extends State<ImageViewPage> {
  late String imgName;
  late bool isLoading = true;
  @override
  void initState() {
    super.initState();
    imgName = widget.imgName;
    fetchImagePath();
  }

  void fetchImagePath() async {
    imgName = await EntriesDatabase.instance.getImgPath(imgName);
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(),
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
                    imageProvider: FileImage(File(imgName)),
                  ),
                ),
              ));
  }
}
