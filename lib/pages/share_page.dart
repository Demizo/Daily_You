// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/pages/edit_entry_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/day_menu.dart';
import 'package:daily_you/widgets/entry_attachment_actions.dart';
import 'package:daily_you/widgets/attachment_tile_background.dart';
import 'package:daily_you/widgets/attachment_grid.dart';
import 'package:daily_you/widgets/video_thumbnail_cache.dart';
import 'package:daily_you/widgets/large_entry_card_widget.dart';
import 'package:daily_you/widgets/vertical_calendar.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_receiver/share_receiver.dart';

class SharePage extends StatefulWidget {
  final SharePayload payload;

  const SharePage({super.key, required this.payload});

  @override
  State<SharePage> createState() => _SharePageState();
}

class _SharePageState extends State<SharePage> {
  final ScrollController _scrollController = ScrollController();
  bool _opening = false;

  @override
  void dispose() {
    widget.payload.deleteMedia();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _selectDay(BuildContext dayContext, DateTime day) async {
    if (_opening) return;
    final entries = EntriesProvider.instance.getEntriesForDate(day);
    Entry? entry;
    if (entries.isNotEmpty) {
      final choice = await _showDayChoiceMenu(dayContext, day, entries);
      if (choice == null) return;
      entry = choice.entry;
    }
    if (!mounted) return;
    await _openEditor(day, entry);
  }

  Future<({Entry? entry})?> _showDayChoiceMenu(
      BuildContext dayContext, DateTime day, List<Entry> entries) {
    final locale = TimeManager.currentLocale(dayContext);
    final timeFormat = TimeManager.localizedTimeFormat(dayContext, locale);
    return showDayMenu<({Entry? entry})>(
      dayContext,
      items: [
        for (final entry in entries)
          PopupMenuItem(
            value: (entry: entry),
            child: Row(
              children: [
                const Icon(Icons.edit_note_rounded),
                const SizedBox(width: 12),
                Text(timeFormat.format(entry.timeCreate)),
              ],
            ),
          ),
        PopupMenuItem(
          value: (entry: null),
          child: Row(
            children: [
              const Icon(Icons.add_rounded),
              const SizedBox(width: 12),
              Text(TimeManager.formatDate(day, dayContext)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openEditor(DateTime day, Entry? entry) async {
    setState(() => _opening = true);
    final newAttachments = <NewAttachment>[];
    try {
      final payload = widget.payload;
      newAttachments
        ..addAll(
            await EntryAttachmentActions.importSharedImages(payload.imagePaths))
        ..addAll(
            await EntryAttachmentActions.importSharedVideos(payload.videoPaths))
        ..addAll(
            await EntryAttachmentActions.importSharedAudio(payload.audioPaths));
    } catch (_) {
      await EntryAttachmentActions.deleteStoredAttachments(newAttachments);
      if (mounted) setState(() => _opening = false);
      rethrow;
    }
    if (!mounted) {
      await EntryAttachmentActions.deleteStoredAttachments(newAttachments);
      return;
    }

    final page = entry == null
        ? AddEditEntryPage(
            overrideCreateDate: TimeManager.currentTimeOnDifferentDate(day)
                .copyWith(isUtc: false),
            attachments: EntryAttachment.appendRanked(const [], newAttachments,
                entryId: -1),
            sharedText: widget.payload.text,
          )
        : AddEditEntryPage(
            entry: entry,
            attachments: EntryAttachment.appendRanked(
                EntryAttachmentsProvider.instance.getForEntry(entry),
                newAttachments,
                entryId: entry.id!),
            sharedText: widget.payload.text,
          );
    await Navigator.of(context).pushReplacement(MaterialPageRoute(
      allowSnapshotting: false,
      builder: (context) => page,
    ));
  }

  Widget _previewTile(String path) {
    final payload = widget.payload;
    if (payload.videoPaths.contains(path)) {
      final cache = VideoThumbnailCache.instance;
      return VideoTileBackground(
        id: path,
        peek: () => cache.peekForPath(path),
        load: () => cache.getThumbnailForPath(path),
      );
    }
    if (payload.audioPaths.contains(path)) {
      return AudioTileBackground(seed: path.hashCode);
    }
    return Image.file(File(path), fit: BoxFit.cover, cacheWidth: 500);
  }

  Widget _buildPreview() {
    final payload = widget.payload;
    final text = payload.text;
    final hasText = text != null && text.isNotEmpty;
    final mediaPaths = [
      ...payload.imagePaths,
      ...payload.videoPaths,
      ...payload.audioPaths,
    ];
    final card = LargeCard(
      media: mediaPaths.isEmpty
          ? null
          : AttachmentGrid.fromPaths(
              attachmentPaths: mediaPaths,
              pathTileBuilder: _previewTile,
            ),
      body: hasText ? LargeCard.markdownBody(text) : null,
    );
    if (mediaPaths.isEmpty || hasText) return card;
    return Center(child: AspectRatio(aspectRatio: 1, child: card));
  }

  @override
  Widget build(BuildContext context) {
    final calendar = VerticalCalendar(
      scrollController: _scrollController,
      onDaySelected: _selectDay,
    );
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(AppLocalizations.of(context)!.shareAddToLogPickerTitle),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
              child: Column(
                children: [
                  SizedBox(height: 200, child: _buildPreview()),
                  const SizedBox(height: 8),
                  Expanded(child: calendar),
                ],
              ),
            ),
            if (_opening)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black26,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
