import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:daily_you/database/image_storage.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
import 'package:daily_you/storage/local_file_store.dart';
import 'package:daily_you/storage/storage_picker.dart';
import 'package:daily_you/utils/imports/import_helpers.dart';
import 'package:daily_you/utils/zip_utils.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

Future<bool> importFromDaybook(
    BuildContext context, Function(String) updateStatus) async {
  final localizations = AppLocalizations.of(context)!;
  updateStatus("0%");

  final selectedFile = await StoragePicker.pickFile();
  if (selectedFile == null) return false;

  bool success = true;

  final tempDir = await getTemporaryDirectory();
  const tempZip = "temp_daybook.zip";
  final tempZipFolder = Directory(join(tempDir.path, "Daybook"));
  await tempZipFolder.create(recursive: true);

  try {
    updateStatus(localizations.tranferStatus("0"));
    await selectedFile.copyInto(
      tempDir.path,
      tempZip,
      onProgress: (percent) {
        updateStatus(localizations.tranferStatus("${percent.round()}"));
      },
    );

    await ZipUtils.extract(
      join(tempDir.path, tempZip),
      tempZipFolder.path,
    );

    final extractedFiles = LocalFileStore(tempZipFolder.path);
    final csvBytes = await extractedFiles.read('entries.csv');
    if (csvBytes == null) throw Exception('entries.csv not found');

    final csvString = utf8.decode(csvBytes);

    final rows = const CsvDecoder(
      fieldDelimiter: ',',
      quoteCharacter: '"',
    ).convert(csvString);

    if (rows.isEmpty) {
      throw Exception("entries.csv is empty");
    }

    final header = rows.first.map((e) => e.toString()).toList();
    final dateIdx = header.indexOf("Date");
    final titleIdx = header.indexOf("Title");
    final textIdx = header.indexOf("Text");
    final imagesIdx = header.indexOf("Images");

    if ([dateIdx, titleIdx, textIdx, imagesIdx].contains(-1)) {
      throw Exception("entries.csv has unexpected format");
    }

    final parsedEntries = <Map<String, dynamic>>[];
    for (final row in rows.skip(1)) {
      final dateStr = row[dateIdx]?.toString() ?? "";
      if (dateStr.isEmpty) continue;

      final created = parseDaybookLocal(dateStr);
      parsedEntries.add({
        'date': created,
        'title': row[titleIdx]?.toString() ?? "",
        'text': row[textIdx]?.toString() ?? "",
        'images': (row[imagesIdx]?.toString() ?? "")
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
      });
    }

    final totalEntries = parsedEntries.length;
    int processedEntries = 0;

    for (final entry in parsedEntries) {
      final date = entry['date'] as DateTime;
      final title = entry['title'] as String;
      final text = entry['text'] as String;
      final imageFilenames = entry['images'] as List<String>;

      final parts = <String>[];
      if (title.isNotEmpty) parts.add("# $title");
      if (text.isNotEmpty) parts.add(text);

      if (!EntriesProvider.instance.hasEntryAtTimestamp(date)) {
        final addedEntry = await EntriesProvider.instance.add(
          Entry(
            text: parts.join("\n\n"),
            mood: null,
            timeCreate: date,
            timeModified: date,
          ),
          skipUpdate: true,
        );

        int rank = 0;
        for (final filename in imageFilenames) {
          final bytes = await extractedFiles.read(filename);
          if (bytes == null) continue;
          final imagePath =
              await ImageStorage.instance.create(null, bytes, currTime: date);
          if (imagePath != null) {
            await EntryImagesProvider.instance.add(
              EntryImage(
                entryId: addedEntry.id!,
                imgPath: imagePath,
                imgRank: rank++,
                timeCreate: date,
              ),
              skipUpdate: true,
            );
          }
        }
      }

      processedEntries++;
      updateStatus("${((processedEntries / totalEntries) * 100).round()}%");
    }
  } catch (e) {
    updateStatus("$e");
    await Future.delayed(const Duration(seconds: 5));
    success = false;
  }

  updateStatus(localizations.cleanUpStatus);

  await EntriesProvider.instance.load();
  await EntryImagesProvider.instance.load();

  if (await File(join(tempDir.path, tempZip)).exists()) {
    await File(join(tempDir.path, tempZip)).delete();
  }
  if (await tempZipFolder.exists()) {
    await tempZipFolder.delete(recursive: true);
  }

  return success;
}
