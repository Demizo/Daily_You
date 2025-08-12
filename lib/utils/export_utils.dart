import 'dart:convert';
import 'dart:io';

import 'package:daily_you/entries_database.dart';
import 'package:daily_you/file_layer.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/stats_provider.dart';
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
    updateStatus("(1/2) 0%");

    final exportFolder = await FileLayer.pickDirectory();
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

    try {
      final totalLogs = StatsProvider.instance.entries.length;
      int processedLogs = 0;
      for (Entry entry in StatsProvider.instance.entries) {
        final images = StatsProvider.instance.getImagesForEntry(entry);
        StringBuffer noteBody = StringBuffer();

        for (EntryImage image in images) {
          final bytes =
              await EntriesDatabase.instance.getImgBytes(image.imgPath);
          final prettyName =
              "image_${DateFormat("yyyy-MM-dd", TimeManager.currentLocale(context)).format(entry.timeCreate)}_${image.imgRank}.jpg";
          if (bytes != null) {
            noteBody.writeln('![](Images/$prettyName)');

            await FileLayer.createFile(
                tempExportImageFolder.path, prettyName, bytes,
                useExternalPath: false);
          }
        }

        String moodText = "";
        if (entry.mood != null) {
          moodText = "${MoodIcon.getMoodIcon(entry.mood)} ";
        }
        noteBody.writeln(
            "$moodText${DateFormat.yMMMEd(TimeManager.currentLocale(context)).format(entry.timeCreate)}\n${entry.text}");

        final timestamp =
            DateFormat("yyyy-MM-dd", TimeManager.currentLocale(context))
                .format(entry.timeCreate);
        await FileLayer.createFile(tempExportFolder.path, "log_$timestamp.md",
            utf8.encode(noteBody.toString()),
            useExternalPath: false);

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
      updateStatus(AppLocalizations.of(context)!.tranferStatus("0"));
      await FileLayer.copyToExternalLocation(
          join(tempDir.path, exportedZipName), exportFolder, exportedZipName,
          onProgress: (percent) {
        updateStatus(
            AppLocalizations.of(context)!.tranferStatus("${percent.round()}"));
      });
    } catch (e) {
      updateStatus("$e");
      await Future.delayed(Duration(seconds: 5));
      success = false;
    }

    // Delete temp files
    updateStatus(AppLocalizations.of(context)!.cleanUpStatus);
    await File(join(tempDir.path, exportedZipName)).delete();
    if (await tempExportFolder.exists()) {
      await tempExportFolder.delete(recursive: true);
    }

    return success;
  }
}
