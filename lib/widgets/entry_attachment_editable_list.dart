// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:ui';

import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/pages/attachment_view_page.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/attachment_tile_background.dart';
import 'package:daily_you/widgets/expressive_loading_indicator.dart';
import 'package:material_ui/material_ui.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';

class EntryAttachmentEditableList extends StatefulWidget {
  final List<EntryAttachment> attachments;
  final ValueChanged<List<EntryAttachment>> onAttachmentsChanged;
  final int pendingCount;

  const EntryAttachmentEditableList({
    super.key,
    required this.attachments,
    required this.onAttachmentsChanged,
    this.pendingCount = 0,
  });

  @override
  State<EntryAttachmentEditableList> createState() =>
      _EntryAttachmentEditableListState();
}

class _EntryAttachmentEditableListState
    extends State<EntryAttachmentEditableList> {
  late List<EntryAttachment> _attachments;
  final ScrollController _scrollController = ScrollController();

  void _showDeleteAttachmentPopup(int index) {
    showAppDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.deleteAttachmentTitle),
          actions: [
            TextButton(
              child:
                  Text(MaterialLocalizations.of(context).deleteButtonTooltip),
              onPressed: () {
                _deleteAttachment(index);
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
              onPressed: () async {
                Navigator.pop(context);
              },
            )
          ],
          content:
              Text(AppLocalizations.of(context)!.deleteAttachmentDescription),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _attachments = List.of(widget.attachments);
  }

  @override
  void didUpdateWidget(EntryAttachmentEditableList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.attachments, oldWidget.attachments)) {
      _attachments = List.of(widget.attachments);
    }
    if (_totalCount(widget) > _totalCount(oldWidget)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  static int _totalCount(EntryAttachmentEditableList list) =>
      list.attachments.length + list.pendingCount;

  @override
  Widget build(BuildContext context) {
    final pendingCount = widget.pendingCount;
    final totalCount = _attachments.length + pendingCount;
    if (totalCount == 0) return const SizedBox.shrink();
    if (totalCount > 1) {
      return SizedBox(
        height: 160,
        child: ReorderableListView.builder(
            scrollController: _scrollController,
            scrollDirection: Axis.horizontal,
            proxyDecorator: _proxyDecorator,
            footer: pendingCount == 0
                ? null
                : Row(children: [
                    for (var i = 0; i < pendingCount; i++)
                      const SizedBox(
                          width: 160, height: 160, child: _PendingTile()),
                  ]),
            itemBuilder: (context, index) {
              return SizedBox(
                key: ValueKey(
                    (_attachments[index].type, _attachments[index].filePath)),
                width: 160,
                height: 160,
                child: editableWidget(
                  index,
                ),
              );
            },
            itemCount: _attachments.length,
            onReorderItem: (int oldIndex, int newIndex) {
              final EntryAttachment attachment =
                  _attachments.removeAt(oldIndex);
              _attachments.insert(newIndex, attachment);
              _updateAttachmentRanks();
              setState(() {});
              widget.onAttachmentsChanged(List.of(_attachments));
            }),
      );
    } else {
      return Center(
          child: SizedBox(
              width: 220,
              height: 220,
              child: pendingCount > 0
                  ? const _PendingTile()
                  : editableWidget(0, showDragHandle: false)));
    }
  }

  void _openViewer(int index) {
    Navigator.of(context).push(
        AttachmentViewPage.route(attachments: _attachments, index: index));
  }

  Card editableWidget(int index, {bool showDragHandle = true}) {
    return Card.filled(
      clipBehavior: Clip.antiAlias,
      child:
          Stack(alignment: Alignment.center, fit: StackFit.expand, children: [
        GestureDetector(
          onTap: () => _openViewer(index),
          child: AttachmentTileBackground(attachment: _attachments[index]),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    onPressed: () => _showDeleteAttachmentPopup(index),
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                            color: Colors.black.withValues(alpha: 0.8),
                            blurRadius: 6,
                            offset: Offset(0, 0)),
                      ],
                    ))
              ],
            ),
            if (showDragHandle)
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.drag_handle_rounded,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                          color: Colors.black.withValues(alpha: 0.8),
                          blurRadius: 6,
                          offset: Offset(0, 0)),
                    ],
                  ),
                ],
              )
          ],
        )
      ]),
    );
  }

  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double animValue = Curves.easeInOut.transform(animation.value);
        final double scale = lerpDouble(1, 1.04, animValue)!;
        return Transform.scale(scale: scale, child: child);
      },
      child: child,
    );
  }

  void _deleteAttachment(int index) {
    _attachments.removeAt(index);
    _updateAttachmentRanks();
    setState(() {});
    widget.onAttachmentsChanged(List.of(_attachments));
  }

  void _updateAttachmentRanks() {
    for (int i = 0; i < _attachments.length; i++) {
      _attachments[i].rank = _attachments.length - 1 - i;
    }
  }
}

class _PendingTile extends StatelessWidget {
  const _PendingTile();

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      child: Center(
        child: ExpressiveLoadingIndicator(),
      ),
    );
  }
}
