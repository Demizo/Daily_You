// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:material_ui/material_ui.dart';

class StatsLayoutProvider with ChangeNotifier {
  static final StatsLayoutProvider instance =
      StatsLayoutProvider(TagsProvider.instance);

  static const int _seededTagCount = 4;

  StatsLayoutProvider(this._tagsProvider) {
    _tagsProvider.addListener(_pruneRemovedTags);
  }

  final TagsProvider _tagsProvider;

  List<int> _pinnedTagIds = const [];
  List<int> get pinnedTagIds => _pinnedTagIds;

  @override
  void dispose() {
    _tagsProvider.removeListener(_pruneRemovedTags);
    super.dispose();
  }

  Future<void> load() async {
    final stored = ConfigProvider.instance.get(Settings.statsPinnedTagIds);
    if (stored == null) {
      final seeded = [
        for (final tag in _tagsProvider.tags.take(_seededTagCount)) tag.id!,
      ];
      if (seeded.isNotEmpty) await replace(seeded);
      return;
    }
    _pinnedTagIds = List.unmodifiable(stored.whereType<int>());
    final remaining = _existingTagIds(_pinnedTagIds);
    if (remaining.length == _pinnedTagIds.length) {
      notifyListeners();
    } else {
      await replace(remaining);
    }
  }

  Future<void> replace(List<int> tagIds) {
    _pinnedTagIds = List.unmodifiable(tagIds);
    notifyListeners();
    return ConfigProvider.instance
        .set(Settings.statsPinnedTagIds, _pinnedTagIds);
  }

  List<int> _existingTagIds(List<int> tagIds) {
    final existingIds = {for (final tag in _tagsProvider.tags) tag.id};
    return [
      for (final tagId in tagIds)
        if (existingIds.contains(tagId)) tagId,
    ];
  }

  Future<void> _pruneRemovedTags() async {
    final remaining = _existingTagIds(_pinnedTagIds);
    if (remaining.length == _pinnedTagIds.length) return;
    await replace(remaining);
  }
}
