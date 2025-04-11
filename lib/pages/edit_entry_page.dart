import 'dart:async';
import 'dart:io';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/notification_manager.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/local_image_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:daily_you/entries_database.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/widgets/entry_image_picker.dart';
import 'package:daily_you/widgets/entry_text_edit.dart';
import 'package:daily_you/widgets/entry_mood_picker.dart';

class AddEditEntryPage extends StatefulWidget {
  final Entry? entry;
  final DateTime? overrideCreateDate;
  final bool openCamera;
  final List<EntryImage> images;

  const AddEditEntryPage({
    super.key,
    this.entry,
    this.overrideCreateDate,
    this.openCamera = false,
    this.images = const <EntryImage>[],
  });
  @override
  State<AddEditEntryPage> createState() => _AddEditEntryPageState();
}

class _AddEditEntryPageState extends State<AddEditEntryPage> {
  late int id;
  late String text;
  late int? mood;
  late List<EntryImage> currentImages;
  bool entryChanged = false;
  bool loadingTemplate = true;
  final ScrollController _scrollController = ScrollController();
  bool _isDragging = false;
  Timer? _autoScrollTimer;
  Offset _draggingOffset = Offset.zero;
  bool _openedCamera = false;

  @override
  void initState() {
    super.initState();
    id = widget.entry?.id ?? -1;
    mood = widget.entry?.mood;
    text = widget.entry?.text ?? '';
    currentImages = List.empty(growable: true);
    currentImages.addAll(widget.images);
    if (widget.entry == null) {
      _loadTemplate();
    } else {
      loadingTemplate = false;
    }
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  Future _loadTemplate() async {
    var defaultTemplateId =
        ConfigProvider.instance.get(ConfigKey.defaultTemplate);
    if (defaultTemplateId != -1) {
      var defaultTemplate =
          await EntriesDatabase.instance.getTemplate(defaultTemplateId);
      if (defaultTemplate != null) {
        text = defaultTemplate.text ?? '';
      }
    }
    setState(() {
      loadingTemplate = false;
    });
  }

  void _showDeleteEntryPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.deleteLogTitle),
          actions: [
            TextButton(
              child:
                  Text(MaterialLocalizations.of(context).deleteButtonTooltip),
              onPressed: () async {
                await deleteEntry(id);
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
            TextButton(
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
              onPressed: () async {
                Navigator.pop(context);
              },
            )
          ],
          content: Text(AppLocalizations.of(context)!.deleteLogDescription),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          actions: [if (widget.entry != null) deleteButton(), saveButton()],
        ),
        body: Center(
          child: Container(
            constraints: BoxConstraints.loose(const Size.fromWidth(800)),
            child: ListView(
              padding: const EdgeInsets.only(left: 8, right: 8),
              children: [
                if (currentImages.isEmpty)
                  EntryImagePicker(
                      imgPath: null,
                      openCamera: widget.openCamera && !_openedCamera,
                      onChangedImage: (imgPaths) {
                        _openedCamera = true;
                        if (imgPaths != null) {
                          addLocalImage(imgPaths);
                        }
                      }),
                if (currentImages.isNotEmpty)
                  SizedBox(
                    height: 220,
                    child: Listener(
                      onPointerMove: _handlePointerMove,
                      onPointerDown: _handlePointerDown,
                      onPointerUp: _handlePointerUp,
                      child: ListView.builder(
                        controller: _scrollController,
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        itemCount: currentImages.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return EntryImagePicker(
                                imgPath: null,
                                openCamera: widget.openCamera && !_openedCamera,
                                onChangedImage: (imgPaths) {
                                  _openedCamera = true;
                                  if (imgPaths != null) {
                                    addLocalImage(imgPaths);
                                  }
                                });
                          } else {
                            return _buildDraggableListItem(index - 1);
                          }
                        },
                      ),
                    ),
                  ),
                StatefulBuilder(
                  builder: (context, setState) => EntryMoodPicker(
                      date: widget.entry != null
                          ? DateFormat.yMMMEd(WidgetsBinding
                                  .instance.platformDispatcher.locale
                                  .toString())
                              .format(widget.entry!.timeCreate)
                          : DateFormat.yMMMEd(WidgetsBinding
                                  .instance.platformDispatcher.locale
                                  .toString())
                              .format(
                                  widget.overrideCreateDate ?? DateTime.now()),
                      moodValue: mood,
                      onChangedMood: (mood) =>
                          {setState(() => this.mood = mood)}),
                ),
                if (!loadingTemplate)
                  StatefulBuilder(
                    builder: (context, setState) => EntryTextEditor(
                        text: text,
                        onChangedText: (text) =>
                            setState(() => this.text = text)),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      );

  Widget saveButton() {
    return IconButton(
      icon: const Icon(Icons.check),
      onPressed: addOrUpdateNote,
    );
  }

  Widget deleteButton() => IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () => _showDeleteEntryPopup(),
      );

  Widget _buildDraggableListItem(int index) {
    bool isHovered = false;
    return LongPressDraggable<EntryImage>(
      onDragStarted: () => _isDragging = true,
      data: currentImages[index],
      feedback: Opacity(
        opacity: 0.7,
        child: SizedBox(
          key: ValueKey(currentImages[index].imgRank),
          height: 220,
          width: 220,
          child: Card(
              clipBehavior: Clip.antiAlias,
              child: LocalImageLoader(imagePath: currentImages[index].imgPath)),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.2,
        child: SizedBox(
          key: ValueKey(currentImages[index].imgRank),
          height: 220,
          width: 220,
          child: Card(
              clipBehavior: Clip.antiAlias,
              child: LocalImageLoader(imagePath: currentImages[index].imgPath)),
        ),
      ),
      child: DragTarget<EntryImage>(
        onLeave: (data) {
          isHovered = false;
        },
        onWillAcceptWithDetails: (data) {
          isHovered = true;
          return true;
        },
        onAcceptWithDetails: (data) {
          int fromIndex = currentImages.indexOf(data.data);
          isHovered = false;
          final movedItem = currentImages.removeAt(fromIndex);
          currentImages.insert(index, movedItem);
          // Update ranks
          for (int i = 0; i < currentImages.length; i++) {
            currentImages[i].imgRank = currentImages.length - 1 - i;
          }
          sortImages();
          setState(() {
            currentImages;
          });
        },
        builder: (context, candidateData, rejectedData) {
          return _buildListItem(index, isHovered, context);
        },
      ),
    );
  }

  Widget _buildListItem(int index, bool isHovered, context) {
    if (isHovered && _isDragging) {
      return SizedBox(
          key: ValueKey(currentImages[index].imgRank),
          height: 220,
          width: 220,
          child: Stack(alignment: Alignment.center, children: [
            Opacity(
              opacity: 0.2,
              child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: LocalImageLoader(
                      imagePath: currentImages[index].imgPath)),
            ),
            Icon(
                size: 100.0,
                color: Theme.of(context).colorScheme.primary,
                Icons.arrow_downward_rounded)
          ]));
    } else {
      return Stack(alignment: Alignment.bottomCenter, children: [
        EntryImagePicker(
            imgPath: currentImages[index].imgPath,
            openCamera: false,
            onChangedImage: (imgPath) {
              if (imgPath == null) {
                removeLocalImage(index);
              }
            }),
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Icon(Icons.drag_handle_rounded),
        ),
      ]);
    }
  }

  void _handlePointerDown(PointerEvent event) {
    _startAutoScrollTimer();
  }

  void _handlePointerUp(PointerEvent event) {
    _isDragging = false;
    _autoScrollTimer?.cancel();
  }

  void _handlePointerMove(PointerEvent event) {
    _draggingOffset = event.position;
  }

  void _startAutoScrollTimer() {
    const autoScrollThreshold = 50.0;
    const scrollSpeed = 15.0;

    _autoScrollTimer =
        Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (!_isDragging) {
        return;
      }

      final position = _scrollController.position;
      if (_draggingOffset.dx < autoScrollThreshold &&
          position.pixels > position.minScrollExtent) {
        _scrollController.jumpTo(position.pixels - scrollSpeed);
      } else if (_draggingOffset.dx >
              position.viewportDimension - autoScrollThreshold &&
          position.pixels < position.maxScrollExtent) {
        _scrollController.jumpTo(position.pixels + scrollSpeed);
      }
    });
  }

  void addOrUpdateNote() async {
    final isUpdating = widget.entry != null;

    if (isUpdating) {
      await updateEntry();
    } else {
      await addEntry();
    }
  }

  Future updateEntry() async {
    final updatedEntry = widget.entry!.copy(
      text: text,
      mood: mood,
      timeModified: DateTime.now(),
    );

    var entry = await EntriesDatabase.instance.updateEntry(updatedEntry);
    await saveOrUpdateImage(widget.entry!.id!);
    Navigator.of(context).pop(entry);
  }

  Future addEntry() async {
    final newEntry = Entry(
      text: text,
      mood: mood,
      timeCreate: widget.overrideCreateDate ?? DateTime.now(),
      timeModified: DateTime.now(),
    );

    if (Platform.isAndroid &&
        TimeManager.isSameDay(DateTime.now(), newEntry.timeCreate)) {
      await NotificationManager.instance.dismissReminderNotification();
    }
    var entry = await EntriesDatabase.instance.addEntry(newEntry);
    await saveOrUpdateImage(entry.id!);
    Navigator.of(context).pop(entry);
  }

  Future deleteEntry(int id) async {
    // Delete entry images
    var entryImages = await EntriesDatabase.instance.getImagesForEntry(id);
    for (EntryImage image in entryImages) {
      await EntriesDatabase.instance.deleteImg(image.imgPath);
      await EntriesDatabase.instance.removeImg(image);
    }
    // Delete entry
    await EntriesDatabase.instance.deleteEntry(id);
  }

  Future saveOrUpdateImage(int entryId) async {
    // Add images
    for (EntryImage currentImage in currentImages) {
      currentImage.entryId = entryId;
      if (currentImage.id == null ||
          widget.images
              .where((image) => image.id == currentImage.id!)
              .isEmpty) {
        await EntriesDatabase.instance.addImg(currentImage);
      }
    }
    // Update images
    for (EntryImage existingImage in widget.images) {
      EntryImage? matchingImage = currentImages
          .where((image) => image.id == existingImage.id!)
          .firstOrNull;
      if (matchingImage == null) {
        // Delete image
        await EntriesDatabase.instance.removeImg(existingImage);
      } else {
        await EntriesDatabase.instance.updateImg(matchingImage);
      }
    }
  }

  void sortImages() {
    currentImages.sort((a, b) {
      if (a.imgRank == b.imgRank) {
        return 0;
      } else if (a.imgRank < b.imgRank) {
        return 1;
      } else {
        return -1;
      }
    });
  }

  void addLocalImage(List<String> imgPaths) {
    for (var imgPath in imgPaths) {
      currentImages.add(EntryImage(
          entryId: widget.entry?.id,
          imgPath: imgPath,
          imgRank: currentImages.length,
          timeCreate: DateTime.now()));
      sortImages();
    }
    setState(() {
      currentImages;
    });
  }

  void removeLocalImage(int index) {
    currentImages.remove(currentImages[index]);
    // Update ranks
    for (int i = 0; i < currentImages.length; i++) {
      currentImages[i].imgRank = currentImages.length - 1 - i;
    }
    sortImages();
    setState(() {
      currentImages;
    });
  }
}
