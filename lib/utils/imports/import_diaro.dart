import 'dart:convert';
import 'dart:io';

import 'package:daily_you/database/image_storage.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
import 'package:daily_you/utils/file_layer.dart';
import 'package:daily_you/utils/imports/import_helpers.dart';
import 'package:daily_you/utils/zip_utils.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart';

Future<bool> importFromDiaro(
    BuildContext context, Function(String) updateStatus) async {
  updateStatus("0%");

  final selectedFile = await FileLayer.pickFile();
  if (selectedFile == null) return false;

  bool success = true;

  var tempDir = await getTemporaryDirectory();
  const tempZip = "temp_diaro.zip";
  final tempZipFolder = Directory(join(tempDir.path, "Diaro"));
  await tempZipFolder.create(recursive: true);

  try {
    updateStatus(AppLocalizations.of(context)!.tranferStatus("0"));
    await FileLayer.copyFromExternalLocation(
        selectedFile, tempDir.path, tempZip, onProgress: (percent) {
      updateStatus(
          AppLocalizations.of(context)!.tranferStatus("${percent.round()}"));
    });

    await ZipUtils.extract(
      join(tempDir.path, tempZip),
      tempZipFolder.path,
    );

    final xmlFile = await tempZipFolder.list().firstWhere(
          (f) => basename(f.path).endsWith('DiaroBackup.xml'),
          orElse: () =>
              throw Exception('DiaroBackup.xml not found in archive'),
        );

    final xmlString = utf8.decode(
        await FileLayer.getFileBytes(xmlFile.path, useExternalPath: false)
            as List<int>);
    final xmlDoc = XmlDocument.parse(xmlString);

    final entriesTable = xmlDoc
        .findAllElements('table')
        .firstWhere((t) => t.getAttribute('name') == 'diaro_entries');

    final attachmentTable = xmlDoc
        .findAllElements('table')
        .firstWhere((t) => t.getAttribute('name') == 'diaro_attachments');

    final attachmentsByEntry = <String, List<Map<String, dynamic>>>{};
    for (final r in attachmentTable.findAllElements('r')) {
      if (r.getElement('type')?.innerText != 'photo') continue;
      final entryUid = r.getElement('entry_uid')?.innerText ?? "";
      final filename = r.getElement('filename')?.innerText ?? "";
      final position =
          int.tryParse(r.getElement('position')?.innerText ?? "");

      if (entryUid.isEmpty || filename.isEmpty || position == null) continue;

      attachmentsByEntry.putIfAbsent(entryUid, () => []).add({
        'filename': filename,
        'position': position,
      });
    }

    const Map<int, int> moodValueMapping = {
      1: 2,
      2: 1,
      3: 0,
      4: -1,
      5: -2,
    };

    final entries = <Map<String, dynamic>>[];
    for (final r in entriesTable.findAllElements('r')) {
      final uid = r.getElement('uid')?.innerText ?? "";
      final title = r.getElement('title')?.innerText ?? "";
      final text = r.getElement('text')?.innerText ?? "";
      final moodString = r.getElement('mood')?.innerText ?? "";
      final utcTimestamp = r.getElement('date')?.innerText ?? "";
      final tzOffset = r.getElement('tz_offset')?.innerText ?? "";

      if (uid.isEmpty || utcTimestamp.isEmpty || tzOffset.isEmpty) continue;

      final created = convertWithOffset(int.parse(utcTimestamp), tzOffset);

      int? mood;
      if (moodString.isNotEmpty) {
        final m = int.tryParse(moodString);
        if (m != null) {
          mood = moodValueMapping[m.clamp(1, 5)];
        }
      }

      entries.add({
        'uid': uid,
        'title': title,
        'text': text,
        'date': created,
        'mood': mood,
        'attachments': attachmentsByEntry[uid] ?? [],
      });
    }

    final totalEntries = entries.length;
    int processedEntries = 0;

    for (final entry in entries) {
      final created = entry['date'] as DateTime;
      final title = entry['title'] as String? ?? "";
      final text = entry['text'] as String? ?? "";
      final mood = entry['mood'] as int?;
      final atts = entry['attachments'] as List<Map<String, dynamic>>;

      final parts = <String>[];
      if (title.isNotEmpty) parts.add("# $title");
      if (text.isNotEmpty) parts.add(text);

      if (!EntriesProvider.instance.hasEntryAtTimestamp(created)) {
        final addedEntry = await EntriesProvider.instance.add(
            Entry(
              text: parts.join("\n\n"),
              mood: mood,
              timeCreate: created,
              timeModified: created,
            ),
            skipUpdate: true);

        if (atts.isNotEmpty) {
          atts.sort((a, b) => a['position'].compareTo(b['position']));
          int rank = 0;
          for (final att in atts) {
            final filename = att['filename'] as String;
            final photoFile =
                File(join(tempZipFolder.path, 'media', 'photo', filename));
            final photoBytes = await FileLayer.getFileBytes(photoFile.path,
                useExternalPath: false);
            if (photoBytes == null) continue;
            final imagePath = await ImageStorage.instance
                .create(null, photoBytes, currTime: created);
            if (imagePath != null) {
              await EntryImagesProvider.instance.add(
                  EntryImage(
                    entryId: addedEntry.id!,
                    imgPath: imagePath,
                    imgRank: rank++,
                    timeCreate: created,
                  ),
                  skipUpdate: true);
            }
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

  updateStatus(AppLocalizations.of(context)!.cleanUpStatus);

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
