import 'dart:convert';

import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
import 'package:daily_you/utils/file_layer.dart';
import 'package:daily_you/utils/imports/import_helpers.dart';

Future<bool> importFromOneShot(Function(String) updateStatus) async {
  updateStatus("0%");

  var selectedFile = await FileLayer.pickFile(
      allowedExtensions: ['json'], mimeTypes: ['application/json']);
  if (selectedFile == null) return false;

  var bytes = await FileLayer.getFileBytes(selectedFile);
  if (bytes == null) return false;
  final jsonData = json.decode(utf8.decode(bytes.toList()));

  const happinessMapping = {
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
    final mood = happinessMapping[entry['happiness']];

    if (!EntriesProvider.instance.hasEntryAtTimestamp(createdDateTime)) {
      var addedEntry = await EntriesProvider.instance.add(
          Entry(
              text: entry['textContent'],
              mood: mood,
              timeCreate: createdDateTime,
              timeModified: DateTime.now()),
          skipUpdate: true);
      if (entry['relativePath'] != null) {
        await EntryImagesProvider.instance.add(
            EntryImage(
                entryId: addedEntry.id,
                imgPath: entry['relativePath'],
                imgRank: 0,
                timeCreate: DateTime.now()),
            skipUpdate: true);
      }
    }
    processedEntries += 1;
    updateStatus("${((processedEntries / totalEntries) * 100).round()}%");
  }

  await finishImport(updateStatus, syncImages: true);
  return true;
}
