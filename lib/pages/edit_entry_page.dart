import 'dart:async';
import 'dart:io';

import 'package:daily_you/database/image_storage.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/notification_manager.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
import 'package:daily_you/models/template.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/providers/templates_provider.dart';
import 'package:daily_you/widgets/tag_attachment_source.dart';
import 'package:daily_you/widgets/tag_grouped_chip_list.dart';
import 'package:daily_you/widgets/tag_picker_dialog.dart';
import 'package:daily_you/widgets/tag_chip.dart';
import 'package:daily_you/time_manager.dart';
import 'package:provider/provider.dart';
import 'package:daily_you/pages/full_screen_text_editor_page.dart';
import 'package:daily_you/widgets/edit_toolbar.dart';
import 'package:daily_you/widgets/entry_image_editable_list.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
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
  bool _creatingNewEntry = false;
  Timer? _debounceTimer;
  late TagAttachmentSource _tagSource;
  // Tag ids seeded from the default template, or already on the entry
  late Set<int> _seededTagIds;

  Future<void> _initEntry() async {
    if (widget.entry == null) {
      var createTime =
          (TimeManager.isToday(widget.overrideCreateDate ?? DateTime.now()))
              ? DateTime.now()
              : (widget.overrideCreateDate ?? DateTime.now());
      var text = "";
      final defaultTemplate = TemplatesProvider.instance.getDefaultTemplate();
      final defaultTagIds = <int>[];
      if (defaultTemplate != null) {
        text = defaultTemplate.text ?? "";
        defaultTagIds.addAll(TagsProvider.instance
            .getTemplateTagsForTemplate(defaultTemplate.id!)
            .map((templateTag) => templateTag.tagId));
      }
      _tagSource = TagAttachmentSource(
          supportsValues: true, initialTagIds: defaultTagIds);
      _entry = Entry(
        text: text,
        mood: null,
        timeCreate: createTime,
        timeModified: DateTime.now(),
      );
      _newEntry = true;
      _creatingNewEntry = true;
      id = -1;
    } else {
      _entry = widget.entry!;
      id = _entry.id ?? -1;
      _tagSource = TagAttachmentSource.fromEntryTags(
          TagsProvider.instance.getEntryTagsForEntry(id));
    }
    _seededTagIds = _tagSource.attachedTagIds.toSet();
    _tagSource.addListener(_onTagsChanged);
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
    _tagSource.removeListener(_onTagsChanged);
    _tagSource.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden) {
      _saveEntry();
    }
  }

  Future<void> _openFullScreenEditor() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        allowSnapshotting: false,
        builder: (context) => FullScreenTextEditorPage(
          initialText: _textEditingController.text,
        ),
      ),
    );
    if (result != null) {
      _textEditingController.text = result;
    }
  }

  void _showDeleteEntryPopup() {
    if (_newEntry) {
      Navigator.of(context).pop();
      return;
    }
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
                // Pop dialog
                Navigator.of(context).pop();
                // Pop edit page
                Navigator.of(context).pop();
                if (!_creatingNewEntry && Navigator.of(context).canPop()) {
                  // Pop view page
                  Navigator.of(context).pop();
                }
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _loadingEntry
        ? Scaffold()
        : PopScope(
            onPopInvokedWithResult: (didPop, result) async {
              if (!_deletingEntry) {
                await _saveEntry();
              }
            },
            child: Scaffold(
              appBar: AppBar(
                  leading: BackButton(
                    onPressed: () {
                      // Pop edit page
                      Navigator.of(context).pop();
                      if (!_creatingNewEntry &&
                          Navigator.of(context).canPop()) {
                        // Pop view page
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  actions: [_deleteButton(), _saveButton()]),
              body: Column(
                children: [
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 800),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (_currentImages.isNotEmpty)
                                      EntryImageEditableList(
                                          images: _currentImages,
                                          onImagesChanged: (images) async {
                                            _currentImages = images;
                                            await _saveEntry();
                                          }),
                                    StatefulBuilder(
                                      builder: (context, setLocalState) =>
                                          _buildMetadataCard(
                                              context, theme, setLocalState),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        _buildTextEditorSliver(),
                      ],
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: EditToolbar(
                      controller: _textEditingController,
                      undoController: _undoController,
                      focusNode: _focusNode,
                      onTemplateInserted: _applyInsertedTemplateTags,
                      trailer: _buildTagsButton(context, theme),
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  // The card showing entry date/time, tag/image actions, mood, and tags.
  // setLocalState is the StatefulBuilder's setter, so a mood change only
  // rebuilds this card instead of the whole scroll view.
  Widget _buildMetadataCard(
    BuildContext context,
    ThemeData theme,
    StateSetter setLocalState,
  ) {
    return Card.filled(
      color: theme.colorScheme.surfaceContainer,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.start,
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 8.0,
              children: [
                _buildDateTimeButtons(context, theme),
                _buildImageButton(context, theme),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
            child: EntryMoodPicker(
                moodValue: mood,
                onChangedMood: (mood) {
                  setLocalState(() => this.mood = mood);
                  EasyDebounce.debounce(
                      "save-entry", Duration(seconds: 5), () => _saveEntry());
                }),
          ),
          _buildTagChips(),
        ],
      ),
    );
  }

  Widget _buildTagChips() {
    const padding = EdgeInsets.only(left: 8, right: 8, bottom: 8);
    return ListenableBuilder(
      listenable: _tagSource,
      builder: (context, _) {
        final attachedIds = _tagSource.attachedTagIds;
        if (attachedIds.isEmpty) return const SizedBox.shrink();
        final tagsProvider = Provider.of<TagsProvider>(context);
        final attachedSet = attachedIds.toSet();
        final tagPool = tagsProvider.tags
            .where((tag) => attachedSet.contains(tag.id))
            .toList();
        final sections = tagsProvider.buildSections('', tagPool: tagPool);
        return Padding(
          padding: padding,
          child: TagGroupedChipList(
            sections: sections,
            chipBuilder: (tag) => TagChip(
              tag: tag,
              value: _tagSource.valueFor(tag.id!),
              onTap: tag.tagType == TagType.tracker
                  ? () => _tagSource.editValue(context, tag)
                  : null,
              onRemove: () => _tagSource.detach(tag.id!),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateTimeButtons(BuildContext context, ThemeData theme) {
    return IntrinsicHeight(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () async {
                _chooseDate();
              },
              style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.all(6)),
              child: Text(
                TimeManager.formatDateWithWeekday(entryDate!, context),
                style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
            VerticalDivider(
              width: 6,
              indent: 8,
              endIndent: 8,
              thickness: 2,
              radius: BorderRadius.circular(4),
            ),
            TextButton(
              onPressed: () async {
                _chooseTime();
              },
              style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.all(6)),
              child: Text(
                TimeManager.localizedTimeFormat(
                        TimeManager.currentLocale(context))
                    .format(entryDate!),
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageButton(BuildContext context, ThemeData theme) {
    return EntryImagePicker(
      onChangedImage: (newImages) {
        _openedCamera = true;
        _addImage(newImages);
      },
      openCamera: widget.openCamera && !_openedCamera,
    );
  }

  Widget _buildTagsButton(BuildContext context, ThemeData theme) {
    return IconButton(
      onPressed: () async {
        await showDialog(
          context: context,
          builder: (_) =>
              TagPickerDialog(mode: TagPickerMode.attach, source: _tagSource),
        );
      },
      icon: Icon(
        Icons.local_offer_rounded,
        color: theme.colorScheme.primary,
        size: 24,
      ),
      style: IconButton.styleFrom(
          backgroundColor: theme.colorScheme.primaryContainer),
    );
  }

  Widget _buildTextEditorSliver() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => _focusNode.requestFocus(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: StatefulBuilder(
                          builder: (context, setState) => EntryTextEditor(
                            text: text,
                            focusNode: _focusNode,
                            textEditingController: _textEditingController,
                            undoHistoryController: _undoController,
                            onExpand: _openFullScreenEditor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _deleteButton() => IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () => _showDeleteEntryPopup(),
      );

  Widget _saveButton() => IconButton(
        icon: const Icon(Icons.check_rounded),
        onPressed: () => Navigator.of(context).pop(),
      );

  Future<void> _chooseDate() async {
    DateTime? pickedDate = await TimeManager.pickDate(
      context,
      initialDate: entryDate!,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate == null) return;

    entryDate = entryDate!.copyWith(
      year: pickedDate.year,
      month: pickedDate.month,
      day: pickedDate.day,
    );
    await _saveEntry();
  }

  Future<void> _chooseTime() async {
    final pickedTime = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(entryDate!));
    if (pickedTime == null) return;

    entryDate = entryDate!.copyWith(
      hour: pickedTime.hour,
      minute: pickedTime.minute,
    );
    await _saveEntry();
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

      final hasTextChange = updatedEntry.text != _lastText;
      final hasMoodChange = updatedEntry.mood != _lastMood;
      final hasDateChange = updatedEntry.timeCreate != _lastEntryDate;

      final hasTagChange = _tagsExceedSeed();

      if (_newEntry) {
        if (hasTextChange ||
            hasMoodChange ||
            hasDateChange ||
            hasTagChange ||
            _currentImages.isNotEmpty) {
          if (Platform.isAndroid &&
              TimeManager.isSameDay(DateTime.now(), updatedEntry.timeCreate)) {
            await NotificationManager.instance.dismissReminderNotification();
          }
          _entry = await EntriesProvider.instance.add(updatedEntry);
          id = _entry.id!;
          _newEntry = false;
          _lastText = _entry.text;
          _lastMood = _entry.mood;
          _lastEntryDate = _entry.timeCreate;
          await TagsProvider.instance
              .setEntryTags(id, _tagSource.toEntryTags(id));
        }
      } else {
        if (hasTextChange || hasMoodChange || hasDateChange) {
          if (Platform.isAndroid &&
              TimeManager.isSameDay(DateTime.now(), updatedEntry.timeCreate)) {
            await NotificationManager.instance.dismissReminderNotification();
          }
          _lastText = updatedEntry.text;
          _lastMood = updatedEntry.mood;
          _lastEntryDate = updatedEntry.timeCreate;
          await EntriesProvider.instance.update(updatedEntry);
        }
        await TagsProvider.instance
            .setEntryTags(id, _tagSource.toEntryTags(id));
      }
      // Images will update if they changed
      await _saveOrUpdateImage(id);
      _savingEntry = false;
    }
  }

  Future _deleteEntry(Entry entry) async {
    var entryImages = EntryImagesProvider.instance.getForEntry(entry);
    for (EntryImage image in entryImages) {
      await ImageStorage.instance.delete(image.imgPath);
      await EntryImagesProvider.instance.remove(image);
    }
    await TagsProvider.instance.removeAllEntryTagsForEntry(entry.id!);
    await EntriesProvider.instance.remove(entry);
  }

  Future _saveOrUpdateImage(int entryId) async {
    if (entryId == -1 || _entry.id == null) return;
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
    if (mounted) {
      setState(() {});
    }
  }

  void _onTagsChanged() {
    EasyDebounce.debounce(
        "save-entry", const Duration(seconds: 5), () => _saveEntry());
  }

  // Whether the working set holds anything beyond the seeded default tags
  bool _tagsExceedSeed() {
    for (final tagId in _tagSource.attachedTagIds) {
      if (!_seededTagIds.contains(tagId)) return true;
      if (_tagSource.valueFor(tagId) != null) return true;
    }
    return false;
  }

  void _applyInsertedTemplateTags(Template template) {
    if (template.id == null) return;
    final templateTagIds = TagsProvider.instance
        .getTemplateTagsForTemplate(template.id!)
        .map((templateTag) => templateTag.tagId);
    for (final tagId in templateTagIds) {
      _tagSource.addTagId(tagId);
    }
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
