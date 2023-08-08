import 'package:flutter/material.dart';
import 'package:daily_you/entries_database.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/widgets/entry_card_widget.dart';
import 'package:daily_you/pages/entry_detail_page.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:easy_debounce/easy_throttle.dart';

class EntriesPage extends StatefulWidget {
  const EntriesPage({super.key});

  @override
  State<EntriesPage> createState() => _EntriesPageState();
}

class _EntriesPageState extends State<EntriesPage> {
  late List<Entry> entries;
  bool isLoading = false;
  String searchText = '';
  bool sortOrderAsc = true;

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

  Future refreshEntries() async {
    setState(() => isLoading = true);

    entries = await EntriesDatabase.instance.getAllEntries();
    if (searchText.length > 2) {
      entries = entries
          .where((entry) =>
              entry.text.toLowerCase().contains(searchText.toLowerCase()))
          .toList();
    }
    if (!sortOrderAsc) {
      entries = entries.reversed.toList();
    }
    setState(() => isLoading = false);
  }

  void filterEntries(String query) {
    searchText = query;
    refreshEntries();
  }

  void switchSortOrder() {
    sortOrderAsc = !sortOrderAsc;
    refreshEntries();
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
                            icon: Icon(sortOrderAsc
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded),
                            onPressed: () => EasyThrottle.throttle(
                                'sort-order-throttle',
                                const Duration(milliseconds: 500), () {
                              setState(() => switchSortOrder());
                            }),
                          ),
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
