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

  const AddEditEntryPage({
    Key? key,
    this.entry,
    this.overrideCreateDate,
    this.openCamera = false,
  }) : super(key: key);
  @override
  State<AddEditEntryPage> createState() => _AddEditEntryPageState();
}

class _AddEditEntryPageState extends State<AddEditEntryPage> {
  late int id;
  late String text;
  late String? imgPath;
  late int? mood;
  bool entryChanged = false;

  @override
  void initState() {
    super.initState();
    id = widget.entry?.id ?? -1;
    imgPath = widget.entry?.imgPath;
    mood = widget.entry?.mood;
    text = widget.entry?.text ?? '';
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
                      if (imgPath != null) {
                        await EntriesDatabase.instance.deleteEntryImage(id);
                      }
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      await EntriesDatabase.instance.deleteEntry(id);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      backgroundColor: Theme.of(context).colorScheme.background,
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
                      foregroundColor: Theme.of(context).colorScheme.background,
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
                EntryImagePicker(
                    imgPath: imgPath,
                    openCamera: widget.openCamera,
                    onChangedImage: (imgPath) =>
                        setState(() => this.imgPath = imgPath)),
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
                Card(
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 8, top: 4, bottom: 4, right: 8),
                    child: StatefulBuilder(
                      builder: (context, setState) => EntryTextEditor(
                          text: text,
                          onChangedText: (text) =>
                              setState(() => this.text = text)),
                    ),
                  ),
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
      imgPath: imgPath,
      mood: mood,
      timeModified: DateTime.now(),
    );

    var entry = await EntriesDatabase.instance.updateEntry(updatedEntry);
    Navigator.of(context).pop(entry);
  }

  Future addEntry() async {
    final newEntry = Entry(
      text: text,
      imgPath: imgPath,
      mood: mood,
      timeCreate: widget.overrideCreateDate ?? DateTime.now(),
      timeModified: DateTime.now(),
    );

    var entry = await EntriesDatabase.instance.create(newEntry);
    Navigator.of(context).pop(entry);
  }
}
