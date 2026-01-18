import 'package:daily_you/config_provider.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
import 'package:daily_you/widgets/hiding_widget.dart';
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

class _GalleryPageState extends State<GalleryPage>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final FocusNode _focusNode = FocusNode();
  double _searchElevation = 0.0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _searchController.text = EntriesProvider.instance.searchText;
    _scrollController.addListener(() {
      final elevation = _scrollController.position.pixels > 0 ? 1.0 : 0.0;

      if (_searchElevation != elevation) {
        setState(() {
          _searchElevation = elevation;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _showSortSelectionPopup(BuildContext context) {
    final entriesProvider =
        Provider.of<EntriesProvider>(context, listen: false);
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
                        groupValue: entriesProvider.orderBy,
                        onChanged: (value) => setState(() {
                          if (value != null) {
                            entriesProvider.orderBy = value;
                          }
                        }),
                        title:
                            Text(AppLocalizations.of(context)!.sortDateTitle),
                      ),
                      RadioListTile<OrderBy>(
                        value: OrderBy.mood,
                        groupValue: entriesProvider.orderBy,
                        onChanged: (value) => setState(() {
                          if (value != null) {
                            entriesProvider.orderBy = value;
                          }
                        }),
                        title: Text(AppLocalizations.of(context)!.tagMoodTitle),
                      ),
                      const Divider(),
                      RadioListTile<SortOrder>(
                        value: SortOrder.ascending,
                        groupValue: entriesProvider.sortOrder,
                        onChanged: (value) => setState(() {
                          if (value != null) {
                            entriesProvider.sortOrder = value;
                          }
                        }),
                        title: Text(AppLocalizations.of(context)!
                            .sortOrderAscendingTitle),
                      ),
                      RadioListTile<SortOrder>(
                        value: SortOrder.descending,
                        groupValue: entriesProvider.sortOrder,
                        onChanged: (value) => setState(() {
                          if (value != null) {
                            entriesProvider.sortOrder = value;
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
    super.build(context);
    final entriesProvider = Provider.of<EntriesProvider>(context);
    final configProvider = Provider.of<ConfigProvider>(context);
    String viewMode = configProvider.get(ConfigKey.galleryPageViewMode);
    bool listView = viewMode == 'list';
    var entries = entriesProvider.getFilteredEntries();
    return Center(
      child: Stack(alignment: Alignment.topCenter, children: [
        buildEntries(context, listView, entries),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding:
                  const EdgeInsets.only(top: 4, bottom: 8, left: 8, right: 8),
              child: SearchBar(
                focusNode: _focusNode,
                controller: _searchController,
                elevation: WidgetStatePropertyAll(_searchElevation),
                leading: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.search_rounded,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
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
                              entriesProvider.searchText = "";
                              setState(() {});
                            },
                          )
                        : SizedBox.shrink(
                            key: ValueKey('empty')), // Empty widget
                  ),
                  if (entriesProvider.searchText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(AppLocalizations.of(context)!
                          .logCount(entries.length)),
                    ),
                  IconButton(
                      icon: const Icon(Icons.sort_rounded),
                      onPressed: () => _showSortSelectionPopup(context)),
                ],
                hintText: AppLocalizations.of(context)!.searchLogsHint,
                padding: WidgetStateProperty.all(
                    const EdgeInsets.only(left: 4, right: 4)),
                backgroundColor: WidgetStatePropertyAll(
                    Theme.of(context).colorScheme.secondaryContainer),
                onChanged: (queryText) => EasyDebounce.debounce(
                    'search-debounce', const Duration(milliseconds: 300), () {
                  entriesProvider.searchText = queryText;
                }),
              ),
            ),
            if (entries.isNotEmpty)
              HidingWidget(
                scrollController: _scrollController,
                duration: Duration(milliseconds: 200),
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
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        elevation: 1,
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                        onPressed: () async {
                          _scrollController.position.animateTo(0,
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeOut);
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ]),
    );
  }

  Widget buildEntries(
      BuildContext context, bool listView, List<Entry> entries) {
    final entryImagesProvider = Provider.of<EntryImagesProvider>(context);
    return entries.isEmpty
        ? Center(
            child: Text(
              AppLocalizations.of(context)!.noLogs,
            ),
          )
        : GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.only(top: 70, bottom: 70),
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
                        images: entryImagesProvider.getForEntry(entry))
                    : EntryCardWidget(
                        entry: entry,
                        images: entryImagesProvider.getForEntry(entry)),
              );
            },
          );
  }
}
