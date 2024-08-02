import 'dart:io';

import 'package:daily_you/config_manager.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/notification_manager.dart';
import 'package:daily_you/time_manager.dart';
import 'package:flutter/material.dart';
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
    Key? key,
    this.entry,
    this.overrideCreateDate,
    this.openCamera = false,
    this.images = const <EntryImage>[],
  }) : super(key: key);
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

  Future _loadTemplate() async {
    var defaultTemplateId = ConfigManager.instance.getField("defaultTemplate");
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
          title: const Text('Delete Log?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Do you want to delete this log?"),
              const SizedBox(
                height: 8,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(
                      Icons.delete_rounded,
                      size: 24,
                    ),
                    label: const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Text(
                        "Delete",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    onPressed: () async {
                      // TODO: Delete images for entry
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      await EntriesDatabase.instance.deleteEntry(id);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(
                      Icons.cancel_rounded,
                      size: 24,
                    ),
                    label: const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Text(
                        "Cancel",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.surface,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
                if (currentImages.length == 0)
                  EntryImagePicker(
                      imgPath: null,
                      openCamera: widget.openCamera,
                      onChangedImage: (imgPath) => addLocalImage(imgPath)),
                if (currentImages.length > 0)
                  Container(
                    height: 220,
                    child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: currentImages.length + 1,
                        itemBuilder: ((context, index) {
                          if (index == 0) {
                            return EntryImagePicker(
                              imgPath: null,
                              openCamera: widget.openCamera,
                              onChangedImage: (imgPath) =>
                                  addLocalImage(imgPath),
                            );
                          } else {
                            // TODO: Remove rank number card
                            return Stack(children: [
                              EntryImagePicker(
                                  imgPath: currentImages[index - 1].imgPath,
                                  onChangedImage: (imgPath) =>
                                      removeLocalImage(index - 1)),
                              Card(
                                  child: Text(
                                      "${currentImages[index - 1].imgRank}")),
                            ]);
                          }
                        })),
                  ),
                StatefulBuilder(
                  builder: (context, setState) => EntryMoodPicker(
                      date: widget.entry != null
                          ? DateFormat.yMMMEd().format(widget.entry!.timeCreate)
                          : DateFormat.yMMMEd().format(
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
      await NotificationManager.instance.notifications.cancel(0);
    }
    var entry = await EntriesDatabase.instance.create(newEntry);
    await saveOrUpdateImage(entry.id!);
    Navigator.of(context).pop(entry);
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

  void addLocalImage(String? imgPath) {
    if (imgPath != null) {
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
