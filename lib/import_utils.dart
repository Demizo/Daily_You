import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:daily_you/entries_database.dart';
import 'package:daily_you/file_layer.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/stats_provider.dart';
import 'package:daily_you/utils/zip_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:sqflite/sqflite.dart';
import 'package:html2md/html2md.dart' as html2md;

enum ImportFormat {
  none,
  dailyYouJson,
  daylio,
  diarium,
  myBrain,
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

  static Future<bool> importFromMyBrain(Function(String) updateStatus) async {
    updateStatus("0%");

    bool success = true;

    try {
      var selectedFile = await FileLayer.pickFile(
          allowedExtensions: ['json'], mimeTypes: ['application/json']);
      if (selectedFile == null) return false;

      var bytes = await FileLayer.getFileBytes(selectedFile);
      if (bytes == null) return false;
      final jsonData = json.decode(utf8.decode(bytes.toList()));

      final moodMap = {
        'TERRIBLE': -2,
        'BAD': -1,
        'OKAY': 0,
        'GOOD': 1,
        'AWESOME': 2,
      };

      // Group entries by date (yyyy-MM-dd)
      Map<String, List<Map<String, dynamic>>> groupedByDay = {};

      for (var entry in jsonData['diary']) {
        final date = DateTime.fromMillisecondsSinceEpoch(entry['createdDate'],
            isUtc: true);
        final dateKey =
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

        groupedByDay.putIfAbsent(dateKey, () => []).add(entry);
      }

      final totalDays = groupedByDay.length;
      var processedDays = 0;

      for (var entryList in groupedByDay.values) {
        final contents = <String>[];
        final moods = <int>[];
        DateTime? earliestCreated;
        DateTime? latestModified;

        for (var entry in entryList) {
          final title = entry['title'];
          final content = entry['content'];
          if (title != null) {
            contents.add("# $title");
          }
          if (content != null) {
            contents.add(content);
          }

          int? mappedMood;
          final mood = entry['mood'];
          if (mood != null) {
            mappedMood = moodMap[entry['mood']];
          }

          if (mappedMood != null) {
            moods.add(mappedMood);
          }

          final created = DateTime.fromMillisecondsSinceEpoch(
                  entry['createdDate'],
                  isUtc: true)
              .toLocal();
          final updated = DateTime.fromMillisecondsSinceEpoch(
                  entry['updatedDate'],
                  isUtc: true)
              .toLocal();

          if (earliestCreated == null || created.isBefore(earliestCreated)) {
            earliestCreated = created;
          }

          if (latestModified == null || updated.isAfter(latestModified)) {
            latestModified = updated;
          }
        }

        int? averageMood;
        if (moods.isNotEmpty) {
          averageMood = (moods.reduce((a, b) => a + b) / moods.length).round();
        }
        String? combinedText;
        if (contents.isNotEmpty) {
          combinedText = contents.join("\n\n");
        }

        // Only add if there’s no entry already on this date
        if (await EntriesDatabase.instance.getEntryForDate(earliestCreated!) ==
            null) {
          await EntriesDatabase.instance.addEntry(
            Entry(
              text: combinedText ?? '',
              mood: averageMood,
              timeCreate: earliestCreated,
              timeModified: latestModified!,
            ),
            updateStatsAndSync: false,
          );
        }

        processedDays += 1;
        updateStatus("${((processedDays / totalDays) * 100).round()}%");
      }
    } catch (e) {
      updateStatus("$e");
      await Future.delayed(Duration(seconds: 5));
      success = false;
    }

    // Sync and update stats
    if (EntriesDatabase.instance.usingExternalDb()) {
      await EntriesDatabase.instance.syncDatabase();
    }
    if (EntriesDatabase.instance.usingExternalImg()) {
      await EntriesDatabase.instance.syncImageFolder(true);
    }
    StatsProvider.instance.updateStats();

    return success;
  }

  static DateTime diariumIdToDateTime(int ticks) {
    const int ticksAtUnixEpoch = 621355968000000000;
    final usSinceEpoch = ((ticks - ticksAtUnixEpoch) / 10).round();
    return DateTime.fromMicrosecondsSinceEpoch(usSinceEpoch, isUtc: false);
  }

  static Future<bool> importFromDiarium(
      BuildContext context, Function(String) updateStatus) async {
    updateStatus("0%");

    var tempDir = await getTemporaryDirectory();
    final tempDbName = "temp_diarium.db";
    Database? db;
    bool success = true;

    try {
      final dbPath = await FileLayer.pickFile();
      if (dbPath == null) return false;

      // Transfer DB to local storage
      updateStatus(AppLocalizations.of(context)!.tranferStatus("0"));
      await FileLayer.copyFromExternalLocation(dbPath, tempDir.path, tempDbName,
          onProgress: (percent) {
        updateStatus(
            AppLocalizations.of(context)!.tranferStatus("${percent.round()}"));
      });

      db = await openDatabase(join(tempDir.path, tempDbName), readOnly: true);
      final entries = await db.rawQuery('SELECT * FROM Entries');
      final media = await db.rawQuery('SELECT * FROM Media WHERE Type = 0');

      // Group entries by date key (yyyy-MM-dd)
      final Map<String, List<Map<String, Object?>>> entriesByDate = {};
      final Map<int, DateTime> idToTimestamp = {};

      for (final entry in entries) {
        final id = entry['DiaryEntryId'] as int;
        final timestamp = diariumIdToDateTime(id);
        idToTimestamp[id] = timestamp;

        final dateKey =
            "${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}";
        entriesByDate.putIfAbsent(dateKey, () => []).add(entry);
      }

      final mediaByEntryId = <int, List<Map<String, Object?>>>{};
      for (final item in media) {
        final entryId = item['DiaryEntryId'] as int;
        mediaByEntryId.putIfAbsent(entryId, () => []).add(item);
      }

      final totalDays = entriesByDate.length;
      int processedDays = 0;

      for (final dayEntries in entriesByDate.values) {
        // Sort chronologically by ID/timestamp
        dayEntries.sort((a, b) =>
            (a['DiaryEntryId'] as int).compareTo(b['DiaryEntryId'] as int));

        final texts = <String>[];
        final moods = <int>[];
        DateTime? earliest, latest;

        final images = <Map<String, dynamic>>[];

        for (final entry in dayEntries) {
          final id = entry['DiaryEntryId'] as int;
          final heading = entry['Heading'] as String? ?? '';
          var body = entry['Text'] as String? ?? '';
          if (body.isNotEmpty) {
            // Convert to markdown
            body = html2md.convert(body);
          }

          final rating = entry['Rating'] as int?;

          if (rating != null) {
            // Convert to range of -2 to 2
            moods.add(rating.clamp(1, 5) - 3);
          }

          if (heading.isNotEmpty) {
            texts.add("# $heading");
          }
          if (body.isNotEmpty) {
            texts.add(body);
          }

          final created = idToTimestamp[id]!;
          if (earliest == null || created.isBefore(earliest)) {
            earliest = created;
          }
          if (latest == null || created.isAfter(latest)) latest = created;

          // Collect media for this entry
          for (final img in mediaByEntryId[id] ?? []) {
            final data = img['Data'] as Uint8List?;
            // Daily You uses a ranking system rather than indexes. The highest rank is shown first
            final rank =
                mediaByEntryId[id]!.length - 1 - img['Index'] as int? ?? 0;
            if (data != null) {
              images.add({
                'data': data,
                'rank': rank,
              });
            }
          }
        }

        // Compose final text & mood
        final combinedText = texts.join('\n\n');
        final averageMood = moods.isNotEmpty
            ? (moods.reduce((a, b) => a + b) / moods.length).round()
            : null;

        // Skip day if it already has an entry
        if (await EntriesDatabase.instance.getEntryForDate(earliest!) == null) {
          final addedEntry = await EntriesDatabase.instance.addEntry(
            Entry(
              text: combinedText,
              mood: averageMood,
              timeCreate: earliest,
              timeModified: latest!,
            ),
            updateStatsAndSync: false,
          );

          for (final img in images) {
            final newImage = await EntriesDatabase.instance.createImg(
              null,
              img['data'],
              currTime: earliest,
            );

            if (newImage != null) {
              await EntriesDatabase.instance.addImg(
                EntryImage(
                  id: null,
                  entryId: addedEntry.id!,
                  imgPath: newImage,
                  imgRank: img['rank'],
                  timeCreate: earliest,
                ),
                updateStatsAndSync: false,
              );
            }
          }
        }

        processedDays++;
        updateStatus("${((processedDays / totalDays) * 100).round()}%");
      }
    } catch (e) {
      updateStatus("$e");
      await Future.delayed(Duration(seconds: 5));
      success = false;
    }

    updateStatus(AppLocalizations.of(context)!.cleanUpStatus);

    if (EntriesDatabase.instance.usingExternalDb()) {
      await EntriesDatabase.instance.syncDatabase();
    }
    // Images were created externally as they were added. No need to sync with external image folder
    StatsProvider.instance.updateStats();

    if (db != null && db.isOpen) {
      await db.close();
    }

    if (await File(join(tempDir.path, tempDbName)).exists()) {
      await File(join(tempDir.path, tempDbName)).delete();
    }

    return success;
  }

  static Future<bool> importFromDaylio(
      BuildContext context, Function(String) updateStatus) async {
    updateStatus("0%");

    final selectedFile = await FileLayer.pickFile();
    if (selectedFile == null) return false;

    bool success = true;

    var tempDir = await getTemporaryDirectory();
    final tempDaylioZip = "temp_daylio.zip";
    final tempDaylioFolder = Directory(join(tempDir.path, "Daylio"));
    await tempDaylioFolder.create(recursive: true);

    try {
      // Import archive
      updateStatus(AppLocalizations.of(context)!.tranferStatus("0"));
      await FileLayer.copyFromExternalLocation(
          selectedFile, tempDir.path, tempDaylioZip, onProgress: (percent) {
        updateStatus(
            AppLocalizations.of(context)!.tranferStatus("${percent.round()}"));
      });

      await ZipUtils.extract(
        join(tempDir.path, tempDaylioZip),
        tempDaylioFolder.path,
      );

      // Get entries
      final backupEntry = await tempDaylioFolder.list().firstWhere(
            (f) => basename(f.path).endsWith('backup.daylio'),
            orElse: () => throw Exception('backup.daylio not found in archive'),
          );

      final base64String = utf8
          .decode(await File(backupEntry.path).readAsBytes())
          .replaceAll('\r', '')
          .replaceAll('\n', ''); // Remove all newline characters
      final decodedBase64 = utf8.decode(base64.decode(base64String));
      final parsed = json.decode(decodedBase64);

      final List<dynamic> dayEntries = parsed['dayEntries'];
      final List<dynamic> assets = parsed['assets'];
      final Map<String, String> checksumToFilePath = {};

      // Collect photos from assets
      for (final file
          in await Directory(join(tempDaylioFolder.path, 'assets', 'photos'))
              .list(recursive: true)
              .toList()) {
        if (file is File) {
          final checksum = basenameWithoutExtension(file.path);
          checksumToFilePath[checksum] = file.path;
        }
      }

      // Group by day
      final Map<String, List<Map<String, dynamic>>> entriesByDate = {};
      for (final entry in dayEntries) {
        final datetime = DateTime.fromMillisecondsSinceEpoch(entry['datetime'])
            .add(Duration(milliseconds: entry['timeZoneOffset'] ?? 0));
        final dateKey =
            "${datetime.year}-${datetime.month.toString().padLeft(2, '0')}-${datetime.day.toString().padLeft(2, '0')}";

        entriesByDate.putIfAbsent(dateKey, () => []).add({
          ...entry,
          'datetime': datetime,
        });
      }

      final Map<int, dynamic> assetById = {
        for (var asset in assets) asset['id']: asset,
      };

      final Map<int, int> moodValueMapping = {
        1: 2,
        2: 1,
        3: 0,
        4: -1,
        5: -2,
      };

      final totalDays = entriesByDate.length;
      int processedDays = 0;

      for (final dayEntries in entriesByDate.values) {
        dayEntries.sort((a, b) =>
            (a['datetime'] as DateTime).compareTo(b['datetime'] as DateTime));

        final texts = <String>[];
        final moods = <int>[];
        final images = <Map<String, dynamic>>[];

        DateTime? earliest, latest;

        for (final entry in dayEntries) {
          final createTime = entry['datetime'] as DateTime;
          earliest ??= createTime;
          latest =
              createTime.isAfter(latest ?? createTime) ? createTime : latest;
          latest ??= createTime;

          final title = entry['note_title'] ?? '';
          final note = entry['note'] ?? '';

          if (title.isNotEmpty) texts.add("# $title");
          if (note.isNotEmpty) texts.add(html2md.convert(note));

          final mood = entry['mood'];
          if (mood != null) {
            moods.add(moodValueMapping[mood.clamp(1, 5)]!);
          }

          final assetIds = (entry['assets'] as List?)?.cast<int>() ?? [];
          for (final assetId in assetIds) {
            final asset = assetById[assetId];
            if (asset == null || asset['type'] != 1) continue;

            final checksum = asset['checksum'];
            final file = checksumToFilePath[checksum];
            if (file == null) continue;

            images.add({
              'data': await File(file).readAsBytes(),
              'rank': 0, // Daylio doesn’t have ranks
            });
          }
        }

        final combinedText = texts.join('\n\n');
        final avgMood = moods.isNotEmpty
            ? (moods.reduce((a, b) => a + b) / moods.length).round()
            : null;

        if (await EntriesDatabase.instance.getEntryForDate(earliest!) == null) {
          final addedEntry = await EntriesDatabase.instance.addEntry(
            Entry(
              text: combinedText,
              mood: avgMood,
              timeCreate: earliest,
              timeModified: latest!,
            ),
            updateStatsAndSync: false,
          );

          for (final img in images) {
            final imagePath = await EntriesDatabase.instance.createImg(
                null, Uint8List.fromList(img['data']),
                currTime: earliest);
            if (imagePath != null) {
              await EntriesDatabase.instance.addImg(
                EntryImage(
                  entryId: addedEntry.id!,
                  imgPath: imagePath,
                  imgRank: img['rank'],
                  timeCreate: earliest,
                ),
                updateStatsAndSync: false,
              );
            }
          }
        }

        processedDays++;
        updateStatus("${((processedDays / totalDays) * 100).round()}%");
      }
    } catch (e) {
      updateStatus("$e");
      await Future.delayed(Duration(seconds: 5));
      success = false;
    }

    updateStatus(AppLocalizations.of(context)!.cleanUpStatus);

    if (EntriesDatabase.instance.usingExternalDb()) {
      await EntriesDatabase.instance.syncDatabase();
    }
    // Images were created externally as they were added. No need to sync with external image folder
    StatsProvider.instance.updateStats();

    if (await File(join(tempDir.path, tempDaylioZip)).exists()) {
      await File(join(tempDir.path, tempDaylioZip)).delete();
    }
    if (await tempDaylioFolder.exists()) {
      await tempDaylioFolder.delete(recursive: true);
    }

    return success;
  }
}
