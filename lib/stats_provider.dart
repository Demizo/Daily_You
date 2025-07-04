import 'dart:async';
import 'package:daily_you/entries_database.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/stat_range_selector.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum OrderBy { date, mood }

enum SortOrder { ascending, descending }

class StatsProvider with ChangeNotifier {
  static final StatsProvider instance = StatsProvider._init();

  StatsProvider._init();

  // Streaks
  int _currentStreak = 0;
  int get currentStreak => _currentStreak;

  int _longestStreak = 0;
  int get longestStreak => _longestStreak;

  int? _daysSinceBadDay;
  int? get daysSinceBadDay => _daysSinceBadDay;

  int totalEntries = 0;
  int syncedEntries = 0;

  void updateSyncStats(int total, int synced) {
    totalEntries = total;
    syncedEntries = synced;
    notifyListeners();
  }

  // Moods
  Map<int, int> moodTotals = {
    -2: 0,
    -1: 0,
    0: 0,
    1: 0,
    2: 0,
  };

  DateTime selectedDate = DateTime.now();

  void forceUpdate() {
    notifyListeners();
  }

  List<Entry> entries = List.empty();
  List<EntryImage> images = List.empty();

  StatsRange statsRange = StatsRange.month;

  int wordCount = 0;

  // Used for filtered searches on the gallery page
  List<Entry> filteredEntries = List.empty();
  String searchText = "";
  OrderBy orderBy = OrderBy.date;
  SortOrder sortOrder = SortOrder.descending;

  List<Entry> filterEntries(List<Entry> entries) {
    if (searchText.length > 2) {
      entries = entries
          .where((entry) =>
              entry.text.toLowerCase().contains(searchText.toLowerCase()))
          .toList();
    }

    // Ordering by date is the default
    if (orderBy == OrderBy.mood) {
      entries.sort((a, b) {
        var aValue = a.mood ?? -999;
        var bValue = b.mood ?? -999;
        return bValue.compareTo(aValue);
      });
    }

    // Sorting is descending by default
    if (sortOrder == SortOrder.ascending) {
      entries = entries.reversed.toList();
    }

    return entries;
  }

  Future<void> updateStats() async {
    entries = await EntriesDatabase.instance.getAllEntries();
    filteredEntries = filterEntries(entries);
    images = await EntriesDatabase.instance.getAllEntryImages();
    getWordCount();
    await getStreaks();
    await getMoodCounts();
    notifyListeners();
  }

  void getWordCount() {
    wordCount = 0;
    for (var entry in entries) {
      final RegExp regex = RegExp(r'\w+');
      wordCount += regex.allMatches(entry.text).length;
    }
  }

  Future<void> getMoodCounts() async {
    // Reset mood counts
    _resetMoodCounts();
    for (Entry entry in getEntriesInRange()) {
      if (entry.mood == null) continue;
      moodTotals.update(
        entry.mood!,
        (value) => moodTotals[entry.mood!]! + 1,
      );
    }
  }

  void _resetMoodCounts() {
    moodTotals = {
      -2: 0,
      -1: 0,
      0: 0,
      1: 0,
      2: 0,
    };
  }

  Map<String, double> getMoodsByDay() {
    Map<String, List<double>> moodsByDay = {};

    var filteredEntries = getEntriesInRange();
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

  int getIndexOfEntry(int entryId) {
    return entries.indexWhere((entry) => entry.id == entryId);
  }

  List<Entry> getEntriesInRange() {
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

  Future getStreaks() async {
    _currentStreak = 0;
    _longestStreak = 0;
    _daysSinceBadDay = null;

    var isFirstStreak = true;
    var activeStreak = 0;

    Entry? prevEntry;

    bool mostRecentBadDay = true;
    for (Entry entry in entries) {
      // Check for bad day
      if (entry.mood != null && mostRecentBadDay) {
        if (entry.mood! < 0) {
          mostRecentBadDay = false;
          _daysSinceBadDay = TimeManager.startOfDay(DateTime.now())
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
          _currentStreak = activeStreak;
        }
        isFirstStreak = false;
        activeStreak = 1;
      } else {
        activeStreak += 1;
        if (activeStreak > longestStreak) {
          _longestStreak = activeStreak;
        }
      }

      // Set the current streak if we have reached the end and are still on the first streak
      if (isFirstStreak && entry == entries.last) {
        _currentStreak = activeStreak;
      }

      prevEntry = entry;
    }
  }

  Entry? getEntryForToday() {
    Entry? todayEntry;
    if (entries.isNotEmpty && TimeManager.isToday(entries.first.timeCreate)) {
      todayEntry = entries.first;
    }
    return todayEntry;
  }

  List<EntryImage> getImagesForEntry(Entry entry) {
    return images.where((img) => img.entryId == entry.id!).toList();
  }
}
