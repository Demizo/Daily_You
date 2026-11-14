// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/tag.dart';
import 'package:flutter/foundation.dart';

enum TagChange { add, remove }

class BulkTagEditor with ChangeNotifier {
  BulkTagEditor(this.change, this.entryCount, this._initialPresence);

  final TagChange change;
  final int entryCount;
  final Map<int, TagPresence> _initialPresence;
  final Map<int, String?> _chosen = {};

  bool get hasChanges => _chosen.isNotEmpty;

  Map<int, String?> get additions =>
      change == TagChange.add ? Map.of(_chosen) : const {};

  Set<int> get removals =>
      change == TagChange.remove ? _chosen.keys.toSet() : const {};

  List<int> get chosenTagIds => _chosen.keys.toList();

  TagPresence _initialPresenceOf(int tagId) =>
      _initialPresence[tagId] ?? TagPresence.none;

  bool isApplicable(int tagId) => switch (change) {
        TagChange.add => _initialPresenceOf(tagId) != TagPresence.all,
        TagChange.remove => _initialPresenceOf(tagId) != TagPresence.none,
      };

  bool isChosen(int tagId) => _chosen.containsKey(tagId);

  String? valueOf(int tagId) => _chosen[tagId];

  void toggle(int tagId, {String? value}) {
    if (isChosen(tagId)) {
      _chosen.remove(tagId);
    } else if (isApplicable(tagId)) {
      _chosen[tagId] = change == TagChange.add ? value : null;
    }
    notifyListeners();
  }
}
