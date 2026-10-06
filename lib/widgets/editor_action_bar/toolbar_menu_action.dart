// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:async';

import 'package:flutter/widgets.dart';

@immutable
class ToolbarMenuAction {
  final IconData icon;
  final String label;
  final FutureOr<void> Function() onSelected;

  const ToolbarMenuAction({
    required this.icon,
    required this.label,
    required this.onSelected,
  });
}
