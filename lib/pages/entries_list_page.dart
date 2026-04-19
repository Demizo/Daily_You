import 'package:daily_you/layouts/fast_page_view_scroll_physics.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/pages/entry_view_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EntriesListPage extends StatefulWidget {
  final int index;
  final List<Entry> Function() getEntries;

  const EntriesListPage({
    super.key,
    required this.index,
    required this.getEntries,
  });

  @override
  State<EntriesListPage> createState() => _EntriesListPageState();
}

class _EntriesListPageState extends State<EntriesListPage> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<EntriesProvider>(context);
    final entries = widget.getEntries();

    return PageView.builder(
        hitTestBehavior: HitTestBehavior.translucent,
        controller: _pageController,
        physics: FastPageViewScrollPhysics(),
        reverse: true,
        itemCount: entries.length,
        onPageChanged: null,
        itemBuilder: (context, index) {
          return EntryViewPage(
            entryId: entries[index].id!,
            onEntryEdited: (editedEntryId) {
              final updatedEntries = widget.getEntries();
              final newIndex =
                  updatedEntries.indexWhere((e) => e.id == editedEntryId);
              if (newIndex != -1 && mounted) {
                _pageController.jumpToPage(newIndex);
              }
            },
          );
        });
  }
}
