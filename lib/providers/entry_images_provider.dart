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

  /// Load the provider's data from the app database
  Future<void> load() async {
    images = await EntryImageDao.getAll();
    notifyListeners();
  }

  // CRUD operations

  Future<void> add(EntryImage image) async {
    // Insert the image into the database so that it has an ID
    final imageWithId = await EntryImageDao.add(image);
    images.add(imageWithId);
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }

  Future<void> remove(EntryImage image) async {
    await EntryImageDao.remove(image);
    images.removeWhere((x) => x.id == image.id);
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }

  Future<void> update(EntryImage image) async {
    await EntryImageDao.update(image);
    final index = images.indexWhere((x) => x.id == image.id);
    images[index] = image;
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }

  /// Get the images for a given entry
  ///
  /// Images are sorted by image rank where the highest number is first.
  List<EntryImage> getForEntry(Entry entry) {
    final imagesForEntry =
        images.where((img) => img.entryId == entry.id!).toList();
    // Reverse order such that the highest rank is the first in the list
    imagesForEntry.sort((a, b) => b.imgRank.compareTo(a.imgRank));
    return imagesForEntry;
  }
}
