import 'dart:convert';

import 'package:daily_you/models/entry.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/utils/file_layer.dart';
import 'package:daily_you/utils/imports/import_helpers.dart';
import 'package:intl/intl.dart';

Future<bool> importFromPixels(Function(String) updateStatus) async {
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
    if (entry['type'] == 'Mood') {
      DateTime timeCreated = DateFormat("yyyy-MM-dd").parse(entry['date']);
      DateTime timeModified = DateTime.now();

      if (!EntriesProvider.instance.hasEntryAtTimestamp(timeCreated)) {
        // Average multiple scores within a single Pixels entry
        int avgMood =
            (entry['scores'] as List<dynamic>).reduce((a, b) => a + b) ~/
                entry['scores'].length;
        int mappedMood = avgMood - 3;

        await EntriesProvider.instance.add(
            Entry(
                text: entry['notes'] ?? '',
                mood: mappedMood,
                timeCreate: timeCreated,
                timeModified: timeModified),
            skipUpdate: true);
      }
    }
    processedEntries += 1;
    updateStatus("${((processedEntries / totalEntries) * 100).round()}%");
  }

  await finishImport(updateStatus, syncImages: true);
  return true;
}
