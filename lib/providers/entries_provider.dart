import 'dart:async';
import 'dart:io';
import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/database/entry_dao.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/notification_manager.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
import 'package:daily_you/providers/templates_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/stat_range_selector.dart';
import 'package:flutter/material.dart';
import 'package:word_count/word_count.dart';

enum OrderBy { date, mood }

enum SortOrder { ascending, descending }

class EntriesProvider with ChangeNotifier {
  static final EntriesProvider instance = EntriesProvider._init();

  EntriesProvider._init();

  List<Entry> entries = List.empty();

  Map<DateTime, Entry> _entriesByDay = {};

  String _searchText = "";
  String get searchText {
    return _searchText;
  }

  int _wordCount = 0;
  int get wordCount {
    return _wordCount;
  }

  set searchText(String newSearchText) {
    _searchText = newSearchText;
    notifyListeners();
  }

  OrderBy _orderBy = OrderBy.date;
  OrderBy get orderBy {
    return _orderBy;
  }

  set orderBy(OrderBy newOrderBy) {
    _orderBy = newOrderBy;
    notifyListeners();
  }

  SortOrder _sortOrder = SortOrder.descending;
  SortOrder get sortOrder {
    return _sortOrder;
  }

  set sortOrder(SortOrder newSortOrder) {
    _sortOrder = newSortOrder;
    notifyListeners();
  }

  // Used for preserving calendar state
  DateTime selectedDate = DateTime.now();

  /// Load the provider's data from the app database
  Future<void> load() async {
    entries = await EntryDao.getAll();
    _calculateWordCount();
    _calculateEntriesByDay();
    notifyListeners();
  }

  // CRUD operations

  Future<Entry> add(Entry entry) async {
    // Insert the entry into the database so that it has an ID
    final entryWithId = await EntryDao.add(entry);
    entries.add(entryWithId);
    // Reverse chronological order such that the most recent day is first
    entries.sort((a, b) => compareDateOnly(b.timeCreate, a.timeCreate));
    await AppDatabase.instance.updateExternalDatabase();

    // Update stats
    _calculateWordCount();
    _calculateEntriesByDay();

    notifyListeners();
    return entryWithId;
  }

  Future<void> update(Entry entry) async {
    await EntryDao.update(entry);
    final index = entries.indexWhere((x) => x.id == entry.id);
    entries[index] = entry;
    // Reverse chronological order such that the most recent day is first
    entries.sort((a, b) => compareDateOnly(b.timeCreate, a.timeCreate));
    await AppDatabase.instance.updateExternalDatabase();

    // Update stats
    _calculateWordCount();
    _calculateEntriesByDay();

    notifyListeners();
  }

  Future<void> remove(Entry entry) async {
    await EntryDao.remove(entry.id!);
    entries.removeWhere((x) => x.id == entry.id);
    await AppDatabase.instance.updateExternalDatabase();

    // Update stats
    _calculateWordCount();
    _calculateEntriesByDay();

    notifyListeners();
  }

  Future<Entry> createNewEntry(DateTime? timeCreate) async {
    var text = "";
    final defaultTemplate = TemplatesProvider.instance.getDefaultTemplate();
    if (defaultTemplate != null) {
      text = defaultTemplate.text ?? "";
    }

    final newEntry = Entry(
      text: text,
      mood: null,
      timeCreate: timeCreate ?? DateTime.now(),
      timeModified: DateTime.now(),
    );

    if (Platform.isAndroid &&
        TimeManager.isSameDay(DateTime.now(), newEntry.timeCreate)) {
      await NotificationManager.instance.dismissReminderNotification();
    }

    return await add(newEntry);
  }

  Future<void> deleteAll(Function(String) updateStatus) async {
    updateStatus("0%");
    var processedEntries = 0;
    for (Entry entry in entries) {
      var images = EntryImagesProvider.instance.getForEntry(entry);
      for (final image in images) {
        await EntryImagesProvider.instance.remove(image);
      }
      processedEntries += 1;
      // The provider's remove function is not used to avoid editing the entries
      // list while iterating over it.
      await EntryDao.remove(entry.id!);
      updateStatus("${((processedEntries / entries.length) * 100).round()}%");
    }

    // Reload the provider since all entries have been deleted
    await load();
    await AppDatabase.instance.updateExternalDatabase();
  }

  int compareDateOnly(DateTime a, DateTime b) {
    if (a.year != b.year) return a.year.compareTo(b.year);
    if (a.month != b.month) return a.month.compareTo(b.month);
    return a.day.compareTo(b.day);
  }

  /// Set the selected date and update listening widgets
  void setSelectedDate(DateTime date) {
    selectedDate = date;
    notifyListeners();
  }

  List<Entry> getFilteredEntries() {
    List<Entry> filteredEntries;
    // Make a copy of the entries list
    if (_searchText.isNotEmpty) {
      filteredEntries = entries
          .where((entry) =>
              entry.text.toLowerCase().contains(_searchText.toLowerCase()))
          .toList();
    } else {
      filteredEntries = entries.toList();
    }

    // Ordering by date is the default
    if (_orderBy == OrderBy.mood) {
      filteredEntries.sort((a, b) {
        var aValue = a.mood ?? -999;
        var bValue = b.mood ?? -999;
        return bValue.compareTo(aValue);
      });
    }

    // Sorting is descending by default
    if (_sortOrder == SortOrder.ascending) {
      filteredEntries = filteredEntries.reversed.toList();
    }

    return filteredEntries;
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

    var isFirstStreak = true;
    var activeStreak = 0;

    Entry? prevEntry;

    bool mostRecentBadDay = true;
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

  void _calculateEntriesByDay() {
    _entriesByDay = {
      for (final e in entries)
        DateTime(e.timeCreate.year, e.timeCreate.month, e.timeCreate.day): e
    };
  }

  Entry? getEntryForDate(DateTime date) {
    final target = DateTime(date.year, date.month, date.day);
    if (_entriesByDay.containsKey(target)) {
      return _entriesByDay[target];
    } else {
      return null;
    }
  }
}
