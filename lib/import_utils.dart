import 'dart:convert';

import 'package:daily_you/entries_database.dart';
import 'package:daily_you/file_layer.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/stats_provider.dart';
import 'package:intl/intl.dart';

enum ImportFormat {
  none,
  dailyYouJson,
  oneShot,
  pixels,
}

class ImportUtils {
  static Future<bool> importFromJson(Function(String) updateStatus) async {
    updateStatus("0%");

    var selectedFile = await FileLayer.pickFile(
        allowedExtensions: ['json'], mimeTypes: ['application/json']);
    if (selectedFile == null) return false;

    var bytes = await FileLayer.getFileBytes(selectedFile);
    if (bytes == null) return false;
    final jsonData = json.decode(utf8.decode(bytes.toList()));

    final totalEntries = jsonData.length;
    var processedEntries = 0;

    for (var entry in jsonData) {
      // Skip if the day already has an entry
      if (await EntriesDatabase.instance
              .getEntryForDate(DateTime.parse(entry['timeCreated'])) ==
          null) {
        var addedEntry = await EntriesDatabase.instance.addEntry(
            Entry(
                text: entry['text'],
                mood: entry['mood'] as int?,
                timeCreate: DateTime.parse(entry['timeCreated']),
                timeModified: DateTime.parse(entry['timeModified'])),
            updateStatsAndSync: false);
        // Support old imgPath field
        if (entry['imgPath'] != null) {
          await EntriesDatabase.instance.addImg(
              EntryImage(
                  entryId: addedEntry.id,
                  imgPath: entry['imgPath'],
                  imgRank: 0,
                  timeCreate: DateTime.now()),
              updateStatsAndSync: false);
        }
        // Import images
        if (entry['images'] != null) {
          for (var img in entry['images']) {
            await EntriesDatabase.instance.addImg(
                EntryImage(
                    entryId: addedEntry.id,
                    imgPath: img['imgPath'],
                    imgRank: img['imgRank'] as int,
                    timeCreate: DateTime.parse(img['timeCreated'])),
                updateStatsAndSync: false);
          }
        }
      }
      processedEntries += 1;
      updateStatus("${((processedEntries / totalEntries) * 100).round()}%");
    }

    // Sync and update stats
    if (EntriesDatabase.instance.usingExternalDb()) {
      await EntriesDatabase.instance.syncDatabase();
    }
    if (EntriesDatabase.instance.usingExternalImg()) {
      await EntriesDatabase.instance.syncImageFolder(true);
    }
    StatsProvider.instance.updateStats();

    return true;
  }

  static Future<bool> importFromOneShot(Function(String) updateStatus) async {
    updateStatus("0%");

    var selectedFile = await FileLayer.pickFile(
        allowedExtensions: ['json'], mimeTypes: ['application/json']);
    if (selectedFile == null) return false;

    var bytes = await FileLayer.getFileBytes(selectedFile);
    if (bytes == null) return false;
    final jsonData = json.decode(utf8.decode(bytes.toList()));

    final happinessMapping = {
      "VERY_SAD": -2,
      "SAD": -1,
      "NEUTRAL": 0,
      "HAPPY": 1,
      "VERY_HAPPY": 2,
    };

    final totalEntries = jsonData.length;
    var processedEntries = 0;

    for (var entry in jsonData) {
      final createdTimestamp = entry['created'];
      final createdDateTime =
          DateTime.fromMillisecondsSinceEpoch(createdTimestamp * 1000);

      final happinessText = entry['happiness'];
      final mood = happinessMapping[happinessText];

      // Skip if the day already has an entry
      if (await EntriesDatabase.instance.getEntryForDate(createdDateTime) ==
          null) {
        var addedEntry = await EntriesDatabase.instance.addEntry(
            Entry(
                text: entry['textContent'],
                mood: mood,
                timeCreate: createdDateTime,
                timeModified: DateTime.now()),
            updateStatsAndSync: false);
        // Import image
        if (entry['relativePath'] != null) {
          await EntriesDatabase.instance.addImg(
              EntryImage(
                  entryId: addedEntry.id,
                  imgPath: entry['relativePath'],
                  imgRank: 0,
                  timeCreate: DateTime.now()),
              updateStatsAndSync: false);
        }
      }
      processedEntries += 1;
      updateStatus("${((processedEntries / totalEntries) * 100).round()}%");
    }

    // Sync and update stats
    if (EntriesDatabase.instance.usingExternalDb()) {
      await EntriesDatabase.instance.syncDatabase();
    }
    if (EntriesDatabase.instance.usingExternalImg()) {
      await EntriesDatabase.instance.syncImageFolder(true);
    }
    StatsProvider.instance.updateStats();

    return true;
  }

  static Future<bool> importFromPixels(Function(String) updateStatus) async {
    updateStatus("0%");

    var selectedFile = await FileLayer.pickFile(
        allowedExtensions: ['json'], mimeTypes: ['application/json']);
    if (selectedFile == null) return false;

    var bytes = await FileLayer.getFileBytes(selectedFile);
    if (bytes == null) return false;
    final jsonData = json.decode(utf8.decode(bytes.toList()));

    final totalEntries = jsonData.length;
    var processedEntries = 0;

    for (var entry in jsonData) {
      // Skip non-mood entries
      if (entry['type'] == 'Mood') {
        DateTime timeCreated = DateFormat("yyyy-MM-dd").parse(entry['date']);
        DateTime timeModified = DateTime.now();

        // Skip if the day already has an entry
        if (await EntriesDatabase.instance.getEntryForDate(timeCreated) ==
            null) {
          int avgMood =
              (entry['scores'] as List<dynamic>).reduce((a, b) => a + b) ~/
                  entry['scores'].length;
          // Convert mood from 1-5 scale to -2 to 2 scale
          int mappedMood = avgMood - 3;

          await EntriesDatabase.instance.addEntry(
              Entry(
                  text: entry['notes'] ?? '',
                  mood: mappedMood,
                  timeCreate: timeCreated,
                  timeModified: timeModified),
              updateStatsAndSync: false);
        }
      }
      processedEntries += 1;
      updateStatus("${((processedEntries / totalEntries) * 100).round()}%");
    }

    // Sync and update stats
    if (EntriesDatabase.instance.usingExternalDb()) {
      await EntriesDatabase.instance.syncDatabase();
    }
    if (EntriesDatabase.instance.usingExternalImg()) {
      await EntriesDatabase.instance.syncImageFolder(true);
    }
    StatsProvider.instance.updateStats();

    return true;
  }
}
