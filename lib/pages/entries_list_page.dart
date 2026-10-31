// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/layouts/fast_page_view_scroll_physics.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/pages/entry_view_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/widgets/desktop_arrow_button.dart';
import 'package:daily_you/widgets/edge_navigation_arrows.dart';
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

  Widget _buildPages(List<Entry> entries) {
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

  @override
  Widget build(BuildContext context) {
    Provider.of<EntriesProvider>(context);
    final entries = widget.getEntries();
    final pages = _buildPages(entries);
    if (!isDesktopPlatform) return pages;

    return ListenableBuilder(
      listenable: _pageController,
      child: pages,
      builder: (context, pages) {
        final current = _pageController.hasClients
            ? _pageController.page?.round() ?? widget.index
            : widget.index;
        return EdgeNavigationArrows(
          topInset: kToolbarHeight + MediaQuery.paddingOf(context).top,
          onBackward: current < entries.length - 1
              ? () => stepToPage(_pageController, current + 1)
              : null,
          onForward: current > 0
              ? () => stepToPage(_pageController, current - 1)
              : null,
          child: pages!,
        );
      },
    );
  }
}
