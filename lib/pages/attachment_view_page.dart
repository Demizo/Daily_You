// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:daily_you/database/attachment_storage.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/storage/storage_picker.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/utils/attachment_mime.dart';
import 'package:daily_you/utils/duration_format.dart';
import 'package:daily_you/utils/file_size_format.dart';
import 'package:daily_you/widgets/failure_dialog.dart';
import 'package:daily_you/widgets/media_attachment_page.dart';
import 'package:daily_you/widgets/scale_fade_page_route.dart';
import 'package:daily_you/widgets/zoomable_attachment_page_view.dart';
import 'package:external_opener/external_opener.dart';
import 'package:just_audio/just_audio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:logging/logging.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

class AttachmentViewPage extends StatefulWidget {
  final List<EntryAttachment> attachments;
  final int index;

  const AttachmentViewPage({
    super.key,
    required this.attachments,
    required this.index,
  });

  static Route<void> route(
          {required List<EntryAttachment> attachments, required int index}) =>
      ScaleFadePageRoute<void>(
        builder: (context) =>
            AttachmentViewPage(attachments: attachments, index: index),
      );

  @override
  State<AttachmentViewPage> createState() => _AttachmentViewPageState();
}

class _AttachmentViewPageState extends State<AttachmentViewPage> {
  final Logger _logger = Logger('AttachmentViewPage');

  late PageController _pageController;
  late ValueNotifier<int> _currentPageNotifier;

  final Map<String, Future<_MediaInfo>> _mediaInfo = {};

  final ValueNotifier<int> _pauseRequests = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.index);
    _currentPageNotifier = ValueNotifier<int>(widget.index);
    _probeActivePage(widget.index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _currentPageNotifier.dispose();
    _pauseRequests.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: const CloseButton(),
          actions: [
            infoButton(context),
            openButton(context),
            shareButton(context),
            downloadButton(context)
          ],
        ),
        body: ZoomableAttachmentPageView(
          controller: _pageController,
          imageProviders: widget.attachments
              .map((attachment) => attachment.type == AttachmentType.image
                  ? EntryImageProvider(attachment.filePath)
                  : null)
              .toList(),
          customPageBuilder: (context, index) {
            final attachment = widget.attachments[index];
            return switch (attachment.type) {
              AttachmentType.video ||
              AttachmentType.audio =>
                MediaAttachmentPage(
                  filePath: attachment.filePath,
                  type: attachment.type,
                  pauseRequests: _pauseRequests,
                ),
              AttachmentType.image => const SizedBox.shrink(),
            };
          },
          onPageChanged: (int newIndex) {
            _currentPageNotifier.value = newIndex;
            _probeOnceSettled(newIndex);
          },
        ));
  }

  Widget infoButton(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _currentPageNotifier,
      builder: (context, currentIndex, child) {
        return IconButton(
          icon: const Icon(Icons.info_outline_rounded),
          onPressed: () => _showInfo(widget.attachments[currentIndex]),
        );
      },
    );
  }

  Future<void> _showInfo(EntryAttachment attachment) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final localPath = await AttachmentStorage.instance
          .getLocalPath(attachment.filePath, attachment.type);
      if (localPath == null) {
        if (mounted) await _showLoadFailed();
        return;
      }

      final sizeString =
          formatFileSize(await File(localPath).length(), l10n.localeName);

      final info = await _mediaInfoFor(attachment);
      final resolution = info.size;
      final duration = info.duration;

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow(Icons.label_rounded, attachment.filePath),
              const SizedBox(height: 8),
              _infoRow(Icons.storage_rounded, sizeString),
              const SizedBox(height: 8),
              if (resolution != null) ...[
                _infoRow(Icons.image_aspect_ratio_rounded,
                    "${resolution.width.round()} x ${resolution.height.round()}"),
                const SizedBox(height: 8),
              ],
              if (duration != null) ...[
                _infoRow(Icons.timer_outlined, formatDuration(duration)),
                const SizedBox(height: 8),
              ],
              _infoRow(
                Icons.schedule_rounded,
                "${TimeManager.formatDateWithWeekday(attachment.timeCreate, context)} ${TimeManager.localizedTimeFormat(context, TimeManager.currentLocale(context)).format(attachment.timeCreate)}",
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(MaterialLocalizations.of(context).closeButtonLabel),
            ),
          ],
        ),
      );
    } catch (error, stackTrace) {
      _logger.warning('Reading attachment info failed', error, stackTrace);
      if (mounted) {
        await _showUnexpectedFailure(
            AppLocalizations.of(context)!.attachmentLoadFailed, error);
      }
    }
  }

  void _probeActivePage(int index) {
    final attachment = widget.attachments[index];
    if (attachment.type != AttachmentType.image) _mediaInfoFor(attachment);
  }

  Future<void> _probeOnceSettled(int index) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted && _currentPageNotifier.value == index) _probeActivePage(index);
  }

  Future<_MediaInfo> _mediaInfoFor(EntryAttachment attachment) =>
      _mediaInfo.putIfAbsent("${attachment.type.name}/${attachment.filePath}",
          () => _loadMediaInfo(attachment));

  Future<_MediaInfo> _loadMediaInfo(EntryAttachment attachment) async {
    try {
      final localPath = await AttachmentStorage.instance
          .getLocalPath(attachment.filePath, attachment.type);
      if (localPath == null) return const _MediaInfo();
      switch (attachment.type) {
        case AttachmentType.image:
          return _MediaInfo(size: await _decodeImageSize(localPath));
        case AttachmentType.video:
          return await _probeVideo(localPath);
        case AttachmentType.audio:
          return await _probeAudio(localPath);
      }
    } catch (error, stackTrace) {
      _logger.warning('Reading media info failed', error, stackTrace);
      return const _MediaInfo();
    }
  }

  Future<_MediaInfo> _probeVideo(String path) async {
    final controller = VideoPlayerController.file(File(path));
    try {
      await controller.initialize().timeout(const Duration(seconds: 10));
      return _MediaInfo(
          size: controller.value.size, duration: controller.value.duration);
    } finally {
      await controller.dispose();
    }
  }

  Future<_MediaInfo> _probeAudio(String path) async {
    final player = AudioPlayer();
    try {
      final duration =
          await player.setFilePath(path).timeout(const Duration(seconds: 10));
      return _MediaInfo(duration: duration);
    } finally {
      await player.dispose();
    }
  }

  Future<Size?> _decodeImageSize(String path) async {
    try {
      final image = await decodeImageFromList(await File(path).readAsBytes());
      final size = Size(image.width.toDouble(), image.height.toDouble());
      image.dispose();
      return size;
    } catch (error, stackTrace) {
      _logger.warning('Reading image size failed', error, stackTrace);
      return null;
    }
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

  Future<void> _showNotice(String message) => showAppDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(MaterialLocalizations.of(context).okButtonLabel),
            ),
          ],
        ),
      );

  Future<void> _showLoadFailed() =>
      _showNotice(AppLocalizations.of(context)!.attachmentLoadFailed);

  Future<void> _showUnexpectedFailure(String description, [Object? error]) =>
      showFailureDialog(context, description: description, error: error);

  Widget openButton(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _currentPageNotifier,
      builder: (context, currentIndex, child) {
        return IconButton(
          icon: const Icon(Icons.open_in_new_rounded),
          onPressed: () => _openExternally(widget.attachments[currentIndex]),
        );
      },
    );
  }

  Future<void> _openExternally(EntryAttachment attachment) async {
    try {
      final localPath = await AttachmentStorage.instance
          .getLocalPath(attachment.filePath, attachment.type);
      if (localPath == null) {
        if (mounted) await _showLoadFailed();
        return;
      }
      if (!mounted) return;
      _pauseRequests.value++;
      final opened = await ExternalOpener.open(
          localPath, attachmentMimeType(attachment.filePath, attachment.type));
      if (!opened && mounted) {
        await _showNotice(AppLocalizations.of(context)!.attachmentNoAppToOpen);
      }
    } catch (error, stackTrace) {
      _logger.warning(
          'Opening attachment externally failed', error, stackTrace);
      if (mounted) {
        await _showUnexpectedFailure(
            AppLocalizations.of(context)!.attachmentLoadFailed, error);
      }
    }
  }

  Widget shareButton(BuildContext context) {
    if (Platform.isAndroid) {
      return ValueListenableBuilder(
        valueListenable: _currentPageNotifier,
        builder: (context, currentIndex, child) {
          return IconButton(
              icon: const Icon(Icons.share_rounded),
              onPressed: () => _share(widget.attachments[currentIndex]));
        },
      );
    }

    return Container();
  }

  Future<void> _share(EntryAttachment attachment) async {
    try {
      final localPath = await AttachmentStorage.instance
          .getLocalPath(attachment.filePath, attachment.type);
      if (localPath == null) {
        if (mounted) await _showLoadFailed();
        return;
      }
      await SharePlus.instance.share(ShareParams(files: [
        XFile(localPath,
            mimeType: attachmentMimeType(attachment.filePath, attachment.type))
      ], fileNameOverrides: [
        attachment.filePath
      ]));
    } catch (error, stackTrace) {
      _logger.warning('Sharing attachment failed', error, stackTrace);
      if (mounted) {
        await _showUnexpectedFailure(
            AppLocalizations.of(context)!.exportErrorDescription, error);
      }
    }
  }

  Widget downloadButton(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: _currentPageNotifier,
        builder: (context, currentIndex, child) {
          return IconButton(
              icon: const Icon(Icons.download_rounded),
              onPressed: () => _download(widget.attachments[currentIndex]));
        });
  }

  Future<void> _download(EntryAttachment attachment) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final localPath = await AttachmentStorage.instance
          .getLocalPath(attachment.filePath, attachment.type);
      if (localPath == null) {
        if (mounted) await _showLoadFailed();
        return;
      }

      final saveDirectory = await StoragePicker.pickDirectory();
      if (saveDirectory == null) return;

      final saved = await saveDirectory
          .copyFileInto(localPath, attachment.filePath, mimeType: '*/*');
      if (!saved && mounted) {
        await _showNotice(l10n.exportErrorDescription);
      }
    } catch (error, stackTrace) {
      _logger.warning('Downloading attachment failed', error, stackTrace);
      if (mounted) {
        await _showUnexpectedFailure(l10n.exportErrorDescription, error);
      }
    }
  }
}

class _MediaInfo {
  final Size? size;
  final Duration? duration;

  const _MediaInfo({this.size, this.duration});
}
