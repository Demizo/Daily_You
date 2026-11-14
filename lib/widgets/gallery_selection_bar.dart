// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/providers/gallery_selection.dart';
import 'package:daily_you/utils/gallery_entry_actions.dart';
import 'package:daily_you/widgets/gallery_action_menu.dart';
import 'package:material_ui/material_ui.dart';

const Duration selectionFadeDuration = Duration(milliseconds: 120);

class SelectionAppBarSwitcher extends StatelessWidget
    implements PreferredSizeWidget {
  const SelectionAppBarSwitcher({
    super.key,
    required this.selecting,
    required this.defaultBar,
  });

  final bool selecting;
  final Widget defaultBar;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: selectionFadeDuration,
      child: selecting
          ? const GallerySelectionBar(key: ValueKey('selection'))
          : KeyedSubtree(key: const ValueKey('default'), child: defaultBar),
    );
  }
}

class GallerySelectionBar extends StatelessWidget
    implements PreferredSizeWidget {
  const GallerySelectionBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final selection = GallerySelection.instance;
    final l10n = AppLocalizations.of(context)!;
    final share = shareSelectionAction(context, selection);
    return ListenableBuilder(
      listenable: selection,
      builder: (context, _) => AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          icon: const Icon(Icons.close_rounded),
          onPressed: selection.clear,
        ),
        title: Semantics(
          liveRegion: true,
          child: Text(
            '${selection.selectedCount}/${selection.selectableCount}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        actions: [
          IconButton(
            tooltip: l10n.gallerySelectAll,
            icon: const Icon(Icons.select_all_rounded),
            onPressed: () => selectAllEntries(context, selection),
          ),
          if (share != null)
            IconButton(
              tooltip: share.label,
              icon: share.icon,
              onPressed: share.onPressed,
            ),
          PopupMenuButton<GalleryAction>(
            tooltip: MaterialLocalizations.of(context).showMenuTooltip,
            shape: galleryMenuShape,
            onSelected: (action) => action.onPressed(),
            itemBuilder: (context) =>
                galleryMenuItems(selectionActions(context, selection)),
          ),
        ],
      ),
    );
  }
}
