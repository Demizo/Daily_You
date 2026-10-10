// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/tag_category.dart';
import 'package:material_ui/material_ui.dart';

extension TagCategoryVisuals on TagCategory {
  /// Resolves the category's color against the theme; a null [TagCategory.color]
  /// means no color has been chosen, so the theme default applies instead.
  Color resolvedColor(BuildContext context, {Color? fallback}) {
    if (color != null) return Color(color!);
    return fallback ?? Theme.of(context).colorScheme.onSurface;
  }
}
