import 'dart:async';
import 'dart:io';

import 'package:daily_you/database/entry_store.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/notification_manager.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
import 'package:daily_you/models/template.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/providers/templates_provider.dart';
import 'package:daily_you/widgets/entry_draft_dirty_tracker.dart';
import 'package:daily_you/widgets/tag_attachment_source.dart';
import 'package:daily_you/widgets/tag_grouped_chip_list.dart';
import 'package:daily_you/widgets/tag_picker_dialog.dart';
import 'package:daily_you/widgets/tag_chip.dart';
import 'package:daily_you/time_manager.dart';
import 'package:provider/provider.dart';
import 'package:daily_you/pages/full_screen_text_editor_page.dart';
import 'package:daily_you/widgets/editor_action_bar.dart';
import 'package:daily_you/widgets/editor_action_bar/editor_keyboard_session.dart';
import 'package:daily_you/widgets/entry_image_editable_list.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/widgets/entry_image_actions.dart';
import 'package:daily_you/widgets/entry_mood_picker.dart';
import 'package:daily_you/widgets/entry_text_edit.dart';
import 'package:daily_you/widgets/markdown_preview_controller.dart';

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
  static const double _pageWidth = 800;

  late Entry _entry;
  int id = -1;
  String text = "";
  int? mood;
  DateTime? entryDate;
  late List<EntryImage> _currentImages;
  bool _loadingEntry = true;
  bool _openedCamera = false;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final MarkdownPreviewController _textEditingController =
      MarkdownPreviewController();
  final UndoHistoryController _undoController = UndoHistoryController();
  bool _deletingEntry = false;
  bool _newEntry = false;
  bool _creatingNewEntry = false;
  late TagAttachmentSource _tagSource;
  late EntryDraftDirtyTracker _dirtyTracker;
  late final EntryDraftSession _draftSession = EntryStore.instance.beginDraft();

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
    _dirtyTracker = EntryDraftDirtyTracker(
      text: _entry.text,
      mood: _entry.mood,
      date: _entry.timeCreate,
      seededTagIds: _tagSource.attachedTagIds.toSet(),
    );
    _tagSource.addListener(_onTagsChanged);
    mood = _entry.mood;
    entryDate = _entry.timeCreate;
    text = _entry.text;
    _textEditingController.addListener(() {
      text = _textEditingController.text;
      _scheduleSave();
    });
    setState(() {
      _loadingEntry = false;
    });

    if (widget.openCamera && !_openedCamera) {
      _openedCamera = true;
      EntryImageActions.takePhoto(_addImage);
    }
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
    EasyDebounce.cancel("save-entry");
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
    if (_newEntry && !_hasNewEntryChanges()) {
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
                EasyDebounce.cancel("save-entry");
                final navigator = Navigator.of(context);
                if (_newEntry) {
                  // Persist so there is a saved entry (and any images) to delete
                  await _saveEntry();
                }
                final entryToDelete = _entry;
                // Pop dialog
                navigator.pop();
                // Pop edit page
                navigator.pop();
                if (!_creatingNewEntry && navigator.canPop()) {
                  // Pop view page
                  navigator.pop();
                }
                await EntryStore.instance.delete(entryToDelete);
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
    final keyboardInset = EditorActionBarOverlay.keyboardInsetOf(context);

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
                  actions: [_deleteButton(), _closeButton()]),
              body: EditorActionBarOverlay(
                keyboardInset: keyboardInset,
                body: LayoutBuilder(
                  builder: (context, constraints) {
                    final sidePadding =
                        ((constraints.maxWidth - _pageWidth) / 2)
                            .clamp(0.0, double.infinity);
                    final capPadding =
                        EdgeInsets.symmetric(horizontal: sidePadding);
                    return CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: capPadding,
                          sliver: SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        SliverPadding(
                          padding: capPadding,
                          sliver: _buildTextEditorSliver(context),
                        ),
                      ],
                    );
                  },
                ),
                actionBar: EditorActionBar(
                  controller: _textEditingController,
                  undoController: _undoController,
                  focusNode: _focusNode,
                  onTemplateInserted: _applyInsertedTemplateTags,
                  mainActions: _buildMainActions(context),
                ),
              ),
            ),
          );
  }

  // The card showing entry date/time, mood, and tags.
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
            child: _buildDateTimeButtons(context, theme),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
            child: EntryMoodPicker(
                moodValue: mood,
                onChangedMood: (mood) {
                  setLocalState(() => this.mood = mood);
                  _scheduleSave();
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
                        context, TimeManager.currentLocale(context))
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

  List<ToolbarAction> _buildMainActions(BuildContext context) {
    return [
      ToolbarAction(
        icon: const Icon(Icons.local_offer_rounded),
        onPressed: () => showDialog(
          context: context,
          builder: (_) =>
              TagPickerDialog(mode: TagPickerMode.attach, source: _tagSource),
        ),
      ),
      ToolbarAction(
        icon: const Icon(Icons.photo),
        mayLeaveApp: true,
        onPressed: () => EntryImageActions.pickFromGallery(_addImage),
      ),
      if (Platform.isAndroid)
        ToolbarAction(
          icon: const Icon(Icons.photo_camera_rounded),
          mayLeaveApp: true,
          onPressed: () => EntryImageActions.takePhoto(_addImage),
        ),
    ];
  }

  Widget _buildTextEditorSliver(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Builder(
        builder: (context) => GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            EditorKeyboardSessionScope.maybeOf(context)?.resume();
            _focusNode.requestFocus();
          },
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
                SizedBox(height: 16 + EditorActionBar.reservedHeight(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _deleteButton() => IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () => _showDeleteEntryPopup(),
      );

  Widget _closeButton() => IconButton(
        icon: Icon(
            _creatingNewEntry ? Icons.check_rounded : Icons.edit_off_rounded),
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

  void _scheduleSave() {
    EasyDebounce.debounce("save-entry", const Duration(seconds: 5), _saveEntry);
  }

  Future<void> _saveEntry() async {
    if (_newEntry && !_hasNewEntryChanges()) return;

    if ((_newEntry || _hasEntryFieldChanges()) &&
        Platform.isAndroid &&
        TimeManager.isSameDay(DateTime.now(), entryDate!)) {
      await NotificationManager.instance.dismissReminderNotification();
    }

    final saved = await _draftSession.save(_buildDraft);
    _adoptSavedEntry(saved);
    _adoptSavedImages(saved);
    if (mounted) {
      setState(() {});
    }
  }

  EntryDraft _buildDraft(Entry? saved) {
    if (saved != null) _adoptSavedEntry(saved);
    final entry = _hasEntryFieldChanges()
        ? _entry.copy(
            text: text,
            mood: mood,
            timeCreate: entryDate,
            timeModified: DateTime.now(),
          )
        : _entry;
    return EntryDraft(
      entry: entry,
      tags: _tagSource.toEntryTags(id),
      images: [for (final image in _currentImages) image.copy()],
    );
  }

  void _adoptSavedEntry(Entry saved) {
    _entry = saved;
    id = saved.id!;
    _newEntry = false;
    _dirtyTracker.markSaved(
      text: saved.text,
      mood: saved.mood,
      date: saved.timeCreate,
    );
  }

  void _adoptSavedImages(Entry saved) {
    final persistedIds = {
      for (final image in EntryImagesProvider.instance.getForEntry(saved))
        image.imgPath: image.id
    };
    _currentImages = [
      for (final image in _currentImages)
        image.copy(id: persistedIds[image.imgPath], entryId: saved.id)
    ];
  }

  bool _hasEntryFieldChanges() {
    return _dirtyTracker.hasFieldChanges(
        text: text, mood: mood, date: entryDate!);
  }

  void _onTagsChanged() {
    _scheduleSave();
  }

  bool _hasNewEntryChanges() {
    return _dirtyTracker.hasUnsavedChanges(
      text: text,
      mood: mood,
      date: entryDate!,
      tagSource: _tagSource,
      hasImages: _currentImages.isNotEmpty,
    );
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
