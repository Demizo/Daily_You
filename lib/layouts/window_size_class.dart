// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:material_ui/material_ui.dart';

enum WindowSizeClass {
  compact,
  medium,
  expanded;

  static const double mediumMinWidth = 600;
  static const double expandedMinWidth = 1100;

  static WindowSizeClass fromWidth(double width) {
    if (width >= expandedMinWidth) return expanded;
    if (width >= mediumMinWidth) return medium;
    return compact;
  }

  static WindowSizeClass of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  bool get isWide => this != compact;

  bool get hasPersistentSidebar => this == expanded;
}
