// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/storage/local_file_store.dart';
import 'package:daily_you/utils/imports/import_attachments.dart';
import 'package:daily_you/utils/imports/import_bundle.dart';
import 'package:daily_you/utils/imports/import_source.dart';
import 'package:daily_you/utils/imports/import_text.dart';
import 'package:path/path.dart';

Future<ImportBundle> parseDaybook(ImportSource source) async {
  final csvBytes =
      await LocalFileStore(source.directoryPath).read('entries.csv');
  if (csvBytes == null) throw Exception('entries.csv not found');

  final rows = const CsvDecoder(
    fieldDelimiter: ',',
    quoteCharacter: '"',
  ).convert(utf8.decode(csvBytes));
  if (rows.isEmpty) throw Exception("entries.csv is empty");

  final header = rows.first.map((cell) => cell.toString()).toList();
  final dateIndex = header.indexOf("Date");
  final titleIndex = header.indexOf("Title");
  final textIndex = header.indexOf("Text");
  final imagesIndex = header.indexOf("Images");
  if ([dateIndex, titleIndex, textIndex, imagesIndex].contains(-1)) {
    throw Exception("entries.csv has unexpected format");
  }

  final entries = <ImportedEntry>[];
  for (final row in rows.skip(1)) {
    final dateText = row[dateIndex]?.toString() ?? "";
    if (dateText.isEmpty) continue;

    final timeCreate = _parseDate(dateText);
    final imageNames = (row[imagesIndex]?.toString() ?? "")
        .split(',')
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty);

    final attachments = await existingImageAttachments(
        imageNames
            .map((imageName) => File(join(source.directoryPath, imageName))),
        timeCreate);

    entries.add(ImportedEntry(
      Entry(
        text:
            titledText(row[titleIndex]?.toString(), row[textIndex]?.toString()),
        timeCreate: timeCreate,
        timeModified: timeCreate,
      ),
      attachments: attachments,
    ));
  }
  return ImportBundle(entries: entries);
}

DateTime _parseDate(String text) {
  final match =
      RegExp(r'^(\d{4})-(\d{2})-(\d{2})-(\d{2}):(\d{2})$').firstMatch(text);
  if (match == null) throw FormatException("Invalid Daybook date: $text");

  return DateTime(
    int.parse(match[1]!),
    int.parse(match[2]!),
    int.parse(match[3]!),
    int.parse(match[4]!),
    int.parse(match[5]!),
  );
}
