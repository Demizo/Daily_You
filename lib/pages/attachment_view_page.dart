// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:daily_you/database/attachment_storage.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/storage/storage_picker.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/widgets/zoomable_attachment_page_view.dart';
import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:share_plus/share_plus.dart';

class AttachmentViewPage extends StatefulWidget {
  final List<EntryAttachment> attachments;
  final int index;

  const AttachmentViewPage({
    super.key,
    required this.attachments,
    required this.index,
  });

  @override
  State<AttachmentViewPage> createState() => _AttachmentViewPageState();
}

class _AttachmentViewPageState extends State<AttachmentViewPage> {
  final Logger _logger = Logger('AttachmentViewPage');

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
          actions: [
            infoButton(context),
            shareButton(context),
            downloadButton(context)
          ],
        ),
        body: ZoomableAttachmentPageView(
          controller: _pageController,
          imageProviders: widget.attachments
              .map((attachment) => EntryImageProvider(attachment.filePath))
              .toList(),
          onPageChanged: (int newIndex) {
            _currentPageNotifier.value = newIndex;
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
            final imageEntry = widget.attachments[currentIndex];
            final bytes =
                await AttachmentStorage.instance.getBytes(imageEntry.filePath);

            if (bytes == null || !context.mounted) return;

            // Get Dimensions
            final decodedImage = await decodeImageFromList(bytes);

            // Get File Size in KB/MB
            final double sizeInMb = bytes.length / (1024 * 1024);
            final String sizeString = sizeInMb < 1
                ? "${(bytes.length / 1024).toStringAsFixed(2)} KB"
                : "${sizeInMb.toStringAsFixed(2)} MB";

            if (!context.mounted) return;
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow(Icons.label_rounded, imageEntry.filePath),
                    const SizedBox(height: 8),
                    _infoRow(Icons.storage_rounded, sizeString),
                    const SizedBox(height: 8),
                    _infoRow(Icons.image_aspect_ratio_rounded,
                        "${decodedImage.width} x ${decodedImage.height}"),
                    const SizedBox(height: 8),
                    _infoRow(
                      Icons.schedule_rounded,
                      "${DateFormat.yMMMEd(TimeManager.currentLocale(context)).format(imageEntry.timeCreate)} ${TimeManager.localizedTimeFormat(context, TimeManager.currentLocale(context)).format(imageEntry.timeCreate)}",
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
                final currentImage = widget.attachments[currentIndex].filePath;
                var bytes =
                    await AttachmentStorage.instance.getBytes(currentImage);
                if (bytes != null) {
                  await SharePlus.instance.share(ShareParams(
                      files: [XFile.fromData(bytes, mimeType: "images/*")],
                      fileNameOverrides: [currentImage]));
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
                  final currentImage =
                      widget.attachments[currentIndex].filePath;
                  var bytes =
                      await AttachmentStorage.instance.getBytes(currentImage);
                  if (bytes == null) return;

                  PickedDirectory? saveDirectory;
                  try {
                    saveDirectory = await StoragePicker.pickDirectory();
                  } catch (error, stackTrace) {
                    _logger.warning(
                        'Choosing a download folder failed', error, stackTrace);
                    return;
                  }
                  if (saveDirectory == null) return;

                  await saveDirectory.store.write(currentImage, bytes);
                });
          });
    }

    return Container();
  }
}
