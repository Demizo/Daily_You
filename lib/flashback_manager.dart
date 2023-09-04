import 'package:daily_you/entries_database.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/flashback.dart';
import 'package:daily_you/time_manager.dart';

class FlashbackManager {
  static Future<List<Flashback>> getFlashbacks() async {
    List<Flashback> flashbacksList = List.empty(growable: true);
    Map<String, Entry> flashbacks = {};

    var entries = await EntriesDatabase.instance.getAllEntries();
    List<Entry> happyEntries = List.empty(growable: true);

    if (entries.isEmpty) return flashbacksList;

    // Time based memories
    for (var entry in entries) {
      if (flashbacks.containsValue(entry)) continue;
      if (TimeManager.isToday(entry.timeCreate)) {
        flashbacks.putIfAbsent('Today', () => entry);
        continue;
      }
      if (TimeManager.isSameDay(
          entry.timeCreate, DateTime.now().subtract(const Duration(days: 1)))) {
        flashbacks.putIfAbsent('Yesterday', () => entry);
        continue;
      }
      if (TimeManager.isSameDay(
          entry.timeCreate, DateTime.now().subtract(const Duration(days: 7)))) {
        flashbacks.putIfAbsent('1 Week Ago', () => entry);
        continue;
      }
      if (entry.timeCreate.day == DateTime.now().day &&
          entry.timeCreate.month == DateTime.now().month &&
          entry.timeCreate.year != DateTime.now().year) {
        var yearsAgo = DateTime.now().year - entry.timeCreate.year;
        var yearLabel = yearsAgo == 1 ? '1 Year Ago' : '$yearsAgo Years Ago';
        flashbacks.putIfAbsent(yearLabel, () => entry);
        continue;
      }
      if (TimeManager.datesExactMonthDiff(entry.timeCreate, DateTime.now()) ==
          1) {
        flashbacks.putIfAbsent('1 Month Ago', () => entry);
        continue;
      }
      if (TimeManager.datesExactMonthDiff(entry.timeCreate, DateTime.now()) ==
          6) {
        flashbacks.putIfAbsent('6 Months Ago', () => entry);
        continue;
      }
      if (entry.mood == 1 || entry.mood == 2) {
        happyEntries.add(entry);
        continue;
      }
    }

    // Random Memories

    // A happy memory
    happyEntries.shuffle();
    for (var entry in happyEntries) {
      if (flashbacks.containsValue(entry)) continue;
      flashbacks.putIfAbsent('A Happy Day', () => entry);
      break;
    }

    // A random memory
    entries.shuffle();
    for (var entry in entries) {
      if (flashbacks.containsValue(entry)) continue;
      flashbacks.putIfAbsent('A Random Day', () => entry);
      break;
    }

    flashbacks.forEach((key, value) {
      flashbacksList.add(Flashback(title: key, entry: value));
    });
    return flashbacksList;
  }
}
