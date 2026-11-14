// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/providers/gallery_selection.dart';
import 'package:daily_you/widgets/drag_select_region.dart';
import 'package:daily_you/widgets/entry_card_widget.dart';
import 'package:daily_you/widgets/gallery_selection_bar.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class SelectableEntryCard extends StatelessWidget {
  const SelectableEntryCard({
    super.key,
    required this.entryId,
    required this.onTap,
    required this.onSecondaryTapUp,
    required this.child,
  });

  final int entryId;
  final VoidCallback onTap;
  final GestureTapUpCallback onSecondaryTapUp;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = context.select(
      (GallerySelection selection) => selection.isSelected(entryId),
    );
    return DragSelectItem(
      itemId: entryId,
      child: Semantics(
        selected: selected ? true : null,
        child: GestureDetector(
          onTap: onTap,
          onSecondaryTapUp: onSecondaryTapUp,
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              child,
              Positioned.fill(
                child: IgnorePointer(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: selected ? 1.0 : 0.0),
                    duration: selectionFadeDuration,
                    builder: (context, opacity, overlay) => opacity == 0
                        ? const SizedBox.shrink()
                        : Opacity(opacity: opacity, child: overlay),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.2),
                          border:
                              Border.all(color: colorScheme.primary, width: 3),
                          borderRadius:
                              BorderRadius.circular(entryCardCornerRadius),
                        ),
                        child: Align(
                          alignment: AlignmentDirectional.topStart,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: colorScheme.primary,
                              child: Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
