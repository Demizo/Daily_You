import 'package:flutter/material.dart';
import 'package:daily_you/entries_database.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/widgets/entry_card_widget.dart';
import 'package:daily_you/pages/entry_detail_page.dart';
import 'package:easy_debounce/easy_debounce.dart';

class EntriesPage extends StatefulWidget {
  const EntriesPage({super.key});

  @override
  State<EntriesPage> createState() => _EntriesPageState();
}

class _EntriesPageState extends State<EntriesPage> {
  late List<Entry> entries;
  bool isLoading = false;
  String searchText = '';
  bool sortOrderAsc = false;
  int orderBy = 0;

  @override
  void initState() {
    super.initState();

    refreshEntries();
  }

  @override
  void dispose() {
    EntriesDatabase.instance.close();

    super.dispose();
  }

  final sortOrderMapping = {true: 'ASC', false: 'DESC'};
  final orderByMapping = {0: 'time_create', 1: 'mood'};

  Future refreshEntries() async {
    setState(() => isLoading = true);

    entries = await EntriesDatabase.instance.getAllEntriesSorted(
        orderByMapping[orderBy]!, sortOrderMapping[sortOrderAsc]!);
    if (searchText.length > 2) {
      entries = entries
          .where((entry) =>
              entry.text.toLowerCase().contains(searchText.toLowerCase()))
          .toList();
    }
    setState(() => isLoading = false);
  }

  void filterEntries(String query) {
    searchText = query;
    refreshEntries();
  }

  void switchSortOrder(bool value) {
    sortOrderAsc = value;
    refreshEntries();
  }

  void switchOrderBy(int value) {
    orderBy = value;
    refreshEntries();
  }

  void _showSortSelectionPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
                  title: const Text('Sort by...'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<int>(
                        value: 0,
                        groupValue: orderBy,
                        onChanged: (value) => setState(() {
                          switchOrderBy(value!);
                        }),
                        title: const Text('Date'),
                      ),
                      RadioListTile<int>(
                        value: 1,
                        groupValue: orderBy,
                        onChanged: (value) => setState(() {
                          switchOrderBy(value!);
                        }),
                        title: const Text('Mood'),
                      ),
                      const Divider(),
                      RadioListTile<bool>(
                        value: true,
                        groupValue: sortOrderAsc,
                        onChanged: (value) => setState(() {
                          switchSortOrder(value!);
                        }),
                        title: const Text('Ascending'),
                      ),
                      RadioListTile<bool>(
                        value: false,
                        groupValue: sortOrderAsc,
                        onChanged: (value) => setState(() {
                          switchSortOrder(value!);
                        }),
                        title: const Text('Descending'),
                      ),
                    ],
                  ),
                ));
      },
    );
  }

  @override
  Widget build(BuildContext context) => Center(
        child: isLoading
            ? const SizedBox()
            : Stack(alignment: Alignment.topCenter, children: [
                buildEntries(),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 4, bottom: 8, left: 3, right: 3),
                      child: SearchBar(
                        leading: const Icon(Icons.search_rounded),
                        trailing: [
                          IconButton(
                              icon: const Icon(Icons.sort_rounded),
                              onPressed: () => _showSortSelectionPopup()),
                        ],
                        hintText: 'Search logs...',
                        padding: MaterialStateProperty.all(
                            const EdgeInsets.only(left: 8, right: 8)),
                        elevation: MaterialStateProperty.all(1),
                        onChanged: (queryText) => EasyDebounce.debounce(
                            'search-debounce',
                            const Duration(milliseconds: 500), () {
                          filterEntries(queryText);
                        }),
                      ),
                    ),
                  ],
                ),
              ]),
      );

  Widget buildEntries() => entries.isEmpty
      ? const Center(
          child: Text(
            'No Logs...',
          ),
        )
      : GridView.builder(
          padding: const EdgeInsets.only(top: 70),
          physics: const ScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 300,
            crossAxisSpacing: 1.0, // Spacing between columns
            mainAxisSpacing: 1.0, // Spacing between rows
          ),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return GestureDetector(
              onTap: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => EntryDetailPage(entryId: entry.id!),
                ));

                refreshEntries();
              },
              child: EntryCardWidget(
                entry: entry,
              ),
            );
          },
        );
}
