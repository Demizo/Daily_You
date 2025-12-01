import 'dart:async';
import 'package:daily_you/entries_database.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/image.dart';
import 'package:flutter/material.dart';

class ImagesProvider with ChangeNotifier {
  static final ImagesProvider instance = ImagesProvider._init();

  ImagesProvider._init();

  List<EntryImage> images = List.empty();

  Future<void> update() async {
    images = await EntriesDatabase.instance.getAllEntryImages();
    notifyListeners();
  }

  List<EntryImage> getImagesForEntry(Entry entry) {
    return images.where((img) => img.entryId == entry.id!).toList();
  }
}
