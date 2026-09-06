import 'dart:convert';
import 'dart:typed_data';

import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/storage/storage_picker.dart';
import 'package:daily_you/utils/imports/import_helpers.dart';

Future<bool> importFromJson(Function(String) updateStatus) async {
  updateStatus("0%");

  var selectedFile = await StoragePicker.pickFile(
      allowedExtensions: ['json'], mimeTypes: ['application/json']);
  if (selectedFile == null) return false;

  var bytes = await selectedFile.readBytes();
  if (bytes == null) return false;

  await addImportedEntries(decodeJsonEntries(bytes), updateStatus);

  await finishImport(updateStatus, syncImages: true);
  return true;
}

List<ImportedEntry> decodeJsonEntries(Uint8List bytes) {
  final jsonData = json.decode(utf8.decode(bytes.toList()));

  return [
    for (var entry in jsonData)
      ImportedEntry(
        Entry(
            text: entry['text'],
            mood: entry['mood'] as int?,
            timeCreate: DateTime.parse(entry['timeCreated']),
            timeModified: DateTime.parse(entry['timeModified'])),
        images: [
          // Support old imgPath field
          if (entry['imgPath'] != null)
            EntryImage(
                entryId: null,
                imgPath: entry['imgPath'],
                imgRank: 0,
                timeCreate: DateTime.now()),
          if (entry['images'] != null)
            for (var image in entry['images'])
              EntryImage(
                  entryId: null,
                  imgPath: image['imgPath'],
                  imgRank: image['imgRank'] as int,
                  timeCreate: DateTime.parse(image['timeCreated'])),
        ],
      ),
  ];
}
