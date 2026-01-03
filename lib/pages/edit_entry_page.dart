import 'dart:async';
import 'dart:io';

import 'package:daily_you/database/image_storage.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/notification_manager.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/edit_toolbar.dart';
import 'package:daily_you/widgets/entry_image_editable_list.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/widgets/entry_image_picker.dart';
import 'package:daily_you/widgets/entry_text_edit.dart';
import 'package:daily_you/widgets/entry_mood_picker.dart';
import 'package:provider/provider.dart';

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
  String _lastText = "";
  String text = "";
  int? _lastMood;
  int? mood;
  DateTime? _lastEntryDate;
  DateTime? entryDate;
  late List<EntryImage> _currentImages;
  bool _loadingEntry = true;
  bool _openedCamera = false;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _textEditingController = TextEditingController();
  final UndoHistoryController _undoController = UndoHistoryController();
  bool _deletingEntry = false;
  bool _savingEntry = false;
  bool _newEntry = false;
  Timer? _debounceTimer;

  Future<void> _initEntry() async {
    if (widget.entry == null) {
      var createTime =
          (TimeManager.isToday(widget.overrideCreateDate ?? DateTime.now()))
              ? DateTime.now()
              : (widget.overrideCreateDate ?? DateTime.now());
      _entry = await EntriesProvider.instance.createNewEntry(createTime);
      _newEntry = true;
    } else {
      _entry = widget.entry!;
    }
    id = _entry.id ?? -1;
    _lastMood = _entry.mood;
    mood = _entry.mood;
    _lastEntryDate = _entry.timeCreate;
    entryDate = _entry.timeCreate;
    _lastText = _entry.text;
    text = _entry.text;
    _textEditingController.addListener(() {
      text = _textEditingController.text;
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(seconds: 5), () {
        _saveEntry();
      });
    });
    setState(() {
      _loadingEntry = false;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentImages = List.empty(growable: true);
    for (var image in widget.images) {
      _currentImages.add(image.copy());
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
    _debounceTimer?.cancel();
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
                await _deleteEntry(_entry);
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
                    _currentImages.isEmpty) {
                  await _deleteEntry(_entry);
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
                      if (_currentImages.isNotEmpty)
                        EntryImageEditableList(
                            images: _currentImages,
                            onImagesChanged: (images) async {
                              _currentImages = images;
                              await _saveEntry();
                            }),
                      StatefulBuilder(
                        builder: (context, setState) => EntryMoodPicker(
                            actions: [
                              _changeDateButton(),
                              EntryImagePicker(
                                onChangedImage: (newImages) {
                                  _openedCamera = true;
                                  _addImage(newImages);
                                },
                                openCamera: widget.openCamera && !_openedCamera,
                              )
                            ],
                            moodValue: mood,
                            onChangedMood: (mood) {
                              setState(() => this.mood = mood);
                              EasyDebounce.debounce("save-entry",
                                  Duration(seconds: 5), () => _saveEntry());
                            }),
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

  Widget _changeDateButton() {
    final theme = Theme.of(context);
    final entriesProvider = Provider.of<EntriesProvider>(context);

    return TextButton.icon(
        icon: SvgPicture.asset(
          'assets/icons/calendar_event.svg',
          colorFilter:
              ColorFilter.mode(theme.colorScheme.primary, BlendMode.srcIn),
          width: 24,
          height: 24,
        ),
        onPressed: () async {
          DateTime? pickedDate = await showDatePicker(
            selectableDayPredicate: (date) =>
                entriesProvider.getEntryForDate(date) == null ||
                TimeManager.isSameDay(date, entryDate!),
            initialDatePickerMode: DatePickerMode.day,
            context: context,
            initialDate: entryDate,
            firstDate: DateTime.utc(2000),
            lastDate: DateTime.now(),
          );
          if (pickedDate != null) {
            entryDate = entryDate!.copyWith(
                year: pickedDate.year,
                month: pickedDate.month,
                day: pickedDate.day);
            await _saveEntry();
          }
        },
        label: Text(
          DateFormat.yMMMEd(TimeManager.currentLocale(context))
              .format(entryDate!),
          style: TextStyle(fontSize: 16),
        ));
  }

  Future<void> _saveEntry() async {
    // Saving is guarded since quickly entering and exiting the app could trigger
    // multiple async saves.
    if (_savingEntry == false) {
      _savingEntry = true;

      final updatedEntry = _entry.copy(
        text: text,
        mood: mood,
        timeCreate: entryDate,
        timeModified: DateTime.now(),
      );

      if (Platform.isAndroid &&
          TimeManager.isSameDay(DateTime.now(), updatedEntry.timeCreate)) {
        await NotificationManager.instance.dismissReminderNotification();
      }
      // Update if the text, mood, or date has changed
      if (updatedEntry.text != _lastText ||
          updatedEntry.mood != _lastMood ||
          updatedEntry.timeCreate != _lastEntryDate) {
        _lastText = updatedEntry.text;
        _lastMood = updatedEntry.mood;
        _lastEntryDate = updatedEntry.timeCreate;
        await EntriesProvider.instance.update(updatedEntry);
      }
      // Images will update if they changed
      await _saveOrUpdateImage(id);
      _savingEntry = false;
    }
  }

  Future _deleteEntry(Entry entry) async {
    // Delete entry images
    var entryImages = EntryImagesProvider.instance.getForEntry(entry);
    for (EntryImage image in entryImages) {
      await ImageStorage.instance.delete(image.imgPath);
      await EntryImagesProvider.instance.remove(image);
    }
    // Delete entry
    await EntriesProvider.instance.remove(entry);
  }

  Future _saveOrUpdateImage(int entryId) async {
    final savedImages = EntryImagesProvider.instance.getForEntry(_entry);
    // Add images
    for (EntryImage currentImage in _currentImages) {
      currentImage.entryId = entryId;
      if (currentImage.id == null ||
          savedImages.where((image) => image.id == currentImage.id!).isEmpty) {
        await EntryImagesProvider.instance.add(currentImage);
      }
    }
    // Update images
    for (EntryImage existingImage in savedImages) {
      EntryImage? matchingImage = _currentImages
          .where((image) => image.id == existingImage.id!)
          .firstOrNull;
      if (matchingImage == null) {
        // Delete image
        await ImageStorage.instance.delete(existingImage.imgPath);
        await EntryImagesProvider.instance.remove(existingImage);
      } else if (matchingImage.imgRank != existingImage.imgRank) {
        await EntryImagesProvider.instance.update(matchingImage);
      }
    }
    // Set current images to match saved state. Note: the entry images
    // are copied to avoid editing the originals in the provider.
    _currentImages.clear();
    for (var image in EntryImagesProvider.instance.getForEntry(_entry)) {
      _currentImages.add(image.copy());
    }
    setState(() {
      _currentImages;
    });
  }

  Future<void> _addImage(List<String> imgPaths) async {
    for (var imgPath in imgPaths) {
      // Add image to the end by giving it the lowest rank
      for (var image in _currentImages) {
        image.imgRank += 1;
      }
      _currentImages.add(EntryImage(
          entryId: id,
          imgPath: imgPath,
          imgRank: 0,
          timeCreate: DateTime.now()));
    }
    await _saveEntry();
  }
}
