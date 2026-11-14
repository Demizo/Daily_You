// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/entry_sort.dart';
import 'package:daily_you/models/gallery_filter.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/providers/gallery_selection.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/utils/gallery_entry_actions.dart';
import 'package:daily_you/widgets/gallery_action_menu.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/drag_select_region.dart';
import 'package:daily_you/widgets/entry_card_widget.dart';
import 'package:daily_you/widgets/crossfade_on_change.dart';
import 'package:daily_you/widgets/gallery_header.dart';
import 'package:daily_you/widgets/gallery_invite.dart';
import 'package:daily_you/pages/edit_entry_page.dart';
import 'package:daily_you/widgets/hide_semantics_while_dragging.dart';
import 'package:daily_you/widgets/hiding_widget.dart';
import 'package:daily_you/widgets/large_entry_card_widget.dart';
import 'package:daily_you/widgets/selectable_entry_card.dart';
import 'package:daily_you/widgets/tag_picker_dialog.dart';
import 'package:material_ui/material_ui.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/pages/entries_list_page.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:provider/provider.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage>
    with AutomaticKeepAliveClientMixin {
  static const String _searchDebounceTag = 'search-debounce';
  static const double _endSpacing = 70;
  static const double _inviteMinimumFraction = 0.3;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _partialMatchesKey = GlobalKey();
  final FocusNode _focusNode = FocusNode();
  bool _isScrolledUnder = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _searchController.text = EntriesProvider.instance.searchText;
    _scrollController.addListener(_onScrolled);
    GallerySelection.instance.addListener(_focusWhileSelecting);
  }

  @override
  void dispose() {
    GallerySelection.instance.removeListener(_focusWhileSelecting);
    _focusNode.dispose();
    EasyDebounce.cancel(_searchDebounceTag);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScrolled() {
    final isScrolledUnder = _scrollController.position.pixels > 0;
    if (isScrolledUnder == _isScrolledUnder) return;
    setState(() => _isScrolledUnder = isScrolledUnder);
  }

  void _onSearchChanged(String queryText) => EasyDebounce.debounce(
        _searchDebounceTag,
        const Duration(milliseconds: 300),
        () => EntriesProvider.instance.searchText = queryText,
      );

  void _clearSearchText() {
    EasyDebounce.cancel(_searchDebounceTag);
    _searchController.clear();
    EntriesProvider.instance.searchText = '';
  }

  void _clearAll() {
    EasyDebounce.cancel(_searchDebounceTag);
    _searchController.clear();
    EntriesProvider.instance.filter = const GalleryFilter();
  }

  void _scrollToPartialMatches() {
    final sliver = _partialMatchesKey.currentContext?.findRenderObject();
    if (sliver is! RenderSliver || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    position.animateTo(
      math.min(
          sliver.constraints.precedingScrollExtent, position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _focusWhileSelecting() {
    if (!GallerySelection.instance.active || _isEditingText()) return;
    _focusNode.requestFocus();
  }

  bool _isEditingText() =>
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<EditableText>() !=
      null;

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    final selection = GallerySelection.instance;
    if (!selection.active || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      selection.clear();
      return KeyEventResult.handled;
    }
    if (_isEditingText()) return KeyEventResult.ignored;
    final keyboard = HardwareKeyboard.instance;
    if (event.logicalKey == LogicalKeyboardKey.keyA &&
        (keyboard.isControlPressed || keyboard.isMetaPressed)) {
      selectAllEntries(context, selection);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.delete) {
      deleteSelectedEntries(context, selection);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _writeNewLog() {
    return Navigator.of(context).push(MaterialPageRoute(
        allowSnapshotting: false,
        builder: (context) => const AddEditEntryPage(
              entry: null,
              openCamera: false,
              attachments: [],
            )));
  }

  Future<void> _openEntry(int index) async {
    GallerySelection.instance.clear();
    await Navigator.of(context).push(MaterialPageRoute(
        allowSnapshotting: false,
        builder: (context) => EntriesListPage(
              index: index,
              getEntries: () => EntriesProvider.instance.getFilteredEntries(),
            )));
  }

  void _onEntryTapped(Entry entry, int index) {
    final selection = GallerySelection.instance;
    if (!selection.active) {
      _openEntry(index);
    } else if (HardwareKeyboard.instance.isShiftPressed) {
      selection.selectRange(entry.id!);
    } else {
      selection.toggle(entry.id!);
    }
  }

  void _onDragSelectStarted(int entryId) {
    HapticFeedback.mediumImpact();
    GallerySelection.instance.beginDrag(entryId);
  }

  Future<void> _showEntryMenu(Entry entry, int index, Offset position) async {
    final l10n = AppLocalizations.of(context)!;
    final selection = GallerySelection.instance;
    final shareAction = shareSelectionAction(context, selection);
    final actions = selection.isSelected(entry.id!)
        ? [
            if (shareAction != null) shareAction,
            ...selectionActions(context, selection)
          ]
        : [
            GalleryAction(
              label: l10n.gallerySelectAction,
              icon: const Icon(Icons.check_circle_outline_rounded),
              onPressed: () => selection.toggle(entry.id!),
            ),
            GalleryAction(
              label: l10n.galleryOpenAction,
              icon: const Icon(Icons.open_in_new_rounded),
              onPressed: () => _openEntry(index),
            ),
            GalleryAction(
              label: l10n.settingsExport,
              icon: const Icon(Icons.file_download_outlined),
              onPressed: () => exportEntries(context, [entry]),
            ),
            GalleryAction(
              label: l10n.deleteTitle,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => deleteEntries(context, [entry]),
            ),
          ];
    final overlaySize = Overlay.of(context).context.size!;
    final chosen = await showMenu<GalleryAction>(
      context: context,
      position: RelativeRect.fromRect(
          position & Size.zero, Offset.zero & overlaySize),
      shape: galleryMenuShape,
      items: galleryMenuItems(actions),
    );
    chosen?.onPressed();
  }

  void _showSortSelectionPopup(BuildContext context) {
    final entriesProvider =
        Provider.of<EntriesProvider>(context, listen: false);
    final tagsProvider = Provider.of<TagsProvider>(context, listen: false);
    showAppDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          final trackerTag = entriesProvider.trackerSortTagId != null
              ? tagsProvider.tags
                  .where((tag) => tag.id == entriesProvider.trackerSortTagId)
                  .firstOrNull
              : null;

          Future<void> handleTrackerTap() async {
            final previousOrderBy = entriesProvider.orderBy;
            setDialogState(() => entriesProvider.orderBy = OrderBy.tracker);

            final tag = await showAppDialog<Tag>(
              context: context,
              builder: (_) => TagPickerDialog(
                mode: TagPickerMode.selectSingle,
                tagTypeFilter: TagType.tracker,
              ),
            );

            if (tag != null) {
              setDialogState(() => entriesProvider.trackerSortTagId = tag.id);
            } else if (previousOrderBy != OrderBy.tracker) {
              setDialogState(() => entriesProvider.orderBy = previousOrderBy);
            }
          }

          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioGroup<OrderBy>(
                  groupValue: entriesProvider.orderBy,
                  onChanged: (value) {
                    final tappedTracker = value == OrderBy.tracker ||
                        (value == null &&
                            entriesProvider.orderBy == OrderBy.tracker);
                    if (tappedTracker) {
                      handleTrackerTap();
                    } else if (value != null) {
                      setDialogState(() {
                        entriesProvider.orderBy = value;
                        entriesProvider.trackerSortTagId = null;
                      });
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<OrderBy>(
                        value: OrderBy.date,
                        title:
                            Text(AppLocalizations.of(context)!.sortDateTitle),
                      ),
                      RadioListTile<OrderBy>(
                        value: OrderBy.mood,
                        title: Text(AppLocalizations.of(context)!.tagMoodTitle),
                      ),
                      RadioListTile<OrderBy>(
                        value: OrderBy.tracker,
                        toggleable: true,
                        title: Text(
                            AppLocalizations.of(context)!.tagTypeTrackerTitle),
                        subtitle: trackerTag != null
                            ? Text(
                                trackerTag.name,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.fade,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
                const Divider(),
                RadioGroup<SortOrder>(
                  groupValue: entriesProvider.sortOrder,
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => entriesProvider.sortOrder = value);
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<SortOrder>(
                        value: SortOrder.ascending,
                        title: Text(AppLocalizations.of(context)!
                            .sortOrderAscendingTitle),
                      ),
                      RadioListTile<SortOrder>(
                        value: SortOrder.descending,
                        title: Text(AppLocalizations.of(context)!
                            .sortOrderDescendingTitle),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final entriesProvider = Provider.of<EntriesProvider>(context);
    final configProvider = Provider.of<ConfigProvider>(context);
    final listView = configProvider.get(Settings.galleryPageViewMode) == 'list';
    final entries = entriesProvider.getFilteredEntries();
    final isFiltering = entriesProvider.filter.isActive;
    if (entries.isEmpty) _isScrolledUnder = false;
    final partialMatchCount = entriesProvider.partialMatchCount;
    return SafeArea(
        top: false,
        bottom: false,
        child: Focus(
            focusNode: _focusNode,
            skipTraversal: true,
            onKeyEvent: _onKeyEvent,
            child: Stack(
              children: [
                Column(
                  children: [
                    GalleryHeader(
                      searchController: _searchController,
                      onSearchChanged: _onSearchChanged,
                      onSearchCleared: _clearSearchText,
                      onClearAll: _clearAll,
                      onSortPressed: () => _showSortSelectionPopup(context),
                      resultCount: isFiltering
                          ? entries.length - partialMatchCount
                          : null,
                      partialMatchCount: partialMatchCount,
                      onPartialMatchesPressed: _scrollToPartialMatches,
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CrossfadeOnChange(
                              changeKey: (
                                entriesProvider.filter,
                                entriesProvider.orderBy,
                                entriesProvider.sortOrder,
                                entriesProvider.trackerSortTagId,
                              ),
                              child: entries.isEmpty
                                  ? _buildEmptyState(context, isFiltering)
                                  : _buildEntries(
                                      context,
                                      listView,
                                      entries,
                                      entriesProvider,
                                    ),
                            ),
                          ),
                          GalleryHeaderEdge(isElevated: _isScrolledUnder),
                        ],
                      ),
                    ),
                  ],
                ),
                if (entries.isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: HidingWidget(
                      scrollController: _scrollController,
                      duration: const Duration(milliseconds: 200),
                      hideDirection: HideDirection.down,
                      shouldShow: () {
                        return _scrollController.position.pixels >= 500;
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: FloatingActionButton(
                              heroTag: "gallery-jump-to-top-button",
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              elevation: 1,
                              child: Icon(
                                Icons.arrow_upward_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: 28,
                              ),
                              onPressed: () async {
                                _scrollController.position.animateTo(0,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            )));
  }

  Widget _buildEmptyState(BuildContext context, bool isFiltering) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    if (!isFiltering) {
      return GalleryInvite(onPressed: _writeNewLog);
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_search_rounded,
            size: 96,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noResults,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _clearAll,
            child: Text(l10n.clearAllFilters),
          ),
        ],
      ),
    );
  }

  List<EntryAttachment> _visualAttachmentsOf(
      EntryAttachmentsProvider provider, Entry entry) {
    return provider
        .getForEntry(entry)
        .where((attachment) => attachment.type.isVisual)
        .toList();
  }

  Widget _buildPartialMatchesHeader(BuildContext context, int count) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverToBoxAdapter(
      key: _partialMatchesKey,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 8),
        child: Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                AppLocalizations.of(context)!.partialMatchCount(count),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
      ),
    );
  }

  Widget _buildInvite() => SliverLayoutBuilder(
        builder: (context, constraints) {
          final viewport = constraints.viewportMainAxisExtent;
          final available =
              viewport - constraints.precedingScrollExtent - _endSpacing;
          if (available < viewport * _inviteMinimumFraction) {
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          }
          return SliverToBoxAdapter(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: available),
              child: GalleryInvite(onPressed: _writeNewLog),
            ),
          );
        },
      );

  Widget _buildEntries(
    BuildContext context,
    bool listView,
    List<Entry> entries,
    EntriesProvider entriesProvider,
  ) {
    final entryAttachmentsProvider =
        Provider.of<EntryAttachmentsProvider>(context);
    final configProvider = Provider.of<ConfigProvider>(context);
    final searchText = entriesProvider.searchText;
    final largeCards = listView || searchText.isNotEmpty;
    final partialMatchCount = entriesProvider.partialMatchCount;
    final firstTierEnd = entries.length - partialMatchCount;

    Widget buildEntry(BuildContext context, int index) {
      final entry = entries[index];
      return SelectableEntryCard(
        entryId: entry.id!,
        onTap: () => _onEntryTapped(entry, index),
        onSecondaryTapUp: (details) =>
            _showEntryMenu(entry, index, details.globalPosition),
        child: largeCards
            ? LargeEntryCardWidget(
                entry: entry,
                attachments:
                    _visualAttachmentsOf(entryAttachmentsProvider, entry),
                hideImage: configProvider.get(Settings.hideImagesInGallery),
                searchQuery: searchText,
              )
            : EntryCardWidget(
                entry: entry,
                attachments:
                    _visualAttachmentsOf(entryAttachmentsProvider, entry),
                hideImage: configProvider.get(Settings.hideImagesInGallery),
              ),
      );
    }

    Widget buildTier(int start, int end) => SliverGrid.builder(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: largeCards ? 500 : 300,
              crossAxisSpacing: 1.0,
              mainAxisSpacing: 1.0,
              childAspectRatio: largeCards ? 2.0 : 1.0),
          itemCount: end - start,
          itemBuilder: (context, index) => buildEntry(context, start + index),
        );

    return DragSelectRegion(
      scrollController: _scrollController,
      onStart: _onDragSelectStarted,
      onUpdate: GallerySelection.instance.dragTo,
      child: HideSemanticsWhileDragging(
        child: CustomScrollView(
          controller: _scrollController,
          physics: const ScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: galleryHorizontalPadding,
              ),
              sliver: buildTier(0, firstTierEnd),
            ),
            if (partialMatchCount > 0) ...[
              _buildPartialMatchesHeader(context, partialMatchCount),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: galleryHorizontalPadding,
                ),
                sliver: buildTier(firstTierEnd, entries.length),
              ),
            ],
            if (!entriesProvider.filter.isActive) _buildInvite(),
            SliverToBoxAdapter(
              child: SizedBox(
                height: _endSpacing + MediaQuery.viewInsetsOf(context).bottom,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
