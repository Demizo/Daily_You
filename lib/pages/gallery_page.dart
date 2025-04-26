import 'package:daily_you/config_provider.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/stats_provider.dart';
import 'package:daily_you/widgets/large_entry_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/widgets/entry_card_widget.dart';
import 'package:daily_you/pages/entry_detail_page.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:provider/provider.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  bool listView = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = StatsProvider.instance.searchText;
    String viewMode =
        ConfigProvider.instance.get(ConfigKey.galleryPageViewMode);
    listView = viewMode == 'list';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> setViewMode() async {
    var viewMode = listView ? 'list' : 'grid';
    await ConfigProvider.instance.set(ConfigKey.galleryPageViewMode, viewMode);
  }

  void _showSortSelectionPopup(BuildContext context) {
    final statsProvider = Provider.of<StatsProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<OrderBy>(
                        value: OrderBy.date,
                        groupValue: statsProvider.orderBy,
                        onChanged: (value) => setState(() {
                          if (value != null) {
                            statsProvider.orderBy = value;
                            statsProvider.updateStats();
                          }
                        }),
                        title:
                            Text(AppLocalizations.of(context)!.sortDateTitle),
                      ),
                      RadioListTile<OrderBy>(
                        value: OrderBy.mood,
                        groupValue: statsProvider.orderBy,
                        onChanged: (value) => setState(() {
                          if (value != null) {
                            statsProvider.orderBy = value;
                            statsProvider.updateStats();
                          }
                        }),
                        title: Text(AppLocalizations.of(context)!.tagMoodTitle),
                      ),
                      const Divider(),
                      RadioListTile<SortOrder>(
                        value: SortOrder.ascending,
                        groupValue: statsProvider.sortOrder,
                        onChanged: (value) => setState(() {
                          if (value != null) {
                            statsProvider.sortOrder = value;
                            statsProvider.updateStats();
                          }
                        }),
                        title: Text(AppLocalizations.of(context)!
                            .sortOrderAscendingTitle),
                      ),
                      RadioListTile<SortOrder>(
                        value: SortOrder.descending,
                        groupValue: statsProvider.sortOrder,
                        onChanged: (value) => setState(() {
                          if (value != null) {
                            statsProvider.sortOrder = value;
                            statsProvider.updateStats();
                          }
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
  Widget build(BuildContext context) {
    final statsProvider = Provider.of<StatsProvider>(context);
    return Center(
      child: Stack(alignment: Alignment.topCenter, children: [
        buildEntries(context),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding:
                  const EdgeInsets.only(top: 4, bottom: 8, left: 8, right: 8),
              child: SearchBar(
                controller: _searchController,
                leading: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.search_rounded),
                ),
                trailing: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(AppLocalizations.of(context)!
                        .logCount(statsProvider.filteredEntries.length)),
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
                      onPressed: () => _showSortSelectionPopup(context)),
                ],
                hintText: AppLocalizations.of(context)!.searchLogsHint,
                padding: WidgetStateProperty.all(
                    const EdgeInsets.only(left: 8, right: 8)),
                elevation: WidgetStateProperty.all(1),
                onChanged: (queryText) => EasyDebounce.debounce(
                    'search-debounce', const Duration(milliseconds: 500), () {
                  statsProvider.searchText = queryText;
                  statsProvider.updateStats();
                }),
              ),
            ),
          ],
        ),
      ]),
    );
  }

  Widget buildEntries(BuildContext context) {
    final statsProvider = Provider.of<StatsProvider>(context);
    var entries = statsProvider.filteredEntries;
    return statsProvider.filteredEntries.isEmpty
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
                            filtered: true,
                            index: index,
                          )));
                },
                child: listView
                    ? LargeEntryCardWidget(
                        entry: entry,
                        images: statsProvider.images
                            .where((img) => img.entryId == entry.id!)
                            .toList())
                    : EntryCardWidget(
                        entry: entry,
                        images: statsProvider.images
                            .where((img) => img.entryId == entry.id!)
                            .toList()),
              );
            },
          );
  }
}
