// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:material_ui/material_ui.dart';

class GalleryAction {
  const GalleryAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final Widget icon;
  final VoidCallback onPressed;
}

final ShapeBorder galleryMenuShape =
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));

List<PopupMenuEntry<GalleryAction>> galleryMenuItems(
        List<GalleryAction> actions) =>
    [
      for (final action in actions)
        PopupMenuItem(
          value: action,
          child: Row(
            children: [
              IconTheme.merge(
                data: const IconThemeData(size: 20),
                child: action.icon,
              ),
              const SizedBox(width: 12),
              Text(action.label),
            ],
          ),
        ),
    ];
