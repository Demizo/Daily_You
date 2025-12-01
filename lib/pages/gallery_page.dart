import 'package:daily_you/config_provider.dart';
import 'package:daily_you/stats_provider.dart';
import 'package:daily_you/widgets/hiding_widget.dart';
import 'package:daily_you/widgets/images_provider.dart';
import 'package:daily_you/widgets/large_entry_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController.text = StatsProvider.instance.searchText;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
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
    final configProvider = Provider.of<ConfigProvider>(context);
    String viewMode = configProvider.get(ConfigKey.galleryPageViewMode);
    bool listView = viewMode == 'list';
    return Center(
      child: Stack(alignment: Alignment.topCenter, children: [
        buildEntries(context, listView),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            HidingWidget(
              focusNode: _focusNode,
              scrollController: _scrollController,
              duration: Duration(milliseconds: 200),
              hideDirection: HideDirection.up,
              child: Padding(
                padding:
                    const EdgeInsets.only(top: 4, bottom: 8, left: 8, right: 8),
                child: SearchBar(
                  focusNode: _focusNode,
                  controller: _searchController,
                  leading: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.search_rounded),
                  ),
                  trailing: [
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        final rotationAnimation =
                            Tween<double>(begin: 0.0, end: 0.5).animate(
                          CurvedAnimation(
                              parent: animation, curve: Curves.easeOut),
                        );

                        final scaleAnimation = TweenSequence([
                          TweenSequenceItem(
                            tween: Tween<double>(begin: 0.0, end: 1.1)
                                .chain(CurveTween(curve: Curves.easeOut)),
                            weight: 50,
                          ),
                          TweenSequenceItem(
                            tween: Tween<double>(begin: 1.1, end: 1.0)
                                .chain(CurveTween(curve: Curves.easeIn)),
                            weight: 50,
                          ),
                        ]).animate(animation);

                        return RotationTransition(
                          turns: rotationAnimation,
                          child: ScaleTransition(
                            scale: scaleAnimation,
                            child: child,
                          ),
                        );
                      },
                      child: _searchController.text.isNotEmpty
                          ? IconButton(
                              visualDensity: VisualDensity(
                                  horizontal: VisualDensity.minimumDensity),
                              key: ValueKey('clearButton'),
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                statsProvider.searchText = "";
                                statsProvider.updateStats();
                                setState(() {});
                              },
                            )
                          : SizedBox.shrink(
                              key: ValueKey('empty')), // Empty widget
                    ),
                    if (statsProvider.filteredEntries.length !=
                        statsProvider.entries.length)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(AppLocalizations.of(context)!
                            .logCount(statsProvider.filteredEntries.length)),
                      ),
                    IconButton(
                        icon: const Icon(Icons.sort_rounded),
                        onPressed: () => _showSortSelectionPopup(context)),
                  ],
                  hintText: AppLocalizations.of(context)!.searchLogsHint,
                  padding: WidgetStateProperty.all(
                      const EdgeInsets.only(left: 4, right: 4)),
                  elevation: WidgetStateProperty.all(1),
                  onChanged: (queryText) => EasyDebounce.debounce(
                      'search-debounce', const Duration(milliseconds: 300), () {
                    statsProvider.searchText = queryText;
                    statsProvider.updateStats();
                  }),
                ),
              ),
            ),
          ],
        ),
      ]),
    );
  }

  Widget buildEntries(BuildContext context, bool listView) {
    final statsProvider = Provider.of<StatsProvider>(context);
    final imagesProvider = Provider.of<ImagesProvider>(context);
    var entries = statsProvider.filteredEntries;
    return statsProvider.filteredEntries.isEmpty
        ? Center(
            child: Text(
              AppLocalizations.of(context)!.noLogs,
            ),
          )
        : GridView.builder(
            controller: _scrollController,
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
                      allowSnapshotting: false,
                      builder: (context) => EntryDetailPage(
                            filtered: true,
                            index: index,
                          )));
                },
                child: listView
                    ? LargeEntryCardWidget(
                        entry: entry,
                        images: imagesProvider.images
                            .where((img) => img.entryId == entry.id!)
                            .toList())
                    : EntryCardWidget(
                        entry: entry,
                        images: imagesProvider.images
                            .where((img) => img.entryId == entry.id!)
                            .toList()),
              );
            },
          );
  }
}
