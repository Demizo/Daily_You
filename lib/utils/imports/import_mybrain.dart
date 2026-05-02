import 'dart:convert';

import 'package:daily_you/models/entry.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/utils/file_layer.dart';
import 'package:daily_you/utils/imports/import_helpers.dart';

Future<bool> importFromMyBrain(Function(String) updateStatus) async {
  updateStatus("0%");

  bool success = true;

  try {
    var selectedFile = await FileLayer.pickFile(
        allowedExtensions: ['json'], mimeTypes: ['application/json']);
    if (selectedFile == null) return false;

    var bytes = await FileLayer.getFileBytes(selectedFile);
    if (bytes == null) return false;
    final jsonData = json.decode(utf8.decode(bytes.toList()));

    const moodMap = {
      'TERRIBLE': -2,
      'BAD': -1,
      'OKAY': 0,
      'GOOD': 1,
      'AWESOME': 2,
    };

    final diary = jsonData['diary'] as List<dynamic>;
    final totalEntries = diary.length;
    var processedEntries = 0;

    for (var entry in diary) {
      final created = DateTime.fromMillisecondsSinceEpoch(
              entry['createdDate'],
              isUtc: true)
          .toLocal();
      final updated = DateTime.fromMillisecondsSinceEpoch(
              entry['updatedDate'],
              isUtc: true)
          .toLocal();

      int? mood;
      if (entry['mood'] != null) {
        mood = moodMap[entry['mood']];
      }

      final parts = <String>[];
      if (entry['title'] != null) parts.add("# ${entry['title']}");
      if (entry['content'] != null) parts.add(entry['content']);

      if (!EntriesProvider.instance.hasEntryAtTimestamp(created)) {
        await EntriesProvider.instance.add(
            Entry(
              text: parts.join("\n\n"),
              mood: mood,
              timeCreate: created,
              timeModified: updated,
            ),
            skipUpdate: true);
      }

      processedEntries += 1;
      updateStatus("${((processedEntries / totalEntries) * 100).round()}%");
    }
  } catch (e) {
    updateStatus("$e");
    await Future.delayed(const Duration(seconds: 5));
    success = false;
  }

  await finishImport(updateStatus, syncImages: true);
  return success;
}
