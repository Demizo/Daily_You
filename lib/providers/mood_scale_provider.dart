// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/database/mood_scale_dao.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/mood_scale_level.dart';
import 'package:daily_you/utils/mood_scale_visuals.dart';
import 'package:material_ui/material_ui.dart';

class MoodScaleProvider with ChangeNotifier {
  static final MoodScaleProvider instance = MoodScaleProvider._init();

  MoodScaleProvider._init();

  List<MoodScaleLevel> levels = List.empty();

  Future<void> load() async {
    levels = await MoodScaleDao.getAll();
    notifyListeners();
  }

  MoodScaleLevel? levelOf(int? mood) =>
      levels.where((level) => level.mood == mood).firstOrNull;

  String moodPrefixOf(int? mood, AppLocalizations l10n) {
    final text = levelOf(mood)?.plainText(l10n);
    return text == null ? "" : "$text ";
  }

  Future<void> save(List<MoodScaleLevel> newLevels) async {
    await MoodScaleDao.save(newLevels);
    levels = [...newLevels]..sort((a, b) => a.mood.compareTo(b.mood));
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }
}
