import 'package:daily_you/config_provider.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/pages/settings/tags_settings.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/widgets/edit_tag.dart';
import 'package:daily_you/widgets/entry_tag_chips.dart';
import 'package:daily_you/widgets/tag_chip.dart';
import 'package:daily_you/widgets/tag_grouped_chip_list.dart';
import 'package:daily_you/widgets/tracker_value_dialog.dart';
import 'package:daily_you/utils/tag_name_sanitizer.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

enum TagPickerMode { addToEntry, selectSingle, filter }

enum TagFilterMode { all, any }

class TagPickerDialog extends StatefulWidget {
  final TagPickerMode mode;

  // addToEntry
  final int? entryId;

  // filter
  final List<int> initialSelectedTagIds;
  final TagFilterMode initialFilterMode;
  final bool initialNoTagsOnly;
  final void Function(List<int>, TagFilterMode, bool)? onFilterChanged;

  final TagType? tagTypeFilter;

  const TagPickerDialog({
    super.key,
    required this.mode,
    this.entryId,
    this.initialSelectedTagIds = const [],
    this.initialFilterMode = TagFilterMode.any,
    this.initialNoTagsOnly = false,
    this.onFilterChanged,
    this.tagTypeFilter,
  });

  @override
  State<TagPickerDialog> createState() => _TagPickerDialogState();
}

class _TagPickerDialogState extends State<TagPickerDialog> {
  final TagNameEditingController _searchController = TagNameEditingController();
  String _searchText = '';
  late String _sortMode;

  // filter mode state
  late List<int> _selectedTagIds;
  late TagFilterMode _filterMode;
  late bool _noTagsOnly;

  @override
  void initState() {
    super.initState();
    _selectedTagIds = List.from(widget.initialSelectedTagIds);
    _filterMode = widget.initialFilterMode;
    _noTagsOnly = widget.initialNoTagsOnly;
    _sortMode =
        ConfigProvider.instance.get(ConfigKey.tagPickerSortMode) ?? 'manual';
    _searchController.addListener(() {
      setState(() => _searchText = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSortMode() {
    final newMode = _sortMode == 'manual' ? 'usage' : 'manual';
    setState(() => _sortMode = newMode);
    ConfigProvider.instance.set(ConfigKey.tagPickerSortMode, newMode);
  }

  // addToEntry mode helpers

  Future<void> _addLabelTag(TagsProvider provider, Tag tag) async {
    await provider.addEntryTag(EntryTag(
      entryId: widget.entryId!,
      tagId: tag.id!,
      timeCreate: DateTime.now(),
    ));
  }

  Future<void> _addTrackerTag(TagsProvider provider, Tag tag) async {
    final value = await showTrackerValueDialog(context, tag);
    if (value == null) return;
    await provider.addEntryTag(EntryTag(
      entryId: widget.entryId!,
      tagId: tag.id!,
      value: value,
      timeCreate: DateTime.now(),
    ));
  }

  Future<void> _editTrackerValue(
      TagsProvider provider, EntryTag entryTag, Tag tag) async {
    final value = await showTrackerValueDialog(context, tag,
        initialValue: entryTag.value);
    if (value == null) return;
    await provider.updateEntryTag(entryTag.copy(value: value));
  }

  Future<void> _createAndAddTagWithName(
      TagsProvider provider, String name) async {
    final tagsBefore = List<Tag>.from(provider.tags);
    await showDialog(
      context: context,
      builder: (_) => EditTag(tag: null, initialName: name),
    );
    final newTag = provider.tags
        .where((tag) =>
            tagsBefore.every((existingTag) => existingTag.id != tag.id))
        .firstOrNull;
    if (newTag == null) return;

    _searchController.clear();

    if (widget.mode == TagPickerMode.addToEntry) {
      final alreadyAdded = provider
          .getEntryTagsForEntry(widget.entryId!)
          .any((entryTag) => entryTag.tagId == newTag.id);
      if (alreadyAdded) return;

      if (newTag.tagType == TagType.tracker) {
        if (context.mounted) await _addTrackerTag(provider, newTag);
      } else {
        await _addLabelTag(provider, newTag);
      }
    }
  }

  // filter mode helpers

  void _notifyFilter() {
    widget.onFilterChanged?.call(_selectedTagIds, _filterMode, _noTagsOnly);
  }

  void _addFilterTag(int tagId) {
    setState(() => _selectedTagIds.add(tagId));
    _notifyFilter();
  }

  void _removeFilterTag(int tagId) {
    setState(() => _selectedTagIds.remove(tagId));
    _notifyFilter();
  }

  void _setNoTagsOnly(bool value) {
    setState(() {
      _noTagsOnly = value;
      if (value) {
        _selectedTagIds = [];
        _filterMode = TagFilterMode.any;
      }
    });
    _notifyFilter();
  }

  void _clearAllFilters() {
    setState(() {
      _selectedTagIds = [];
      _filterMode = TagFilterMode.any;
      _noTagsOnly = false;
    });
    _notifyFilter();
    Navigator.of(context).pop();
  }

  // builders

  Widget _buildAddedChips(TagsProvider provider) {
    return EntryTagChips(
      entryId: widget.entryId!,
      padding: const EdgeInsets.only(bottom: 8),
      chipBuilder: (tag, entryTag) => TagChip(
        tag: tag,
        value: entryTag.value,
        onTap: tag.tagType == TagType.tracker
            ? () => _editTrackerValue(provider, entryTag, tag)
            : null,
        onRemove: () => provider.removeEntryTag(entryTag),
      ),
    );
  }

  Widget _buildFilterSelectedChips(TagsProvider provider) {
    if (_selectedTagIds.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: _selectedTagIds.map((tagId) {
          final tag = provider.tags
              .where((candidate) => candidate.id == tagId)
              .firstOrNull;
          if (tag == null) return const SizedBox.shrink();
          return TagChip(tag: tag, onRemove: () => _removeFilterTag(tagId));
        }).toList(),
      ),
    );
  }

  Widget _buildFilterModeToggle(BuildContext context) {
    if (_selectedTagIds.length < 2) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SegmentedButton<TagFilterMode>(
        segments: [
          ButtonSegment(
            value: TagFilterMode.any,
            label: Text(l10n.tagFilterModeAny),
          ),
          ButtonSegment(
            value: TagFilterMode.all,
            label: Text(l10n.tagFilterModeAll),
          ),
        ],
        selected: {_filterMode},
        onSelectionChanged: (selected) {
          setState(() => _filterMode = selected.first);
          _notifyFilter();
        },
      ),
    );
  }

  Widget _buildNoTagsToggle(AppLocalizations l10n) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.noTagsFilterLabel,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(width: 4),
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: _noTagsOnly,
            onChanged: _setNoTagsOnly,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(AppLocalizations l10n, TagsProvider provider) {
    final showAdd = _searchText.isNotEmpty &&
        widget.mode == TagPickerMode.addToEntry &&
        !provider.tags
            .any((tag) => tag.name.toLowerCase() == _searchText.toLowerCase());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SearchBar(
        controller: _searchController,
        hintText: l10n.addTagsSearchHint,
        elevation: const WidgetStatePropertyAll(0),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.only(left: 4, right: 4),
        ),
        backgroundColor: WidgetStatePropertyAll(
          Theme.of(context).colorScheme.secondaryContainer,
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            Icons.search_rounded,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        trailing: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) {
              final scale = TweenSequence([
                TweenSequenceItem(
                  tween: Tween<double>(begin: 0.0, end: 1.1)
                      .chain(CurveTween(curve: Curves.easeOut)),
                  weight: 60,
                ),
                TweenSequenceItem(
                  tween: Tween<double>(begin: 1.1, end: 1.0)
                      .chain(CurveTween(curve: Curves.easeIn)),
                  weight: 40,
                ),
              ]).animate(animation);
              return ScaleTransition(scale: scale, child: child);
            },
            child: showAdd
                ? IconButton(
                    key: const ValueKey('addButton'),
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () => _createAndAddTagWithName(
                        provider, sanitizeTagName(_searchController.text)),
                  )
                : const SizedBox.shrink(key: ValueKey('empty')),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) {
              if (value != _sortMode) _toggleSortMode();
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'manual',
                child: Row(children: [
                  Icon(Icons.check_rounded,
                      size: 18,
                      color: _sortMode == 'manual'
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent),
                  const SizedBox(width: 8),
                  Text(l10n.tagPickerSortManualLabel),
                ]),
              ),
              PopupMenuItem<String>(
                value: 'usage',
                child: Row(children: [
                  Icon(Icons.check_rounded,
                      size: 18,
                      color: _sortMode == 'usage'
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent),
                  const SizedBox(width: 8),
                  Text(l10n.tagPickerSortUsageLabel),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<TagsProvider>(
      builder: (context, provider, _) {
        // Available pool excludes tags already selected/added
        final List<int> excludedIds;
        if (widget.mode == TagPickerMode.addToEntry) {
          excludedIds = provider
              .getEntryTagsForEntry(widget.entryId!)
              .map((entryTag) => entryTag.tagId)
              .toList();
        } else if (widget.mode == TagPickerMode.filter) {
          excludedIds = _selectedTagIds;
        } else {
          excludedIds = [];
        }

        List<Tag> pool;
        bool typeMatch(Tag tag) =>
            widget.tagTypeFilter == null || tag.tagType == widget.tagTypeFilter;

        if (_sortMode == 'usage') {
          pool = provider.tags
              .where((tag) => !excludedIds.contains(tag.id) && typeMatch(tag))
              .toList()
            ..sort((a, b) {
              final countA = provider.entryTags
                  .where((entryTag) => entryTag.tagId == a.id)
                  .length;
              final countB = provider.entryTags
                  .where((entryTag) => entryTag.tagId == b.id)
                  .length;
              return countB.compareTo(countA);
            });
        } else {
          pool = provider.tags
              .where((tag) => !excludedIds.contains(tag.id) && typeMatch(tag))
              .toList();
        }

        final sections = provider.buildSections(_searchText, tagPool: pool);

        final String title;
        switch (widget.mode) {
          case TagPickerMode.addToEntry:
            title = l10n.addTagsTitle;
          case TagPickerMode.selectSingle:
            title = l10n.selectTagTitle;
          case TagPickerMode.filter:
            title = l10n.filterTagsTitle;
        }

        final titleWidget = widget.mode == TagPickerMode.filter
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
                  _buildNoTagsToggle(l10n),
                ],
              )
            : Text(title);

        return AlertDialog(
          title: titleWidget,
          contentPadding: widget.mode == TagPickerMode.selectSingle
              ? const EdgeInsets.fromLTRB(24, 16, 24, 0)
              : null,
          content: SizedBox(
            width: double.maxFinite,
            child: _buildContent(context, l10n, provider, sections),
          ),
          actions: _buildActions(context, l10n, provider),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    TagsProvider provider,
    List<TagSection> sections,
  ) {
    if (widget.mode == TagPickerMode.selectSingle) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchField(l10n, provider),
          const SizedBox(height: 8),
          if (sections.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(l10n.noResults),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                child: TagGroupedChipList(
                  sections: sections,
                  chipBuilder: (tag) => TagChip(
                    tag: tag,
                    onTap: () => Navigator.of(context).pop(tag),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return SingleChildScrollView(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _noTagsOnly ? 0.3 : 1.0,
        child: IgnorePointer(
          ignoring: _noTagsOnly,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.mode == TagPickerMode.addToEntry)
                _buildAddedChips(provider),
              if (widget.mode == TagPickerMode.filter) ...[
                _buildFilterSelectedChips(provider),
                _buildFilterModeToggle(context),
              ],
              _buildSearchField(l10n, provider),
              const SizedBox(height: 8),
              TagGroupedChipList(
                sections: sections,
                chipBuilder: (tag) => TagChip(
                  tag: tag,
                  onTap: () async {
                    if (widget.mode == TagPickerMode.addToEntry) {
                      if (tag.tagType == TagType.tracker) {
                        await _addTrackerTag(provider, tag);
                      } else {
                        await _addLabelTag(provider, tag);
                      }
                    } else {
                      _addFilterTag(tag.id!);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActions(
      BuildContext context, AppLocalizations l10n, TagsProvider provider) {
    final close = TextButton(
      onPressed: () => Navigator.of(context).pop(),
      child: Text(MaterialLocalizations.of(context).closeButtonLabel),
    );

    final manageTags = TextButton(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TagsSettings()),
      ),
      child: Text(l10n.manageTags),
    );

    switch (widget.mode) {
      case TagPickerMode.addToEntry:
        return [manageTags, close];
      case TagPickerMode.selectSingle:
        return [close];
      case TagPickerMode.filter:
        return [
          TextButton(
            onPressed: _clearAllFilters,
            child: Text(l10n.clearAllFilters),
          ),
          close,
        ];
    }
  }
}
