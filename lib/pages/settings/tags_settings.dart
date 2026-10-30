// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/tag.dart';
import 'package:daily_you/models/tag_category.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/utils/backup_restore_utils.dart';
import 'package:daily_you/utils/tag_category_visuals.dart';
import 'package:daily_you/utils/templates_tags_transfer.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/edit_category.dart';
import 'package:daily_you/widgets/edit_tag.dart';
import 'package:daily_you/widgets/expressive_fab_menu.dart';
import 'package:daily_you/widgets/failure_dialog.dart';
import 'package:daily_you/widgets/segmented_group.dart';
import 'package:daily_you/widgets/share_tags_dialog.dart';
import 'package:daily_you/widgets/settings_page_scaffold.dart';
import 'package:daily_you/widgets/tag_chip.dart';
import 'package:daily_you/widgets/tag_icon_glyph.dart';
import 'package:material_ui/material_ui.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

sealed class _ListItem {
  const _ListItem();
}

class _HeaderItem extends _ListItem {
  final TagCategory? category; // null = Uncategorized section
  const _HeaderItem(this.category);
}

class _TagItem extends _ListItem {
  final Tag tag;
  const _TagItem(this.tag);
}

class TagsSettings extends StatefulWidget {
  const TagsSettings({super.key});

  @override
  State<TagsSettings> createState() => _TagsSettingsState();
}

class _TagsSettingsState extends State<TagsSettings> {
  final Set<int?> _manuallyCollapsedIds = {};
  bool _isDraggingCategory = false;

  void _showEditTagDialog(BuildContext context, Tag? tag) {
    showAppDialog(
      context: context,
      builder: (context) => EditTag(tag: tag),
    );
  }

  void _showCategoryDialog(BuildContext context, TagCategory? category) {
    showAppDialog(
      context: context,
      builder: (_) => EditCategory(category: category),
    );
  }

  void _showShareDialog(BuildContext context) async {
    await Navigator.of(context).push(MaterialPageRoute(
        allowSnapshotting: false,
        fullscreenDialog: true,
        builder: (context) => const ShareTagsDialog()));
  }

  Future<void> _importFile(BuildContext context) async {
    final outcome = await BackupRestoreUtils.runWithLoadingStatus(
        context, TemplatesTagsTransfer.importTransferFile);

    if (!context.mounted) return;

    if (outcome.failed) {
      await showFailureDialog(context,
          description: AppLocalizations.of(context)!.importErrorDescription,
          error: outcome.error);
    }
  }

  void _toggleCollapse(int? categoryId) {
    setState(() {
      if (_manuallyCollapsedIds.contains(categoryId)) {
        _manuallyCollapsedIds.remove(categoryId);
      } else {
        _manuallyCollapsedIds.add(categoryId);
      }
    });
  }

  List<_ListItem> _buildFlatItems(TagsProvider provider) {
    final items = <_ListItem>[];
    final hasCategories = provider.categories.isNotEmpty;

    // Header only shown when named categories exist, to give uncategorized
    // tags something to collapse under.
    final uncategorizedTags =
        provider.tags.where((tag) => tag.categoryId == null).toList();
    if (hasCategories) {
      items.add(const _HeaderItem(null));
    }
    if (!hasCategories || !_manuallyCollapsedIds.contains(null)) {
      for (final tag in uncategorizedTags) {
        items.add(_TagItem(tag));
      }
    }

    for (final category in provider.categories) {
      items.add(_HeaderItem(category));
      if (!_manuallyCollapsedIds.contains(category.id)) {
        final categoryTags = provider.tags
            .where((tag) => tag.categoryId == category.id)
            .toList();
        for (final tag in categoryTags) {
          items.add(_TagItem(tag));
        }
      }
    }

    return items;
  }

  Future<void> _onReorder(
      int from, int to, TagsProvider provider, List<_ListItem> items) async {
    if (from == to) return;

    final movedItem = items[from];
    items.removeAt(from);
    items.insert(to, movedItem);

    if (movedItem is _HeaderItem) {
      // Uncategorized header is pinned, no-op if it was somehow moved
      if (movedItem.category == null) return;

      final orderedCategories = items
          .whereType<_HeaderItem>()
          .where((header) => header.category != null)
          .map((header) => header.category!)
          .toList();
      await provider.updateCategorySortOrders(orderedCategories);
    } else if (movedItem is _TagItem) {
      TagCategory? currentCategory;
      final Map<int?, List<Tag>> sectionTags = {};

      for (final item in items) {
        if (item is _HeaderItem) {
          currentCategory = item.category;
          sectionTags[currentCategory?.id] ??= [];
        } else if (item is _TagItem) {
          (sectionTags[currentCategory?.id] ??= []).add(item.tag);
        }
      }

      final tagsToUpdate = <Tag>[];
      for (final entry in sectionTags.entries) {
        final categoryId = entry.key;
        final tagsInSection = entry.value;
        for (int index = 0; index < tagsInSection.length; index++) {
          final tag = tagsInSection[index];
          final categoryChanged = tag.categoryId != categoryId;
          final orderChanged = tag.sortOrder != index;
          if (categoryChanged || orderChanged) {
            tagsToUpdate.add(Tag(
              id: tag.id,
              name: tag.name,
              color: tag.color,
              tagType: tag.tagType,
              icon: tag.icon,
              iconType: tag.iconType,
              categoryId: categoryId,
              sortOrder: index,
              timeCreate: tag.timeCreate,
              timeModified: categoryChanged ? DateTime.now() : tag.timeModified,
            ));
          }
        }
      }

      if (tagsToUpdate.isNotEmpty) {
        await provider.batchUpdateTags(tagsToUpdate);
      }
    }
  }

  Widget _buildHeaderRow(
    BuildContext context,
    int index,
    TagCategory? category,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final isCollapsed = _manuallyCollapsedIds.contains(category?.id);

    return ListTile(
      onTap: () => _toggleCollapse(category?.id),
      leading: category == null
          ? const Icon(Icons.folder_off_rounded)
          : ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle_rounded),
            ),
      title: Row(
        spacing: 10,
        children: [
          if (category != null)
            TagIconGlyph(
              icon: category.icon,
              iconType: category.iconType,
              fallbackIcon: Icons.folder_rounded,
              color: category.resolvedColor(context),
              size: 20,
            ),
          Expanded(
            child: Text(
              category?.name ?? l10n.tagCategoryUncategorized,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (category != null)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => _showCategoryDialog(context, category),
            ),
          Icon(isCollapsed
              ? Icons.expand_more_rounded
              : Icons.expand_less_rounded),
        ],
      ),
    );
  }

  Widget _buildTagRow(
    BuildContext context,
    int index,
    Tag tag,
    TagsProvider provider,
  ) {
    return ListTile(
      onTap: () => _showEditTagDialog(context, tag),
      leading: ReorderableDragStartListener(
        index: index,
        child: const Icon(Icons.drag_handle_rounded),
      ),
      title: Align(
        alignment: Alignment.centerLeft,
        child: TagChip(tag: tag),
      ),
      trailing: Text(
        AppLocalizations.of(context)!
            .logCount(provider.entryCountForTag(tag.id!)),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<TagsProvider>(context);
    final isEmpty = provider.tags.isEmpty && provider.categories.isEmpty;

    return SettingsPageScaffold.slivers(
      title: l10n.settingsTagsTitle,
      actions: [
        IconButton(
          icon: const Icon(Icons.file_open_outlined),
          onPressed: () => _importFile(context),
        ),
        IconButton(
          icon: const Icon(Icons.share_rounded),
          onPressed: () => _showShareDialog(context),
        ),
      ],
      floatingActionButton: ExpressiveFabMenu(items: [
        ExpressiveFabMenuItem(
            icon: Icons.folder_rounded,
            label: l10n.tagCategoryLabel,
            onTap: () => _showCategoryDialog(context, null)),
        ExpressiveFabMenuItem(
            icon: Icons.local_offer_rounded,
            label: l10n.tagLabel,
            onTap: () => _showEditTagDialog(context, null)),
      ]),
      slivers: isEmpty
          ? [
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 48),
                    child: Text(l10n.noResults),
                  ),
                ),
              ),
            ]
          : _tagSlivers(provider),
    );
  }

  Key _headerKey(TagCategory? category) => ValueKey('hdr_${category?.id}');

  List<Widget> _tagSlivers(TagsProvider provider) {
    final allItems = _buildFlatItems(provider);
    final firstItem = allItems.firstOrNull;
    final hasUncategorizedHeader =
        firstItem is _HeaderItem && firstItem.category == null;
    final offset = hasUncategorizedHeader ? 1 : 0;
    final items = allItems.sublist(offset);

    Widget segmented(int allIndex, Key key, Widget child) {
      final isHeader = allItems[allIndex] is _HeaderItem;
      final endsGroup = _isDraggingCategory ||
          allIndex + 1 == allItems.length ||
          allItems[allIndex + 1] is _HeaderItem;
      return Padding(
        key: key,
        padding: EdgeInsets.only(top: isHeader && allIndex > 0 ? 16 : 0),
        child: SegmentedRow(isFirst: isHeader, isLast: endsGroup, child: child),
      );
    }

    return [
      if (hasUncategorizedHeader)
        SliverToBoxAdapter(
          child: segmented(
            0,
            _headerKey(null),
            _buildHeaderRow(context, 0, null),
          ),
        ),
      SliverReorderableList(
        itemCount: items.length,
        onReorderStart: (index) {
          if (_isDraggingCategory || index >= items.length) return;
          final item = items[index];
          if (item is _HeaderItem && item.category != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _isDraggingCategory = true);
              }
            });
          }
        },
        onReorderEnd: (_) {
          if (_isDraggingCategory) {
            setState(() => _isDraggingCategory = false);
          }
        },
        onReorderItem: (from, to) {
          final snapshot = List<_ListItem>.from(items);
          _onReorder(from, to, provider, snapshot);
        },
        itemBuilder: (context, index) {
          switch (items[index]) {
            case _HeaderItem(:final category):
              return segmented(
                index + offset,
                _headerKey(category),
                _buildHeaderRow(context, index, category),
              );
            case _TagItem(:final tag):
              final key = ValueKey('tag_${tag.id}');
              if (_isDraggingCategory) return SizedBox(key: key);
              return segmented(
                index + offset,
                key,
                _buildTagRow(context, index, tag, provider),
              );
          }
        },
      ),
    ];
  }
}
