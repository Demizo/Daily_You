import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/database/entry_dao.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:flutter/foundation.dart';

class EntryStore with ChangeNotifier {
  static final EntryStore instance = EntryStore._init();

  EntryStore._init();

  List<Entry> entries = List.empty(growable: true);

  Map<DateTime, List<Entry>> _entriesByDay = {};

  Future<void> load() async {
    entries = await EntryDao.getAll();
    _indexEntriesByDay();
    notifyListeners();
  }

  Future<Entry> add(Entry entry, {bool skipUpdate = false}) async {
    final entryWithId = await EntryDao.add(entry);
    entries.add(entryWithId);
    await AppDatabase.instance.updateExternalDatabase();

    if (!skipUpdate) {
      _sortEntries();
      _indexEntriesByDay();
      notifyListeners();
    }
    return entryWithId;
  }

  Future<void> update(Entry entry) async {
    await EntryDao.update(entry);
    final index = getIndexOfEntry(entry.id!);
    entries[index] = entry;
    _sortEntries();
    await AppDatabase.instance.updateExternalDatabase();

    _indexEntriesByDay();
    notifyListeners();
  }

  Future<void> remove(Entry entry) async {
    await EntryDao.remove(entry.id!);
    entries.removeWhere((existing) => existing.id == entry.id);
    await AppDatabase.instance.updateExternalDatabase();

    _indexEntriesByDay();
    notifyListeners();
  }

  Future<void> deleteAll(Function(String) updateStatus) async {
    updateStatus("0%");
    var processedEntries = 0;
    for (Entry entry in entries) {
      var images = EntryImagesProvider.instance.getForEntry(entry);
      for (final image in images) {
        await EntryImagesProvider.instance.remove(image);
      }
      await TagsProvider.instance.removeAllEntryTagsForEntry(entry.id!);
      processedEntries += 1;
      // The store's remove function is not used to avoid editing the entries
      // list while iterating over it.
      await EntryDao.remove(entry.id!);
      updateStatus("${((processedEntries / entries.length) * 100).round()}%");
    }

    await load();
    await AppDatabase.instance.updateExternalDatabase();
  }

  int getIndexOfEntry(int entryId) {
    return entries.indexWhere((entry) => entry.id == entryId);
  }

  Entry? getEntryForToday() {
    if (entries.isNotEmpty && TimeManager.isToday(entries.first.timeCreate)) {
      return entries.first;
    }
    return null;
  }

  Entry? getEntryForDate(DateTime date) {
    return getEntriesForDate(date).firstOrNull;
  }

  List<Entry> getEntriesForDate(DateTime date) {
    return _entriesByDay[DateTime(date.year, date.month, date.day)] ?? const [];
  }

  int getEntryDayCount() => _entriesByDay.length;

  bool hasEntryAtTimestamp(DateTime timestamp) {
    return entries.any((entry) => entry.timeCreate == timestamp);
  }

  void _sortEntries() {
    entries.sort((a, b) => _compareDateOnly(b.timeCreate, a.timeCreate));
  }

  void _indexEntriesByDay() {
    final index = <DateTime, List<Entry>>{};
    for (final entry in entries) {
      final key = DateTime(
          entry.timeCreate.year, entry.timeCreate.month, entry.timeCreate.day);
      index.putIfAbsent(key, () => []).add(entry);
    }
    _entriesByDay = index;
  }
}

int _compareDateOnly(DateTime a, DateTime b) {
  if (a.year != b.year) return a.year.compareTo(b.year);
  if (a.month != b.month) return a.month.compareTo(b.month);
  if (a.day != b.day) return a.day.compareTo(b.day);
  if (a.hour != b.hour) return a.hour.compareTo(b.hour);
  return a.minute.compareTo(b.minute);
}
