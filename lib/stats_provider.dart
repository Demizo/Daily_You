import 'dart:async';

import 'package:daily_you/entries_database.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/time_manager.dart';
import 'package:flutter/material.dart';

class StatsProvider with ChangeNotifier {
  static final StatsProvider instance = StatsProvider._init();

  StatsProvider._init();

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

  List<Entry> entries = List.empty();

  Future<void> updateStats() async {
    entries = await EntriesDatabase.instance.getAllEntries();
    await getStreaks();
    notifyListeners();
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
