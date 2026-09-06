import 'dart:convert';
import 'dart:io';

import 'package:daily_you/database/image_storage.dart';
import 'package:daily_you/storage/local_file_store.dart';
import 'package:daily_you/storage/storage_picker.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/utils/zip_utils.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';

enum ExportFormat {
  none,
  markdown,
}

class ExportUtils {
  static Future<bool> exportToMarkdown(
      BuildContext context, Function(String) updateStatus) async {
    final localizations = AppLocalizations.of(context)!;
    final locale = TimeManager.currentLocale(context);
    updateStatus("(1/2) 0%");

    PickedDirectory? exportFolder;
    try {
      exportFolder = await StoragePicker.pickDirectory();
    } catch (e) {
      updateStatus("$e");
      await Future.delayed(Duration(seconds: 5));
      return false;
    }
    if (exportFolder == null) return false;

    bool success = true;

    var tempDir = await getTemporaryDirectory();
    final tempExportFolder = Directory(join(tempDir.path, "logs"));
    await tempExportFolder.create(recursive: true);
    final tempExportImageFolder =
        Directory(join(tempExportFolder.path, "Images"));
    await tempExportImageFolder.create(recursive: true);
    final exportedZipName =
        "daily_you_markdown_export_${DateTime.now().toIso8601String().replaceAll(':', '-')}.zip";

    final exportStore = LocalFileStore(tempExportFolder.path);
    final exportImageStore = LocalFileStore(tempExportImageFolder.path);

    try {
      final entries = EntriesProvider.instance.entries;
      final totalLogs = entries.length;
      int processedLogs = 0;
      final Map<String, int> timestampCount = {};
      for (Entry entry in entries) {
        final images = EntryImagesProvider.instance.getForEntry(entry);
        StringBuffer noteBody = StringBuffer();

        final timestamp =
            DateFormat("yyyy-MM-dd", locale).format(entry.timeCreate);
        timestampCount[timestamp] = (timestampCount[timestamp] ?? 0) + 1;
        final index = timestampCount[timestamp]!;
        final indexSuffix = index > 1 ? "_$index" : "";

        for (EntryImage image in images) {
          final bytes = await ImageStorage.instance.getBytes(image.imgPath);
          final prettyName =
              "image_$timestamp${indexSuffix}_${image.imgRank}${extension(image.imgPath)}";
          if (bytes != null) {
            noteBody.writeln('![](Images/$prettyName)');

            await exportImageStore.write(prettyName, bytes);
          }
        }

        String moodText = "";
        if (entry.mood != null) {
          moodText = "${MoodIcon.getMoodIcon(entry.mood)} ";
        }
        noteBody.writeln(
            "$moodText${DateFormat.yMMMEd(locale).format(entry.timeCreate)}\n${entry.text}");

        await exportStore.write(
            "log_$timestamp$indexSuffix.md", utf8.encode(noteBody.toString()));

        processedLogs++;
        updateStatus("(1/2) ${((processedLogs / totalLogs) * 100).round()}%");
      }

      // Zip export folder
      await ZipUtils.compress(
          join(tempDir.path, exportedZipName), [], [tempExportFolder.path],
          onProgress: (percent) {
        updateStatus("(2/2) ${percent.round()}%");
      });

      // Save archive
      updateStatus(localizations.tranferStatus("0"));
      await exportFolder.copyFileInto(
          join(tempDir.path, exportedZipName), exportedZipName,
          mimeType: "application/zip", onProgress: (percent) {
        updateStatus(localizations.tranferStatus("${percent.round()}"));
      });
    } catch (e) {
      updateStatus("$e");
      await Future.delayed(Duration(seconds: 5));
      success = false;
    }

    // Delete temp files
    updateStatus(localizations.cleanUpStatus);
    await File(join(tempDir.path, exportedZipName)).delete();
    if (await tempExportFolder.exists()) {
      await tempExportFolder.delete(recursive: true);
    }

    return success;
  }
}
