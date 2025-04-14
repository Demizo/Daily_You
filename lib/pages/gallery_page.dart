import 'package:daily_you/config_provider.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/stats_provider.dart';
import 'package:daily_you/widgets/large_entry_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:daily_you/entries_database.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/widgets/entry_card_widget.dart';
import 'package:daily_you/pages/entry_detail_page.dart';
import 'package:easy_debounce/easy_debounce.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  late List<Entry> entries;
  late List<EntryImage> images;
  bool isLoading = false;
  String searchText = '';
  bool sortOrderAsc = false;
  int orderBy = 0;
  int entryCount = 0;
  bool firstLoad = true;
  bool listView = false;

  @override
  void initState() {
    super.initState();
    String viewMode =
        ConfigProvider.instance.get(ConfigKey.galleryPageViewMode);
    listView = viewMode == 'list';
    refreshEntries();
  }

  final sortOrderMapping = {true: 'ASC', false: 'DESC'};
  final orderByMapping = {0: 'time_create', 1: 'mood'};

  Future refreshEntries() async {
    if (firstLoad) setState(() => isLoading = true);
    firstLoad = false;

    images = await EntriesDatabase.instance.getAllEntryImages();
    entries = await EntriesDatabase.instance.getAllEntriesSorted(
        orderByMapping[orderBy]!, sortOrderMapping[sortOrderAsc]!);
    if (searchText.length > 2) {
      entries = entries
          .where((entry) =>
              entry.text.toLowerCase().contains(searchText.toLowerCase()))
          .toList();
    }
    entryCount = entries.length;
    setState(() => isLoading = false);
  }

  Future<void> setViewMode() async {
    var viewMode = listView ? 'list' : 'grid';
    await ConfigProvider.instance.set(ConfigKey.galleryPageViewMode, viewMode);
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
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<int>(
                        value: 0,
                        groupValue: orderBy,
                        onChanged: (value) => setState(() {
                          switchOrderBy(value!);
                        }),
                        title:
                            Text(AppLocalizations.of(context)!.sortDateTitle),
                      ),
                      RadioListTile<int>(
                        value: 1,
                        groupValue: orderBy,
                        onChanged: (value) => setState(() {
                          switchOrderBy(value!);
                        }),
                        title: Text(AppLocalizations.of(context)!.tagMoodTitle),
                      ),
                      const Divider(),
                      RadioListTile<bool>(
                        value: true,
                        groupValue: sortOrderAsc,
                        onChanged: (value) => setState(() {
                          switchSortOrder(value!);
                        }),
                        title: Text(AppLocalizations.of(context)!
                            .sortOrderAscendingTitle),
                      ),
                      RadioListTile<bool>(
                        value: false,
                        groupValue: sortOrderAsc,
                        onChanged: (value) => setState(() {
                          switchSortOrder(value!);
                        }),
                        title: Text(AppLocalizations.of(context)!
                            .sortOrderDescendingTitle),
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
                          top: 4, bottom: 8, left: 8, right: 8),
                      child: SearchBar(
                        leading: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.search_rounded),
                        ),
                        trailing: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(AppLocalizations.of(context)!
                                .logCount(entryCount)),
                          ),
                          IconButton(
                              onPressed: () async {
                                listView = !listView;
                                await setViewMode();
                                setState(() {});
                              },
                              icon: listView
                                  ? const Icon(Icons.grid_view_rounded)
                                  : const Icon(Icons.view_list_rounded)),
                          IconButton(
                              icon: const Icon(Icons.sort_rounded),
                              onPressed: () => _showSortSelectionPopup()),
                        ],
                        hintText: AppLocalizations.of(context)!.searchLogsHint,
                        padding: WidgetStateProperty.all(
                            const EdgeInsets.only(left: 8, right: 8)),
                        elevation: WidgetStateProperty.all(1),
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
      ? Center(
          child: Text(
            AppLocalizations.of(context)!.noLogs,
          ),
        )
      : GridView.builder(
          padding: const EdgeInsets.only(top: 70),
          physics: const ScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: listView ? 500 : 300,
              crossAxisSpacing: 1.0, // Spacing between columns
              mainAxisSpacing: 1.0, // Spacing between rows
              childAspectRatio: listView ? 2.0 : 1.0),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return GestureDetector(
              onTap: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => EntryDetailPage(
                      index: StatsProvider.instance.getIndexOfEntry(entry.id!)),
                ));

                refreshEntries();
              },
              child: listView
                  ? LargeEntryCardWidget(
                      entry: entry,
                      images: images
                          .where((img) => img.entryId == entry.id!)
                          .toList())
                  : EntryCardWidget(
                      entry: entry,
                      images: images
                          .where((img) => img.entryId == entry.id!)
                          .toList()),
            );
          },
        );
}
