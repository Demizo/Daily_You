// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/person.dart';
import 'package:daily_you/models/space.dart';
import 'package:daily_you/pages/edit_entry_page.dart';
import 'package:daily_you/pages/entries_list_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
import 'package:daily_you/providers/people_provider.dart';
import 'package:daily_you/providers/spaces_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/large_entry_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum SpacesPeopleTab { spaces, people }

class SpacesAndPeoplePage extends StatefulWidget {
  final SpacesPeopleTab initialTab;

  const SpacesAndPeoplePage({
    super.key,
    this.initialTab = SpacesPeopleTab.spaces,
  });

  @override
  State<SpacesAndPeoplePage> createState() => _SpacesAndPeoplePageState();
}

class _SpacesAndPeoplePageState extends State<SpacesAndPeoplePage>
    with AutomaticKeepAliveClientMixin {
  late SpacesPeopleTab _currentTab;
  int? _selectedSpaceId;
  int? _selectedPersonId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
  }

  Future<void> _promptAddSpace(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Space'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Space name',
            hintText: 'e.g. Work, Travel, Ideas',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) Navigator.of(ctx).pop(text);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty && mounted) {
      final newSpace = await SpacesProvider.instance.addSpace(name);
      setState(() {
        _selectedSpaceId = newSpace.id;
      });
    }
  }

  Future<void> _showSpaceOptions(BuildContext context, Space space) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Rename Space'),
              onTap: () => Navigator.of(ctx).pop('rename'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: const Text('Delete Space', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.of(ctx).pop('delete'),
            ),
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;

    if (action == 'rename') {
      final controller = TextEditingController(text: space.name);
      final renamed = await showDialog<String>(
        context: this.context,
        builder: (ctx) => AlertDialog(
          title: const Text('Rename Space'),
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
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) Navigator.of(ctx).pop(text);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
      if (renamed != null && renamed.isNotEmpty && mounted) {
        await SpacesProvider.instance.updateSpace(space.copy(
          name: renamed,
          timeModified: DateTime.now(),
        ));
      }
    } else if (action == 'delete' && mounted) {
      final confirm = await showDialog<bool>(
        context: this.context,
        builder: (ctx) => AlertDialog(
          title: Text('Delete "${space.name}"?'),
          content: const Text(
            'Entries in this space will become unassigned normal journals.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirm == true && mounted) {
        await SpacesProvider.instance.removeSpace(space);
        setState(() {
          _selectedSpaceId = null;
        });
      }
    }
  }

  Future<void> _promptAddPerson(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Person'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'e.g. Alice, Mom, Alex',
            prefixText: '@',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) Navigator.of(ctx).pop(text);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty && mounted) {
      final newPerson = await PeopleProvider.instance.addPerson(name);
      setState(() {
        _selectedPersonId = newPerson.id;
      });
    }
  }

  Future<void> _showPersonOptions(BuildContext context, Person person) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Rename Person'),
              onTap: () => Navigator.of(ctx).pop('rename'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: const Text('Delete Person', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.of(ctx).pop('delete'),
            ),
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;

    if (action == 'rename') {
      final controller = TextEditingController(text: person.name);
      final renamed = await showDialog<String>(
        context: this.context,
        builder: (ctx) => AlertDialog(
          title: const Text('Rename Person'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              prefixText: '@',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) Navigator.of(ctx).pop(text);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
      if (renamed != null && renamed.isNotEmpty && mounted) {
        await PeopleProvider.instance.updatePerson(person.copy(
          name: renamed,
          timeModified: DateTime.now(),
        ));
      }
    } else if (action == 'delete' && mounted) {
      await PeopleProvider.instance.removePerson(person);
      setState(() {
        _selectedPersonId = null;
      });
    }
  }

  void _createNewEntry(BuildContext context) {
    if (_currentTab == SpacesPeopleTab.spaces) {
      Navigator.of(context).push(MaterialPageRoute(
        allowSnapshotting: false,
        builder: (context) => AddEditEntryPage(
          entry: null,
          openCamera: false,
          images: const [],
          initialSpaceId: _selectedSpaceId,
        ),
      ));
    } else {
      Navigator.of(context).push(MaterialPageRoute(
        allowSnapshotting: false,
        builder: (context) => AddEditEntryPage(
          entry: null,
          openCamera: false,
          images: const [],
          initialPersonIds: _selectedPersonId != null ? [_selectedPersonId!] : const [],
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final spacesProvider = Provider.of<SpacesProvider>(context);
    final peopleProvider = Provider.of<PeopleProvider>(context);
    final entriesProvider = Provider.of<EntriesProvider>(context);
    final imagesProvider = Provider.of<EntryImagesProvider>(context);

    final allEntries = entriesProvider.entries;
    final spaces = spacesProvider.spaces;
    final people = peopleProvider.people;

    // Sync selected space
    if (_selectedSpaceId != null && !spaces.any((s) => s.id == _selectedSpaceId)) {
      _selectedSpaceId = spaces.isNotEmpty ? spaces.first.id : null;
    } else if (_selectedSpaceId == null && spaces.isNotEmpty) {
      _selectedSpaceId = spaces.first.id;
    }
    final activeSpace = spaces.where((s) => s.id == _selectedSpaceId).firstOrNull;

    // Sync selected person
    if (_selectedPersonId != null && !people.any((p) => p.id == _selectedPersonId)) {
      _selectedPersonId = people.isNotEmpty ? people.first.id : null;
    } else if (_selectedPersonId == null && people.isNotEmpty) {
      _selectedPersonId = people.first.id;
    }
    final activePerson = people.where((p) => p.id == _selectedPersonId).firstOrNull;

    // Get matching entries
    final List<Entry> matchingEntries = _currentTab == SpacesPeopleTab.spaces
        ? (activeSpace?.id != null
            ? spacesProvider.getEntriesForSpace(activeSpace!.id!, allEntries)
            : const [])
        : (activePerson?.id != null
            ? peopleProvider.getEntriesForPerson(activePerson!.id!, allEntries)
            : const []);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Spaces & People'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: Icon(_currentTab == SpacesPeopleTab.spaces
            ? (activeSpace != null ? Icons.edit_note_rounded : Icons.create_new_folder_rounded)
            : (activePerson != null ? Icons.edit_note_rounded : Icons.person_add_rounded)),
        label: Text(_currentTab == SpacesPeopleTab.spaces
            ? (activeSpace != null
                ? 'New entry in ${activeSpace.name}'
                : 'Create Space')
            : (activePerson != null
                ? 'New entry with @${activePerson.name}'
                : 'Add Person')),
        onPressed: () {
          if (_currentTab == SpacesPeopleTab.spaces && activeSpace == null) {
            _promptAddSpace(context);
          } else if (_currentTab == SpacesPeopleTab.people && activePerson == null) {
            _promptAddPerson(context);
          } else {
            _createNewEntry(context);
          }
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Segment selector: Spaces vs People
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    avatar: const Icon(Icons.dashboard_rounded, size: 16),
                    label: const Center(child: Text('Spaces')),
                    selected: _currentTab == SpacesPeopleTab.spaces,
                    showCheckmark: false,
                    onSelected: (selected) {
                      if (selected) setState(() => _currentTab = SpacesPeopleTab.spaces);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    avatar: const Icon(Icons.people_alt_rounded, size: 16),
                    label: const Center(child: Text('People')),
                    selected: _currentTab == SpacesPeopleTab.people,
                    showCheckmark: false,
                    onSelected: (selected) {
                      if (selected) setState(() => _currentTab = SpacesPeopleTab.people);
                    },
                  ),
                ),
              ],
            ),
          ),

          // Horizontal Shelf
          if (_currentTab == SpacesPeopleTab.spaces)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  for (final space in spaces)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onLongPress: () => _showSpaceOptions(context, space),
                        child: FilterChip(
                          selected: space.id == _selectedSpaceId,
                          showCheckmark: false,
                          avatar: const Icon(
                            Icons.folder_rounded,
                            size: 16,
                          ),
                          label: Text(
                            '${space.name} (${spacesProvider.getEntryCountForSpace(space.id ?? -1, allEntries)})',
                          ),
                          onSelected: (_) {
                            setState(() => _selectedSpaceId = space.id);
                          },
                        ),
                      ),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Create Space'),
                    onPressed: () => _promptAddSpace(context),
                  ),
                ],
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  for (final person in people)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onLongPress: () => _showPersonOptions(context, person),
                        child: FilterChip(
                          selected: person.id == _selectedPersonId,
                          showCheckmark: false,
                          avatar: const Icon(Icons.person_outline_rounded, size: 16),
                          label: Text(
                            '@${person.name} (${peopleProvider.getEntryCountForPerson(person.id ?? -1, allEntries)})',
                          ),
                          onSelected: (_) {
                            setState(() => _selectedPersonId = person.id);
                          },
                        ),
                      ),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Add Person'),
                    onPressed: () => _promptAddPerson(context),
                  ),
                ],
              ),
            ),

          // Main Body Content
          Expanded(
            child: _currentTab == SpacesPeopleTab.spaces
                ? (spaces.isEmpty
                    ? _buildEmptySpacesListState(context)
                    : (matchingEntries.isEmpty && activeSpace != null
                        ? _buildEmptySpaceEntriesState(context, activeSpace)
                        : _buildEntriesList(matchingEntries, entriesProvider, imagesProvider)))
                : (people.isEmpty
                    ? _buildEmptyPeopleListState(context)
                    : (matchingEntries.isEmpty && activePerson != null
                        ? _buildEmptyPersonEntriesState(context, activePerson)
                        : _buildEntriesList(
                            matchingEntries, entriesProvider, imagesProvider))),
          ),
        ],
      ),
    );
  }

  Widget _buildEntriesList(
    List<Entry> entries,
    EntriesProvider entriesProvider,
    EntryImagesProvider imagesProvider,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 80),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final images = imagesProvider.getForEntry(entry);
        final dateStr = TimeManager.formatDateWithWeekday(entry.timeCreate, context);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: SizedBox(
            height: 110,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  allowSnapshotting: false,
                  builder: (context) => EntriesListPage(
                    index: entriesProvider.getIndexOfEntry(entry.id!),
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
    );
  }

  Widget _buildEmptySpacesListState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dashboard_customize_outlined,
                size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'No Spaces created yet',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Create spaces to organize your journal by areas of life, projects, or contexts.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Space'),
              onPressed: () => _promptAddSpace(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySpaceEntriesState(BuildContext context, Space space) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dashboard_customize_outlined,
                size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'No entries in ${space.name}',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Entries you write or assign to this space will show up here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.edit_note_rounded),
              label: Text('Write entry in ${space.name}'),
              onPressed: () => _createNewEntry(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPeopleListState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline_rounded,
                size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Who was there? (@name)',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Track friends, family, and colleagues across your journal.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Add Person'),
              onPressed: () => _promptAddPerson(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPersonEntriesState(BuildContext context, Person person) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline_rounded,
                size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'No entries with @${person.name}',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Tag @${person.name} in your entries to see them collected here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.edit_note_rounded),
              label: Text('Write entry with @${person.name}'),
              onPressed: () => _createNewEntry(context),
            ),
          ],
        ),
      ),
    );
  }
}
