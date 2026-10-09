// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/pages/edit_entry_page.dart';
import 'package:daily_you/pages/entries_list_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/large_entry_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum JuneTagGroup { spaces, people, topics }

class TagsPage extends StatefulWidget {
  const TagsPage({super.key});

  @override
  State<TagsPage> createState() => _TagsPageState();
}

class _TagsPageState extends State<TagsPage>
    with AutomaticKeepAliveClientMixin {
  JuneTagGroup _currentGroup = JuneTagGroup.spaces;
  int? _selectedTagId;

  @override
  bool get wantKeepAlive => true;

  bool _matchesGroup(Tag tag, JuneTagGroup group) {
    final name = tag.name.trim();
    switch (group) {
      case JuneTagGroup.people:
        return name.startsWith('@');
      case JuneTagGroup.topics:
        return name.startsWith('#');
      case JuneTagGroup.spaces:
        return !name.startsWith('@') && !name.startsWith('#');
    }
  }

  List<Tag> _getTagsForGroup(List<Tag> allTags, JuneTagGroup group) {
    return allTags.where((tag) => _matchesGroup(tag, group)).toList();
  }

  Future<void> _promptAddTag(BuildContext context, JuneTagGroup group) async {
    final prefix = group == JuneTagGroup.people
        ? '@'
        : group == JuneTagGroup.topics
            ? '#'
            : '';
    final nameController = TextEditingController(text: prefix);

    final created = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(group == JuneTagGroup.people
            ? 'Add Person'
            : group == JuneTagGroup.topics
                ? 'Add Topic'
                : 'Add Tag'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: group == JuneTagGroup.people
                ? 'Name (e.g. @Alice)'
                : group == JuneTagGroup.topics
                    ? 'Topic (e.g. #Project)'
                    : 'Tag name',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final raw = nameController.text.trim();
              if (raw.isNotEmpty) {
                Navigator.of(dialogCtx).pop(raw);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (created != null && created.trim().isNotEmpty && mounted) {
      final now = DateTime.now();
      final tag = Tag(
        name: created.trim(),
        tagType: TagType.label,
        timeCreate: now,
        timeModified: now,
      );
      await TagsProvider.instance.add(tag);
      final addedTag = TagsProvider.instance.tags
          .where((t) => t.name == tag.name)
          .firstOrNull;
      setState(() {
        _selectedTagId = addedTag?.id;
      });
    }
  }

  Future<void> _showTagOptions(BuildContext context, Tag tag) async {
    final tagsProvider = TagsProvider.instance;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Rename Tag'),
              onTap: () => Navigator.of(ctx).pop('rename'),
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title:
                  const Text('Delete Tag', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.of(ctx).pop('delete'),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;

    if (action == 'rename') {
      final controller = TextEditingController(text: tag.name);
      final renamed = await showDialog<String>(
        context: this.context,
        builder: (ctx) => AlertDialog(
          title: const Text('Rename Tag'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        ),
      );
      if (renamed != null && renamed.isNotEmpty && mounted) {
        await tagsProvider.update(tag.copy(name: renamed));
      }
    } else if (action == 'delete' && mounted) {
      await tagsProvider.remove(tag);
      setState(() {
        _selectedTagId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final tagsProvider = Provider.of<TagsProvider>(context);
    final entriesProvider = Provider.of<EntriesProvider>(context);
    final imagesProvider = Provider.of<EntryImagesProvider>(context);

    final allTags = tagsProvider.tags;
    final currentGroup = _currentGroup;
    final groupTags = _getTagsForGroup(allTags, currentGroup);

    if (_selectedTagId != null &&
        !groupTags.any((t) => t.id == _selectedTagId)) {
      _selectedTagId = groupTags.isNotEmpty ? groupTags.first.id : null;
    } else if (_selectedTagId == null && groupTags.isNotEmpty) {
      _selectedTagId = groupTags.first.id;
    }

    final Tag? activeTag =
        allTags.where((t) => t.id == _selectedTagId).firstOrNull;

    final matchingEntries = activeTag != null
        ? entriesProvider.entries.where((entry) {
            final entryTags =
                tagsProvider.getEntryTagsForEntry(entry.id ?? -1);
            return entryTags.any((et) => et.tagId == activeTag.id);
          }).toList()
        : const <Entry>[];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Tags & People'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_rounded),
        label: Text(currentGroup == JuneTagGroup.people
            ? 'Add Person'
            : currentGroup == JuneTagGroup.topics
                ? 'Add Topic'
                : 'Add Tag'),
        onPressed: () => _promptAddTag(context, currentGroup),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    avatar: const Icon(Icons.dashboard_rounded, size: 16),
                    label: const Center(child: Text('Spaces')),
                    selected: _currentGroup == JuneTagGroup.spaces,
                    showCheckmark: false,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _currentGroup = JuneTagGroup.spaces;
                          _selectedTagId = null;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    avatar: const Icon(Icons.people_alt_rounded, size: 16),
                    label: const Center(child: Text('People')),
                    selected: _currentGroup == JuneTagGroup.people,
                    showCheckmark: false,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _currentGroup = JuneTagGroup.people;
                          _selectedTagId = null;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    avatar: const Icon(Icons.tag_rounded, size: 16),
                    label: const Center(child: Text('Topics')),
                    selected: _currentGroup == JuneTagGroup.topics,
                    showCheckmark: false,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _currentGroup = JuneTagGroup.topics;
                          _selectedTagId = null;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          // Horizontal tags shelf
          if (groupTags.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  for (final tag in groupTags)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onLongPress: () => _showTagOptions(context, tag),
                        child: FilterChip(
                          selected: tag.id == _selectedTagId,
                          showCheckmark: false,
                          label: Text(
                            entriesProvider.entries.where((e) {
                              final ets =
                                  tagsProvider.getEntryTagsForEntry(e.id ?? -1);
                              return ets.any((et) => et.tagId == tag.id);
                            }).isNotEmpty
                                ? '${tag.name} (${entriesProvider.entries.where((e) {
                                    final ets = tagsProvider
                                        .getEntryTagsForEntry(e.id ?? -1);
                                    return ets.any((et) => et.tagId == tag.id);
                                  }).length})'
                                : tag.name,
                          ),
                          onSelected: (_) {
                            setState(() {
                              _selectedTagId = tag.id;
                            });
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Main body content
          Expanded(
            child: groupTags.isEmpty
                ? _buildEmptyGroupState(context, currentGroup)
                : matchingEntries.isEmpty
                    ? _buildEmptyTagEntriesState(context, activeTag!)
                    : ListView.builder(
                        padding: const EdgeInsets.only(
                            left: 12, right: 12, top: 8, bottom: 80),
                        itemCount: matchingEntries.length,
                        itemBuilder: (context, index) {
                          final entry = matchingEntries[index];
                          final images = imagesProvider.getForEntry(entry);
                          final dateStr = TimeManager.formatDateWithWeekday(
                              entry.timeCreate, context);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: SizedBox(
                              height: 110,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    allowSnapshotting: false,
                                    builder: (context) => EntriesListPage(
                                      index: entriesProvider
                                          .getIndexOfEntry(entry.id!),
                                      getEntries: () => entriesProvider.entries,
                                    ),
                                  ));
                                },
                                child: LargeEntryCardWidget(
                                  title: dateStr,
                                  entry: entry,
                                  images: images,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyGroupState(BuildContext context, JuneTagGroup group) {
    final theme = Theme.of(context);
    final String title;
    final String subtitle;
    final IconData icon;

    switch (group) {
      case JuneTagGroup.people:
        title = 'Who was there? (@name)';
        subtitle = 'Track friends, family, or colleagues across your entries.';
        icon = Icons.people_outline_rounded;
        break;
      case JuneTagGroup.topics:
        title = 'What was it about? (#topic)';
        subtitle = 'Organize entries by projects, themes, or interests.';
        icon = Icons.tag_rounded;
        break;
      case JuneTagGroup.spaces:
        title = 'Where were you?';
        subtitle = 'Group entries by locations, environments, or areas of life.';
        icon = Icons.dashboard_customize_outlined;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.add_rounded),
              label: Text(group == JuneTagGroup.people
                  ? 'Add Person'
                  : group == JuneTagGroup.topics
                      ? 'Add Topic'
                      : 'Add Tag'),
              onPressed: () => _promptAddTag(context, group),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTagEntriesState(BuildContext context, Tag tag) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notes_rounded,
                size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'No entries tagged with ${tag.name}',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.edit_note_rounded),
              label: Text('New log with ${tag.name}'),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  allowSnapshotting: false,
                  builder: (context) => AddEditEntryPage(
                    entry: null,
                    sharedText: '${tag.name} ',
                  ),
                ));
              },
            ),
          ],
        ),
      ),
    );
  }
}
