import 'dart:convert';
import 'dart:typed_data';

import 'package:daily_you/models/entry.dart';
import 'package:daily_you/storage/storage_picker.dart';
import 'package:daily_you/utils/imports/import_helpers.dart';
import 'package:daily_you/utils/operation_outcome.dart';

Future<OperationOutcome> importFromMyBrain(
    Function(String) updateStatus) async {
  updateStatus("0%");

  var outcome = const OperationOutcome.succeeded();

  try {
    final selectedFile = await StoragePicker.pickFile(
        allowedExtensions: ['json'], mimeTypes: ['application/json']);
    if (selectedFile == null) return const OperationOutcome.cancelled();

    final bytes = await selectedFile.readBytes();
    if (bytes == null) return const OperationOutcome.failed();

    await addImportedEntries(decodeMyBrainEntries(bytes), updateStatus);
  } catch (error) {
    outcome = OperationOutcome.failed(error);
  }

  await finishImport(updateStatus, syncImages: true);
  return outcome;
}

List<ImportedEntry> decodeMyBrainEntries(Uint8List bytes) {
  const moodMap = {
    'TERRIBLE': -2,
    'BAD': -1,
    'OKAY': 0,
    'GOOD': 1,
    'AWESOME': 2,
  };

  final jsonData = json.decode(utf8.decode(bytes.toList()));
  final diary = jsonData['diary'] as List<dynamic>;

  return [
    for (var entry in diary)
      ImportedEntry(Entry(
        text: [
          if (entry['title'] != null) "# ${entry['title']}",
          if (entry['content'] != null) entry['content'] as String,
        ].join("\n\n"),
        mood: entry['mood'] != null ? moodMap[entry['mood']] : null,
        timeCreate: DateTime.fromMillisecondsSinceEpoch(entry['createdDate'],
                isUtc: true)
            .toLocal(),
        timeModified: DateTime.fromMillisecondsSinceEpoch(entry['updatedDate'],
                isUtc: true)
            .toLocal(),
      )),
  ];
}
