import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:daily_you/database/image_storage.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
import 'package:daily_you/utils/file_layer.dart';
import 'package:daily_you/utils/zip_utils.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:html2md/html2md.dart' as html2md;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

Future<bool> importFromDaylio(
    BuildContext context, Function(String) updateStatus) async {
  updateStatus("0%");

  final selectedFile = await FileLayer.pickFile();
  if (selectedFile == null) return false;

  bool success = true;

  var tempDir = await getTemporaryDirectory();
  const tempDaylioZip = "temp_daylio.zip";
  final tempDaylioFolder = Directory(join(tempDir.path, "Daylio"));
  await tempDaylioFolder.create(recursive: true);

  try {
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

    final backupEntry = await tempDaylioFolder.list().firstWhere(
          (f) => basename(f.path).endsWith('backup.daylio'),
          orElse: () => throw Exception('backup.daylio not found in archive'),
        );

    final base64String = utf8
        .decode(await File(backupEntry.path).readAsBytes())
        .replaceAll('\r', '')
        .replaceAll('\n', '');
    final decodedBase64 = utf8.decode(base64.decode(base64String));
    final parsed = json.decode(decodedBase64);

    final List<dynamic> dayEntries = parsed['dayEntries'];
    final List<dynamic> assets = parsed['assets'];
    final Map<String, String> checksumToFilePath = {};

    final photosFolder =
        Directory(join(tempDaylioFolder.path, 'assets', 'photos'));
    if (await photosFolder.exists()) {
      for (final file in await photosFolder.list(recursive: true).toList()) {
        if (file is File) {
          final checksum = basenameWithoutExtension(file.path);
          checksumToFilePath[checksum] = file.path;
        }
      }
    }

    final Map<int, dynamic> assetById = {
      for (var asset in assets) asset['id']: asset,
    };

    const Map<int, int> moodValueMapping = {
      1: 2,
      2: 1,
      3: 0,
      4: -1,
      5: -2,
    };

    final totalEntries = dayEntries.length;
    int processedEntries = 0;

    for (final entry in dayEntries) {
      final datetime = DateTime.fromMillisecondsSinceEpoch(entry['datetime'])
          .add(Duration(milliseconds: entry['timeZoneOffset'] ?? 0));

      final title = entry['note_title'] ?? '';
      final note = entry['note'] ?? '';

      final parts = <String>[];
      if (title.isNotEmpty) parts.add("# $title");
      if (note.isNotEmpty) parts.add(html2md.convert(note));

      final mood = entry['mood'];
      final mappedMood =
          mood != null ? moodValueMapping[mood.clamp(1, 5)] : null;

      if (!EntriesProvider.instance.hasEntryAtTimestamp(datetime)) {
        final addedEntry = await EntriesProvider.instance.add(
            Entry(
              text: parts.join('\n\n'),
              mood: mappedMood,
              timeCreate: datetime,
              timeModified: datetime,
            ),
            skipUpdate: true);

        final assetIds = (entry['assets'] as List?)?.cast<int>() ?? [];
        for (final assetId in assetIds) {
          final asset = assetById[assetId];
          if (asset == null || asset['type'] != 1) continue;

          final checksum = asset['checksum'];
          final file = checksumToFilePath[checksum];
          if (file == null) continue;

          final imagePath = await ImageStorage.instance.create(
              null, Uint8List.fromList(await File(file).readAsBytes()),
              currTime: datetime);
          if (imagePath != null) {
            await EntryImagesProvider.instance.add(
                EntryImage(
                  entryId: addedEntry.id!,
                  imgPath: imagePath,
                  imgRank: 0,
                  timeCreate: datetime,
                ),
                skipUpdate: true);
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

  if (await File(join(tempDir.path, tempDaylioZip)).exists()) {
    await File(join(tempDir.path, tempDaylioZip)).delete();
  }
  if (await tempDaylioFolder.exists()) {
    await tempDaylioFolder.delete(recursive: true);
  }

  return success;
}
