import 'package:daily_you/database/entry_store.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/widgets/stat_range_selector.dart';
import 'package:flutter/material.dart';
import 'package:word_count/word_count.dart';

enum OrderBy { date, mood, tracker }

enum SortOrder { ascending, descending }

class EntriesProvider with ChangeNotifier {
  static final EntriesProvider instance = EntriesProvider._init();

  EntriesProvider._init() {
    _store.addListener(_onStoreChanged);
  }

  final EntryStore _store = EntryStore.instance;

  List<Entry> get entries => _store.entries;

  List<Entry> _filteredEntries = [];

  String _searchText = "";
  String get searchText => _searchText;

  set searchText(String newSearchText) {
    if (_searchText == newSearchText) return;
    _searchText = newSearchText;
    _calculateFilteredEntries();
    notifyListeners();
  }

  int _wordCount = 0;
  int get wordCount => _wordCount;

  OrderBy _orderBy = OrderBy.date;
  OrderBy get orderBy => _orderBy;

  set orderBy(OrderBy newOrderBy) {
    if (_orderBy == newOrderBy) return;
    _orderBy = newOrderBy;
    _calculateFilteredEntries();
    notifyListeners();
  }

  int? _trackerSortTagId;
  int? get trackerSortTagId => _trackerSortTagId;
  set trackerSortTagId(int? id) {
    if (_trackerSortTagId == id) return;
    _trackerSortTagId = id;
    notifyListeners();
  }

  SortOrder _sortOrder = SortOrder.descending;
  SortOrder get sortOrder => _sortOrder;

  set sortOrder(SortOrder newSortOrder) {
    if (_sortOrder == newSortOrder) return;
    _sortOrder = newSortOrder;
    _calculateFilteredEntries();
    notifyListeners();
  }

  Future<void> load() => _store.load();

  Future<Entry> add(Entry entry, {bool skipUpdate = false}) =>
      _store.add(entry, skipUpdate: skipUpdate);

  Future<void> update(Entry entry) => _store.update(entry);

  Future<void> remove(Entry entry) => _store.remove(entry);

  Future<void> deleteAll(Function(String) updateStatus) =>
      _store.deleteAll(updateStatus);

  int getIndexOfEntry(int entryId) => _store.getIndexOfEntry(entryId);

  Entry? getEntryForToday() => _store.getEntryForToday();

  Entry? getEntryForDate(DateTime date) => _store.getEntryForDate(date);

  List<Entry> getEntriesForDate(DateTime date) =>
      _store.getEntriesForDate(date);

  int getEntryDayCount() => _store.getEntryDayCount();

  bool hasEntryAtTimestamp(DateTime timestamp) =>
      _store.hasEntryAtTimestamp(timestamp);

  List<Entry> getFilteredEntries() => _filteredEntries;

  void _onStoreChanged() {
    _calculateWordCount();
    _calculateFilteredEntries();
    notifyListeners();
  }

  void _calculateFilteredEntries() {
    List<Entry> filteredEntries;
    if (_searchText.isNotEmpty) {
      filteredEntries = entries
          .where((entry) =>
              entry.text.toLowerCase().contains(_searchText.toLowerCase()))
          .toList();
    } else {
      filteredEntries = entries.toList();
    }

    if (_orderBy == OrderBy.mood) {
      filteredEntries.sort((a, b) {
        var aValue = a.mood ?? -999;
        var bValue = b.mood ?? -999;
        return bValue.compareTo(aValue);
      });
    }

    if (_sortOrder == SortOrder.ascending) {
      filteredEntries = filteredEntries.reversed.toList();
    }

    _filteredEntries = filteredEntries;
  }

  void _calculateWordCount() {
    _wordCount = 0;
    for (var entry in entries) {
      _wordCount += wordsCount(entry.text);
    }
  }

  List<Entry> getEntriesInRange(StatsRange statsRange) {
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
    var filteredEntries = entries.toList();
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

    // Handle empty state to prevent entries.first from throwing an error
    if (entries.isEmpty) {
      return (currentStreak, longestStreak, daysSinceBadDay);
    }

    // Helper: Converts local DateTime to a UTC midnight DateTime.
    // This completely eliminates DST drift by ensuring every calendar day difference
    // is calculated using consistent 24-hour blocks.
    DateTime toUtcMidnight(DateTime dt) =>
        DateTime.utc(dt.year, dt.month, dt.day);

    DateTime today = toUtcMidnight(DateTime.now());
    DateTime firstEntryDate = toUtcMidnight(entries.first.timeCreate);

    bool isFirstStreak = true;
    int activeStreak = 0;
    DateTime? prevDate;
    bool mostRecentBadDay = true;

    for (Entry entry in entries) {
      DateTime entryDate = toUtcMidnight(entry.timeCreate);

      // 1. Check for bad day
      if (mostRecentBadDay && entry.mood != null && entry.mood! < 0) {
        mostRecentBadDay = false;
        daysSinceBadDay = today.difference(entryDate).inDays;
      }

      // 2. Process streaks
      if (prevDate == null) {
        // Initialize with the very first valid entry
        activeStreak = 1;
        longestStreak = 1;
      } else if (prevDate != entryDate) {
        // Ignores multiple entries on the same day

        int daysDiff = prevDate.difference(entryDate).inDays;

        if (daysDiff == 1) {
          // Consecutive calendar day: increment streak
          activeStreak += 1;
          if (activeStreak > longestStreak) {
            longestStreak = activeStreak;
          }
        } else if (daysDiff > 1) {
          // Gap in days: streak broken
          if (isFirstStreak) {
            // The active streak only counts as the "Current Streak" if the most
            // recent logged entry was today or yesterday.
            if (today.difference(firstEntryDate).inDays <= 1) {
              currentStreak = activeStreak;
            }
            isFirstStreak = false;
          }
          // Reset active streak to 1 to track older historical sequences
          activeStreak = 1;
        }
      }

      // Keep track of the date we just processed
      prevDate = entryDate;
    }

    // If the loop finished and the first sequence never broke
    if (isFirstStreak) {
      if (today.difference(firstEntryDate).inDays <= 1) {
        currentStreak = activeStreak;
      }
    }

    return (currentStreak, longestStreak, daysSinceBadDay);
  }
}
