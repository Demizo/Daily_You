import 'dart:async';
import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/database/entry_dao.dart';
import 'package:daily_you/database/image_storage.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
import 'package:flutter/material.dart';

class EntriesProvider with ChangeNotifier {
  static final EntriesProvider instance = EntriesProvider._init();

  EntriesProvider._init();

  List<Entry> entries = List.empty();

  /// Load the provider's data from the app database
  Future<void> load() async {
    entries = await EntryDao.getAll();
    // TODO load stats provider
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

  Future<void> deleteAllEntries(Function(String) updateStatus) async {
    updateStatus("0%");

    var processedEntries = 0;
    for (Entry entry in entries) {
      var images = EntryImagesProvider.instance.getForEntry(entry.id!);
      for (final image in images) {
        await ImageStorage.instance.delete(image.imgPath);
        // TODO Don't update data until everything is deleted
        await EntryImagesProvider.instance.remove(image);
      }
      processedEntries += 1;
      updateStatus("${((processedEntries / entries.length) * 100).round()}%");
    }

    await EntryDao.removeAll();

    await StatsProvider.instance.updateStats();
    if (usingExternalDb()) await updateExternalDatabase();
  }
}
