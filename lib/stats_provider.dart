import 'dart:async';
import 'package:daily_you/entries_database.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/time_manager.dart';
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

  DateTime _referenceDay = DateTime.now();
  set referenceDay(DateTime dateTime) {
    _referenceDay = dateTime;
  }

  // Moods
  Map<int, int> _moodCountsAllTime = {
    -2: 0,
    -1: 0,
    0: 0,
    1: 0,
    2: 0,
  };
  Map<int, int> get moodCountsAllTime => _moodCountsAllTime;
  Map<int, int> _moodCountsThisMonth = {
    -2: 0,
    -1: 0,
    0: 0,
    1: 0,
    2: 0,
  };
  Map<int, int> get moodCountsThisMonth => _moodCountsThisMonth;

  List<Entry> entries = List.empty();

  Future<void> updateStats() async {
    entries = await EntriesDatabase.instance.getAllEntries();
    await getStreaks();
    await getMoodCounts(_referenceDay);
    notifyListeners();
  }

  Future<void> getMoodCounts(DateTime referenceTime) async {
    // Reset mood counts
    _resetMoodCounts();
    for (Entry entry in entries) {
      if (entry.mood == null) continue;
      _moodCountsAllTime.update(
        entry.mood!,
        (value) => _moodCountsAllTime[entry.mood!]! + 1,
      );
      if (TimeManager.isSameMonth(entry.timeCreate, referenceTime)) {
        _moodCountsThisMonth.update(
          entry.mood!,
          (value) => _moodCountsThisMonth[entry.mood!]! + 1,
        );
      }
    }
  }

  void _resetMoodCounts() {
    _moodCountsAllTime = {
      -2: 0,
      -1: 0,
      0: 0,
      1: 0,
      2: 0,
    };
    _moodCountsThisMonth = {
      -2: 0,
      -1: 0,
      0: 0,
      1: 0,
      2: 0,
    };
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
