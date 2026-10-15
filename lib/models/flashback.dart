// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/entry.dart';

class Flashback {
  final String title;
  final List<Entry> entries;
  final List<String> entryLabels;
  final bool isOnThisDay;

  const Flashback({
    required this.title,
    required this.entries,
    required this.entryLabels,
    this.isOnThisDay = false,
  });

  bool get isMultiEntry => entries.length > 1;

  Entry get firstEntry => entries.first;
}
