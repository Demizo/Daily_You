import 'dart:math';

import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/flashback.dart';
import 'package:daily_you/time_manager.dart';

class FlashbackManager {
  static List<Flashback> getFlashbacks(List<Entry> entries) {
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
        var yearLabel = yearsAgo == 1 ? '1 Year Ago' : '$yearsAgo Years Ago';
        flashbacks.putIfAbsent(yearLabel, () => entry);
        continue;
      }
      if (TimeManager.datesExactMonthDiff(entry.timeCreate, DateTime.now()) ==
          6) {
        flashbacks.putIfAbsent('6 Months Ago', () => entry);
        continue;
      }
      if (TimeManager.datesExactMonthDiff(entry.timeCreate, DateTime.now()) ==
          1) {
        flashbacks.putIfAbsent('1 Month Ago', () => entry);
        continue;
      }
      if (TimeManager.isSameDay(
          entry.timeCreate, DateTime.now().subtract(const Duration(days: 7)))) {
        flashbacks.putIfAbsent('1 Week Ago', () => entry);
        continue;
      }
      if (entry.mood == 1 || entry.mood == 2) {
        happyEntries.add(entry);
        continue;
      }
    }

    // Random Memories
    int? seed = int.tryParse(
        "${DateTime.now().year}${DateTime.now().month}${DateTime.now().day}");

    // A happy memory
    Random random = Random(seed);
    int index = 0;
    while (index < happyEntries.length) {
      Entry randomEntry = happyEntries[random.nextInt(happyEntries.length)];
      if (flashbacks.containsValue(randomEntry)) continue;
      flashbacks.putIfAbsent('A Happy Day', () => randomEntry);
      break;
    }

    // A random memory
    if (entries.length > 7) {
      random = Random(seed);
      index = 0;
      while (index < entries.length) {
        Entry randomEntry = entries[random.nextInt(entries.length)];
        if (flashbacks.containsValue(randomEntry)) continue;
        flashbacks.putIfAbsent('A Random Day', () => randomEntry);
        break;
      }
    }

    flashbacks.forEach((key, value) {
      flashbacksList.add(Flashback(title: key, entry: value));
    });
    return flashbacksList;
  }
}
