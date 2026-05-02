import 'dart:convert';

import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
import 'package:daily_you/utils/file_layer.dart';
import 'package:daily_you/utils/imports/import_helpers.dart';

Future<bool> importFromJson(Function(String) updateStatus) async {
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
    final timeCreated = DateTime.parse(entry['timeCreated']);
    if (!EntriesProvider.instance.hasEntryAtTimestamp(timeCreated)) {
      var addedEntry = await EntriesProvider.instance.add(
        Entry(
            text: entry['text'],
            mood: entry['mood'] as int?,
            timeCreate: timeCreated,
            timeModified: DateTime.parse(entry['timeModified'])),
        skipUpdate: true,
      );
      // Support old imgPath field
      if (entry['imgPath'] != null) {
        await EntryImagesProvider.instance.add(
            EntryImage(
                entryId: addedEntry.id,
                imgPath: entry['imgPath'],
                imgRank: 0,
                timeCreate: DateTime.now()),
            skipUpdate: true);
      }
      if (entry['images'] != null) {
        for (var img in entry['images']) {
          await EntryImagesProvider.instance.add(
              EntryImage(
                  entryId: addedEntry.id,
                  imgPath: img['imgPath'],
                  imgRank: img['imgRank'] as int,
                  timeCreate: DateTime.parse(img['timeCreated'])),
              skipUpdate: true);
        }
      }
    }
    processedEntries += 1;
    updateStatus("${((processedEntries / totalEntries) * 100).round()}%");
  }

  await finishImport(updateStatus, syncImages: true);
  return true;
}
