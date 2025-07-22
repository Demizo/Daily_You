import 'dart:math';

import 'package:daily_you/config_provider.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/flashback.dart';
import 'package:daily_you/time_manager.dart';
import 'package:provider/provider.dart';

class FlashbackManager {
  static List<Flashback> getFlashbacks(
      BuildContext context, List<Entry> entries) {
    final configProvider = Provider.of<ConfigProvider>(context);

    List<Entry> filteredEntries = entries;

    if (configProvider.get(ConfigKey.excludeBadDaysFromFlashbacks)) {
      // Filter out unhappy entries
      filteredEntries =
          filteredEntries.where((entry) => (entry.mood ?? 0) >= 0).toList();
    }

    List<Flashback> flashbacksList = List.empty(growable: true);
    Map<String, Entry> flashbacks = {};

    List<Entry> happyEntries = List.empty(growable: true);

    if (filteredEntries.isEmpty) return flashbacksList;

    // Time based memories
    for (var entry in filteredEntries.reversed.toList()) {
      if (flashbacks.containsValue(entry)) continue;
      if (configProvider.get(ConfigKey.showflashbackYearsAgo) &&
          entry.timeCreate.day == DateTime.now().day &&
          entry.timeCreate.month == DateTime.now().month &&
          entry.timeCreate.year != DateTime.now().year) {
        var yearsAgo = DateTime.now().year - entry.timeCreate.year;
        flashbacks.putIfAbsent(
            AppLocalizations.of(context)!.flashbackYear(yearsAgo), () => entry);
        continue;
      }
      if (configProvider.get(ConfigKey.showflashback6MonthsAgo) &&
          TimeManager.datesExactMonthDiff(entry.timeCreate, DateTime.now()) ==
              6) {
        flashbacks.putIfAbsent(
            AppLocalizations.of(context)!.flashbackMonth(6), () => entry);
        continue;
      }
      if (configProvider.get(ConfigKey.showflashback1MonthAgo) &&
          TimeManager.datesExactMonthDiff(entry.timeCreate, DateTime.now()) ==
              1) {
        flashbacks.putIfAbsent(
            AppLocalizations.of(context)!.flashbackMonth(1), () => entry);
        continue;
      }
      if (configProvider.get(ConfigKey.showflashback1WeekAgo) &&
          TimeManager.isSameDay(entry.timeCreate,
              DateTime.now().subtract(const Duration(days: 7)))) {
        flashbacks.putIfAbsent(
            AppLocalizations.of(context)!.flashbackWeek(1), () => entry);
        continue;
      }
      if (entry.mood == 1 || entry.mood == 2) {
        happyEntries.add(entry);
        continue;
      }
    }

    // Random Memories
    if (filteredEntries.length > 7) {
      int? seed = int.tryParse(
          "${DateTime.now().year}${DateTime.now().month}${DateTime.now().day}");

      // A happy memory
      if (configProvider.get(ConfigKey.showflashbackGoodDay)) {
        Random random = Random(seed);
        int index = 0;
        while (index < happyEntries.length) {
          Entry randomEntry = happyEntries[random.nextInt(happyEntries.length)];
          if (flashbacks.containsValue(randomEntry)) continue;
          flashbacks.putIfAbsent(AppLocalizations.of(context)!.flashbackGoodDay,
              () => randomEntry);
          break;
        }
      }

      // A random memory
      if (configProvider.get(ConfigKey.showflashbackRandomDay)) {
        Random random = Random(seed);
        int index = 0;
        while (index < filteredEntries.length) {
          Entry randomEntry =
              filteredEntries[random.nextInt(filteredEntries.length)];
          if (flashbacks.containsValue(randomEntry)) continue;
          flashbacks.putIfAbsent(
              AppLocalizations.of(context)!.flashbackRandomDay,
              () => randomEntry);
          break;
        }
      }
    }

    flashbacks.forEach((key, value) {
      flashbacksList.add(Flashback(title: key, entry: value));
    });
    return flashbacksList;
  }
}
