import 'dart:async';
import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/database/entry_image_dao.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/image.dart';
import 'package:flutter/material.dart';

class EntryImagesProvider with ChangeNotifier {
  static final EntryImagesProvider instance = EntryImagesProvider._init();

  EntryImagesProvider._init();

  List<EntryImage> images = List.empty();
  Map<int, EntryImage?> _firstImageByEntryId = {};

  void _rebuildCache() {
    final cache = <int, EntryImage?>{};
    for (final img in images) {
      final id = img.entryId;
      if (id == null) continue;
      final existing = cache[id];
      if (existing == null || img.imgRank > existing.imgRank) {
        cache[id] = img;
      }
    }
    _firstImageByEntryId = cache;
  }

  /// Load the provider's data from the app database
  Future<void> load() async {
    images = await EntryImageDao.getAll();
    _rebuildCache();
    notifyListeners();
  }

  // CRUD operations

  Future<void> add(EntryImage image, {skipUpdate = false}) async {
    final imageWithId = await EntryImageDao.add(image);
    images.add(imageWithId);
    _rebuildCache();
    await AppDatabase.instance.updateExternalDatabase();
    if (!skipUpdate) {
      notifyListeners();
    }
  }

  Future<void> remove(EntryImage image) async {
    await EntryImageDao.remove(image);
    images.removeWhere((x) => x.id == image.id);
    _rebuildCache();
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }

  Future<void> update(EntryImage image) async {
    await EntryImageDao.update(image);
    final index = images.indexWhere((x) => x.id == image.id);
    images[index] = image;
    _rebuildCache();
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }

  EntryImage? getFirstImageForEntry(int entryId) =>
      _firstImageByEntryId[entryId];

  /// Get the images for a given entry, sorted by rank descending.
  List<EntryImage> getForEntry(Entry entry) {
    final imagesForEntry =
        images.where((img) => img.entryId == entry.id!).toList();
    imagesForEntry.sort((a, b) => b.imgRank.compareTo(a.imgRank));
    return imagesForEntry;
  }
}
