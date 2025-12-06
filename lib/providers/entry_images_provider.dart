import 'dart:async';
import 'package:daily_you/database/entry_image_dao.dart';
import 'package:daily_you/entries_database.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/image.dart';
import 'package:flutter/material.dart';

class EntryImagesProvider with ChangeNotifier {
  static final EntryImagesProvider instance = EntryImagesProvider._init();

  EntryImagesProvider._init();

  List<EntryImage> images = List.empty();

  /// Load the provider's data from the app database
  Future<void> load() async {
    images = await EntriesDatabase.instance.getAllEntryImages();
    notifyListeners();
  }

  // CRUD operations

  Future<void> add(EntryImage image) async {
    // Insert the image into the database so that it has an ID
    final imageWithId = await EntryImageDao.add(image);
    images.add(imageWithId);
    // TODO trigger sync
  }

  // TODO add other CRUD operations

  /// Get the images for a given entry
  ///
  /// Images are sorted by image rank where the highest number is first.
  List<EntryImage> getForEntry(Entry entry) {
    final imagesForEntry =
        images.where((img) => img.entryId == entry.id!).toList();
    // TODO double check that this is the correct order
    imagesForEntry.sort((a, b) => b.imgRank.compareTo(a.imgRank));
    return imagesForEntry;
  }
}
