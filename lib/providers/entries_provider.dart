import 'dart:async';
import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/database/entry_dao.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/stat_range_selector.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:word_count/word_count.dart';

enum OrderBy { date, mood }

enum SortOrder { ascending, descending }

class EntriesProvider with ChangeNotifier {
  static final EntriesProvider instance = EntriesProvider._init();

  EntriesProvider._init();

  List<Entry> entries = List.empty();

  StatsRange statsRange = StatsRange.month;

  // Used for filtered searches on the gallery page
  List<Entry> filteredEntries = List.empty();
  String searchText = "";
  OrderBy orderBy = OrderBy.date;
  SortOrder sortOrder = SortOrder.descending;

  // Used for preserving calendar state
  DateTime selectedDate = DateTime.now();

  /// Load the provider's data from the app database
  Future<void> load() async {
    entries = await EntryDao.getAll();
    notifyListeners();
  }

  // CRUD operations

  Future<void> add(Entry entry) async {
    // Insert the entry into the database so that it has an ID
    final entryWithId = await EntryDao.add(entry);
    entries.add(entryWithId);
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }

  Future<void> remove(Entry entry) async {
    await EntryDao.remove(entry.id!);
    entries.removeWhere((x) => x.id == entry.id);
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }

  Future<void> update(Entry entry) async {
    await EntryDao.update(entry);
    final index = entries.indexWhere((x) => x.id == entry.id);
    entries[index] = entry.copy();
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }

  Future<void> setStatsRange(StatsRange range) async {
    statsRange = range;
    getMoodTotals();
    notifyListeners();
  }

  Future<void> filterEntries() async {
    if (searchText.isNotEmpty) {
      filteredEntries = entries
          .where((entry) =>
              entry.text.toLowerCase().contains(searchText.toLowerCase()))
          .toList();
    }

    // Ordering by date is the default
    if (orderBy == OrderBy.mood) {
      filteredEntries.sort((a, b) {
        var aValue = a.mood ?? -999;
        var bValue = b.mood ?? -999;
        return bValue.compareTo(aValue);
      });
    }

    // Sorting is descending by default
    if (sortOrder == SortOrder.ascending) {
      filteredEntries = entries.reversed.toList();
    }

    notifyListeners();
  }

  int getWordCount() {
    var wordCount = 0;
    for (var entry in entries) {
      wordCount += wordsCount(entry.text);
    }
    return wordCount;
  }

  Map<int, int> getMoodTotals() {
    Map<int, int> moodTotals = {
      -2: 0,
      -1: 0,
      0: 0,
      1: 0,
      2: 0,
    };

    for (Entry entry in _getEntriesInRange()) {
      if (entry.mood == null) continue;
      moodTotals.update(
        entry.mood!,
        (value) => value + 1,
      );
    }

    return moodTotals;
  }

  Map<String, double> getMoodsByDay() {
    Map<String, List<double>> moodsByDay = {};

    var filteredEntries = _getEntriesInRange();
    for (Entry entry in filteredEntries) {
      if (entry.mood == null) continue;
      String dayKey = DateFormat('EEE').format(entry.timeCreate);

      if (moodsByDay[dayKey] == null) {
        moodsByDay[dayKey] = List.empty(growable: true);
        moodsByDay[dayKey]!.add(entry.mood!.toDouble());
      } else {
        moodsByDay[dayKey]!.add(entry.mood!.toDouble());
      }
    }

    // Average the mood for each day
    for (var key in moodsByDay.keys) {
      moodsByDay[key]!.first =
          moodsByDay[key]!.reduce((a, b) => a + b) / moodsByDay[key]!.length;
    }

    Map<String, double> averageMoodsByDay = {
      'Mon': -2,
      'Tue': -2,
      'Wed': -2,
      'Thu': -2,
      'Fri': -2,
      'Sat': -2,
      'Sun': -2,
    };

    for (String key in moodsByDay.keys) {
      if (moodsByDay[key] == null) {
        averageMoodsByDay[key] = -2;
      } else {
        averageMoodsByDay[key] = moodsByDay[key]!.first;
      }
    }

    return averageMoodsByDay;
  }

  List<Entry> _getEntriesInRange() {
    int filterMonthCount = 0;
    switch (statsRange) {
      case StatsRange.month:
        {
          filterMonthCount = 1;
          break;
        }
      case StatsRange.sixMonths:
        {
          filterMonthCount = 6;
          break;
        }
      case StatsRange.year:
        {
          filterMonthCount = 12;
          break;
        }
      case StatsRange.allTime:
        {
          filterMonthCount = 0;
          break;
        }
    }

    // Filter entries by time range
    var filteredEntries = entries;
    if (filterMonthCount > 0) {
      filteredEntries = filteredEntries.where((entry) {
        DateTime now = DateTime.now();
        DateTime monthsAgo =
            DateTime(now.year, now.month - filterMonthCount, now.day);
        return entry.timeCreate.isAfter(monthsAgo);
      }).toList();
    }

    return filteredEntries;
  }

  /// Calculates and returns the current streak, the longest streak, and the days since a bad day
  (int, int, int?) getStreaks() {
    int currentStreak = 0;
    int longestStreak = 0;
    int? daysSinceBadDay;

    var isFirstStreak = true;
    var activeStreak = 0;

    Entry? prevEntry;

    bool mostRecentBadDay = true;
    // TODO check if this order is correct
    entries.sort((a, b) => a.timeCreate.compareTo(b.timeCreate));
    for (Entry entry in entries) {
      // Check for bad day
      if (entry.mood != null && mostRecentBadDay) {
        if (entry.mood! < 0) {
          mostRecentBadDay = false;
          daysSinceBadDay = TimeManager.startOfDay(DateTime.now())
              .difference(TimeManager.startOfDay(entry.timeCreate))
              .inDays;
        }
      }

      // Increment current streak
      if (prevEntry != null &&
          TimeManager.startOfDay(prevEntry.timeCreate)
                  .difference(TimeManager.startOfDay(entry.timeCreate))
                  .inDays >
              1) {
        if (isFirstStreak &&
            TimeManager.startOfDay(DateTime.now())
                    .difference(
                        TimeManager.startOfDay(entries.first.timeCreate))
                    .inDays <=
                1) {
          currentStreak = activeStreak;
        }
        isFirstStreak = false;
        activeStreak = 1;
      } else {
        activeStreak += 1;
        if (activeStreak > longestStreak) {
          longestStreak = activeStreak;
        }
      }

      // Set the current streak if we have reached the end and are still on the first streak
      if (isFirstStreak && entry == entries.last) {
        currentStreak = activeStreak;
      }

      prevEntry = entry;
    }

    return (currentStreak, longestStreak, daysSinceBadDay);
  }

  // Helper functions

  int getIndexOfEntry(int entryId) {
    return entries.indexWhere((entry) => entry.id == entryId);
  }

  Entry? getEntryForToday() {
    Entry? todayEntry;
    if (entries.isNotEmpty && TimeManager.isToday(entries.first.timeCreate)) {
      todayEntry = entries.first;
    }
    return todayEntry;
  }

  Entry? getEntryForDate(DateTime date) {
    //Search each entry for one on the date
    for (var entry in entries) {
      if (entry.timeCreate.day == date.day &&
          entry.timeCreate.month == date.month &&
          entry.timeCreate.year == date.year) {
        return entry;
      }
    }

    return null;
  }
}
