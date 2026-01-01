import 'dart:ui';

import 'package:daily_you/models/image.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';

import 'local_image_loader.dart';

class EntryImageEditableList extends StatefulWidget {
  final List<EntryImage> images;
  final ValueChanged<List<EntryImage>> onImagesChanged;

  const EntryImageEditableList({
    super.key,
    required this.images,
    required this.onImagesChanged,
  });

  @override
  State<EntryImageEditableList> createState() => _EntryImageEditableListState();
}

class _EntryImageEditableListState extends State<EntryImageEditableList> {
  late List<EntryImage> _images;

  void _showDeleteImagePopup(int index) {
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
                _deleteImage(index);
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
    _images = widget.images;
  }

  @override
  Widget build(BuildContext context) {
    if (_images.length > 1) {
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
            itemCount: _images.length,
            onReorder: (int oldIndex, int newIndex) {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              final EntryImage image = _images.removeAt(oldIndex);
              _images.insert(newIndex, image);
              _updateImageRanks();
              setState(() {});
              widget.onImagesChanged(_images);
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child:
          Stack(alignment: Alignment.center, fit: StackFit.expand, children: [
        LocalImageLoader(imagePath: _images[index].imgPath),
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
                    onPressed: () => _showDeleteImagePopup(index),
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

  void _deleteImage(int index) {
    _images.removeAt(index);
    _updateImageRanks();
    setState(() {});
    widget.onImagesChanged(_images);
  }

  /// Sets the image ranks assuming that the list is in the correct order
  void _updateImageRanks() {
    for (int i = 0; i < _images.length; i++) {
      _images[i].imgRank = _images.length - 1 - i;
    }
  }
}
