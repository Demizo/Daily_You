import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/flashback.dart';
import 'package:daily_you/time_manager.dart';

class FlashbackManager {
  static List<Flashback> getFlashbacks(BuildContext context, List<Entry> entries) {
    List<Flashback> flashbacksList = List.empty(growable: true);
    Map<String, Entry> flashbacks = {};

    List<Entry> happyEntries = List.empty(growable: true);

    if (entries.isEmpty) return flashbacksList;

    // Time based memories
    for (var entry in entries.reversed.toList()) {
      if (flashbacks.containsValue(entry)) continue;
      if (entry.timeCreate.day == DateTime.now().day &&
          entry.timeCreate.month == DateTime.now().month &&
          entry.timeCreate.year != DateTime.now().year) {
        var yearsAgo = DateTime.now().year - entry.timeCreate.year;
        flashbacks.putIfAbsent(AppLocalizations.of(context)!.flashbackYear(yearsAgo), () => entry);
        continue;
      }
      if (TimeManager.datesExactMonthDiff(entry.timeCreate, DateTime.now()) ==
          6) {
        flashbacks.putIfAbsent(AppLocalizations.of(context)!.flashbackMonth(6), () => entry);
        continue;
      }
      if (TimeManager.datesExactMonthDiff(entry.timeCreate, DateTime.now()) ==
          1) {
        flashbacks.putIfAbsent(AppLocalizations.of(context)!.flashbackMonth(1), () => entry);
        continue;
      }
      if (TimeManager.isSameDay(
          entry.timeCreate, DateTime.now().subtract(const Duration(days: 7)))) {
        flashbacks.putIfAbsent(AppLocalizations.of(context)!.flashbackWeek(1), () => entry);
        continue;
      }
      if (entry.mood == 1 || entry.mood == 2) {
        happyEntries.add(entry);
        continue;
      }
    }

    // Random Memories
    if (entries.length > 7) {
      int? seed = int.tryParse(
          "${DateTime.now().year}${DateTime.now().month}${DateTime.now().day}");

      // A happy memory
      Random random = Random(seed);
      int index = 0;
      while (index < happyEntries.length) {
        Entry randomEntry = happyEntries[random.nextInt(happyEntries.length)];
        if (flashbacks.containsValue(randomEntry)) continue;
        flashbacks.putIfAbsent(AppLocalizations.of(context)!.flashbackGoodDay, () => randomEntry);
        break;
      }

      // A random memory
      random = Random(seed);
      index = 0;
      while (index < entries.length) {
        Entry randomEntry = entries[random.nextInt(entries.length)];
        if (flashbacks.containsValue(randomEntry)) continue;
        flashbacks.putIfAbsent(AppLocalizations.of(context)!.flashbackRandomDay, () => randomEntry);
        break;
      }
    }

    flashbacks.forEach((key, value) {
      flashbacksList.add(Flashback(title: key, entry: value));
    });
    return flashbacksList;
  }
}
