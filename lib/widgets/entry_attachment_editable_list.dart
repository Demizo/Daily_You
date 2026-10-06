// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:ui';

import 'package:daily_you/models/attachment.dart';
import 'package:material_ui/material_ui.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';

import 'local_image_loader.dart';

class EntryAttachmentEditableList extends StatefulWidget {
  final List<EntryAttachment> attachments;
  final ValueChanged<List<EntryAttachment>> onAttachmentsChanged;

  const EntryAttachmentEditableList({
    super.key,
    required this.attachments,
    required this.onAttachmentsChanged,
  });

  @override
  State<EntryAttachmentEditableList> createState() =>
      _EntryAttachmentEditableListState();
}

class _EntryAttachmentEditableListState
    extends State<EntryAttachmentEditableList> {
  late List<EntryAttachment> _attachments;

  void _showDeleteAttachmentPopup(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.deletePhotoTitle),
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
          content: Text(AppLocalizations.of(context)!.deletePhotoDescription),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _attachments = widget.attachments;
  }

  @override
  void didUpdateWidget(EntryAttachmentEditableList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.attachments, oldWidget.attachments)) {
      _attachments = widget.attachments;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_attachments.length > 1) {
      return SizedBox(
        height: 160,
        child: ReorderableListView.builder(
            scrollDirection: Axis.horizontal,
            proxyDecorator: _proxyDecorator,
            itemBuilder: (context, index) {
              return SizedBox(
                key: ValueKey(index),
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
              widget.onAttachmentsChanged(_attachments);
            }),
      );
    } else {
      return Center(
          child: SizedBox(
              width: 220,
              height: 220,
              child: editableWidget(0, showDragHandle: false)));
    }
  }

  Card editableWidget(int index, {bool showDragHandle = true}) {
    return Card.filled(
      clipBehavior: Clip.antiAlias,
      child:
          Stack(alignment: Alignment.center, fit: StackFit.expand, children: [
        LocalImageLoader(imagePath: _attachments[index].filePath),
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
    widget.onAttachmentsChanged(_attachments);
  }

  void _updateAttachmentRanks() {
    for (int i = 0; i < _attachments.length; i++) {
      _attachments[i].rank = _attachments.length - 1 - i;
    }
  }
}
