import 'dart:async';
import 'package:daily_you/config_manager.dart';
import 'package:daily_you/entries_database.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/stat_range_selector.dart';
import 'package:flutter/material.dart';

class StatsProvider with ChangeNotifier {
  static final StatsProvider instance = StatsProvider._init();

  StatsProvider._init();

  // Streaks
  int _currentStreak = 0;
  int get currentStreak => _currentStreak;

  int _longestStreak = 0;
  int get longestStreak => _longestStreak;

  int? _daysSinceBadDay = null;
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

  List<Entry> entries = List.empty();
  List<EntryImage> images = List.empty();

  String calendarViewMode = "mood";
  StatsRange statsRange = StatsRange.month;

  Future<void> updateStats() async {
    entries = await EntriesDatabase.instance.getAllEntries();
    images = await EntriesDatabase.instance.getAllEntryImages();
    calendarViewMode = ConfigManager.instance.getField('calendarViewMode');
    await getStreaks();
    await getMoodCounts();
    notifyListeners();
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

    var prevEntry = null;

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
                1) _currentStreak = activeStreak;
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
}
