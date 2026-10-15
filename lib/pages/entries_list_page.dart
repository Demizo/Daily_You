// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/layouts/fast_page_view_scroll_physics.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/pages/entry_view_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:material_ui/material_ui.dart';
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

    // SelectionArea for entry text sits above the page so it loses to swipe gestures.
    return SelectionArea(
      child: PageView.builder(
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
          }),
    );
  }
}
