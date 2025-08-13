import 'dart:async';
import 'dart:io';

import 'package:daily_you/models/image.dart';
import 'package:daily_you/notification_manager.dart';
import 'package:daily_you/stats_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/edit_toolbar.dart';
import 'package:daily_you/widgets/local_image_loader.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
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

class _AddEditEntryPageState extends State<AddEditEntryPage>
    with WidgetsBindingObserver {
  late Entry _entry;
  int id = -1;
  String text = "";
  int? mood;
  late List<EntryImage> currentImages;
  bool _loadingEntry = true;
  final ScrollController _scrollController = ScrollController();
  bool _isDragging = false;
  Timer? _autoScrollTimer;
  Offset _draggingOffset = Offset.zero;
  bool _openedCamera = false;
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _textEditingController = TextEditingController();
  final UndoHistoryController _undoController = UndoHistoryController();
  bool _deletingEntry = false;
  bool _savingEntry = false;
  bool _newEntry = false;

  Future<void> _initEntry() async {
    if (widget.entry == null) {
      var createTime =
          (TimeManager.isToday(widget.overrideCreateDate ?? DateTime.now()))
              ? DateTime.now()
              : (widget.overrideCreateDate ?? DateTime.now());
      _entry = await EntriesDatabase.instance.createNewEntry(createTime);
      _newEntry = true;
    } else {
      _entry = widget.entry!;
    }
    id = _entry.id ?? -1;
    mood = _entry.mood;
    text = _entry.text;
    _textEditingController
        .addListener(() => text = _textEditingController.text);
    setState(() {
      _loadingEntry = false;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    currentImages = List.empty(growable: true);
    for (var image in widget.images) {
      currentImages.add(image.copy());
    }
    _initEntry();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _focusNode.dispose();
    _textEditingController.dispose();
    _undoController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden) {
      _saveEntry();
    }
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
                _deletingEntry = true;
                Navigator.of(context).popUntil((route) => route.isFirst);
                await _deleteEntry(id);
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
  Widget build(BuildContext context) => _loadingEntry
      ? Scaffold()
      : PopScope(
          onPopInvokedWithResult: (didPop, result) async {
            if (!_deletingEntry) {
              if (_newEntry) {
                final updatedEntry = _entry.copy(
                  text: text,
                  mood: mood,
                  timeModified: DateTime.now(),
                );
                if (updatedEntry.text == _entry.text &&
                    updatedEntry.mood == _entry.mood &&
                    currentImages.isEmpty) {
                  await _deleteEntry(id);
                } else {
                  await _saveEntry();
                }
              } else {
                await _saveEntry();
              }
            }
          },
          child: Scaffold(
            appBar: AppBar(actions: [_deleteButton()]),
            body: Column(children: [
              Expanded(
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
                                _addLocalImage(imgPaths);
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
                                      openCamera:
                                          widget.openCamera && !_openedCamera,
                                      onChangedImage: (imgPaths) {
                                        _openedCamera = true;
                                        if (imgPaths != null) {
                                          _addLocalImage(imgPaths);
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
                            date: DateFormat.yMMMEd(
                                    TimeManager.currentLocale(context))
                                .format(_entry.timeCreate),
                            moodValue: mood,
                            onChangedMood: (mood) =>
                                {setState(() => this.mood = mood)}),
                      ),
                      StatefulBuilder(
                          builder: (context, setState) => EntryTextEditor(
                                text: text,
                                focusNode: _focusNode,
                                textEditingController: _textEditingController,
                                undoHistoryController: _undoController,
                              )),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: EditToolbar(
                  controller: _textEditingController,
                  undoController: _undoController,
                  focusNode: _focusNode,
                  showTemplatesButton: true,
                ),
              ),
            ]),
          ),
        );

  Widget _deleteButton() => IconButton(
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
          _sortImages();
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
                _removeLocalImage(index);
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

  Future<void> _saveEntry() async {
    // Saving is guarded since quickly entering and exiting the app could trigger
    // multiple async saves.
    if (_savingEntry == false) {
      _savingEntry = true;

      final updatedEntry = _entry.copy(
        text: text,
        mood: mood,
        timeModified: DateTime.now(),
      );

      if (Platform.isAndroid &&
          TimeManager.isSameDay(DateTime.now(), updatedEntry.timeCreate)) {
        await NotificationManager.instance.dismissReminderNotification();
      }
      if (updatedEntry.text != _entry.text ||
          updatedEntry.mood != _entry.mood) {
        await EntriesDatabase.instance.updateEntry(updatedEntry);
      }
      await _saveOrUpdateImage(id);
      _savingEntry = false;
    }
  }

  Future _deleteEntry(int id) async {
    // Delete entry images
    var entryImages = await EntriesDatabase.instance.getImagesForEntry(id);
    for (EntryImage image in entryImages) {
      await EntriesDatabase.instance.deleteImg(image.imgPath);
      await EntriesDatabase.instance.removeImg(image);
    }
    // Delete entry
    await EntriesDatabase.instance.deleteEntry(id);
  }

  Future _saveOrUpdateImage(int entryId) async {
    final savedImages = StatsProvider.instance.getImagesForEntry(_entry);
    // Add images
    for (EntryImage currentImage in currentImages) {
      currentImage.entryId = entryId;
      if (currentImage.id == null ||
          savedImages.where((image) => image.id == currentImage.id!).isEmpty) {
        await EntriesDatabase.instance.addImg(currentImage);
      }
    }
    // Update images
    for (EntryImage existingImage in savedImages) {
      EntryImage? matchingImage = currentImages
          .where((image) => image.id == existingImage.id!)
          .firstOrNull;
      if (matchingImage == null) {
        // Delete image
        await EntriesDatabase.instance.removeImg(existingImage);
      } else if (matchingImage.imgRank != existingImage.imgRank) {
        await EntriesDatabase.instance.updateImg(matchingImage);
      }
    }
    currentImages = StatsProvider.instance.getImagesForEntry(_entry);
  }

  void _sortImages() {
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

  void _addLocalImage(List<String> imgPaths) {
    for (var imgPath in imgPaths) {
      currentImages.add(EntryImage(
          entryId: id,
          imgPath: imgPath,
          imgRank: currentImages.length,
          timeCreate: DateTime.now()));
      _sortImages();
    }
    setState(() {
      currentImages;
    });
  }

  void _removeLocalImage(int index) {
    currentImages.remove(currentImages[index]);
    // Update ranks
    for (int i = 0; i < currentImages.length; i++) {
      currentImages[i].imgRank = currentImages.length - 1 - i;
    }
    _sortImages();
    setState(() {
      currentImages;
    });
  }
}
