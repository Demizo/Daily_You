// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/storage/sync_item.dart';

class SyncProgress {
  const SyncProgress(this.item, [this.completed = 0, this.total = 0]);

  final SyncItem item;
  final int completed;
  final int total;

  String? get counts => total == 0 ? null : '$completed/$total';
}
