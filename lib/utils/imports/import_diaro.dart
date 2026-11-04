// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:convert';
import 'dart:io';

import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/mood.dart';
import 'package:daily_you/storage/local_file_store.dart';
import 'package:daily_you/utils/imports/import_attachments.dart';
import 'package:daily_you/utils/imports/import_bundle.dart';
import 'package:daily_you/utils/imports/import_source.dart';
import 'package:daily_you/utils/imports/import_text.dart';
import 'package:daily_you/utils/imports/import_time.dart';
import 'package:path/path.dart';
import 'package:xml/xml.dart';

Future<ImportBundle> parseDiaro(ImportSource source) async {
  final files = LocalFileStore(source.directoryPath);
  final xmlName = (await files.list()).firstWhere(
      (name) => name.endsWith('DiaroBackup.xml'),
      orElse: () => throw Exception('DiaroBackup.xml not found in archive'));
  final xmlBytes = (await files.read(xmlName))!;
  final document = XmlDocument.parse(utf8.decode(xmlBytes));

  XmlElement tableNamed(String name) => document
      .findAllElements('table')
      .firstWhere((table) => table.getAttribute('name') == name);

  final photosByEntryUid = <String, List<({String fileName, int position})>>{};
  for (final row in tableNamed('diaro_attachments').findAllElements('r')) {
    if (row.getElement('type')?.innerText != 'photo') continue;
    final entryUid = row.getElement('entry_uid')?.innerText ?? "";
    final fileName = row.getElement('filename')?.innerText ?? "";
    final position = int.tryParse(row.getElement('position')?.innerText ?? "");
    if (entryUid.isEmpty || fileName.isEmpty || position == null) continue;

    photosByEntryUid
        .putIfAbsent(entryUid, () => [])
        .add((fileName: fileName, position: position));
  }

  final entries = <ImportedEntry>[];
  for (final row in tableNamed('diaro_entries').findAllElements('r')) {
    final uid = row.getElement('uid')?.innerText ?? "";
    final utcMilliseconds = row.getElement('date')?.innerText ?? "";
    final timeZoneOffset = row.getElement('tz_offset')?.innerText ?? "";
    if (uid.isEmpty || utcMilliseconds.isEmpty || timeZoneOffset.isEmpty) {
      continue;
    }

    final timeCreate = _localTime(int.parse(utcMilliseconds), timeZoneOffset);
    final rating = int.tryParse(row.getElement('mood')?.innerText ?? "");

    final photos = [...?photosByEntryUid[uid]]
      ..sort((a, b) => a.position.compareTo(b.position));
    final attachments = await existingImageAttachments(
        photos.map((photo) =>
            File(join(source.directoryPath, 'media', 'photo', photo.fileName))),
        timeCreate);

    entries.add(ImportedEntry(
      Entry(
        text: titledText(row.getElement('title')?.innerText,
            row.getElement('text')?.innerText),
        mood: rating == null ? null : Mood.fromRating(rating, bestFirst: true),
        timeCreate: timeCreate,
        timeModified: timeCreate,
      ),
      attachments: attachments,
    ));
  }
  return ImportBundle(entries: entries);
}

DateTime _localTime(int utcMilliseconds, String timeZoneOffset) {
  final sign = timeZoneOffset.startsWith('-') ? -1 : 1;
  final parts = timeZoneOffset.substring(1).split(':');
  final offset = Duration(
    hours: int.parse(parts[0]) * sign,
    minutes: int.parse(parts[1]) * sign,
  );
  return wallClockOf(
      DateTime.fromMillisecondsSinceEpoch(utcMilliseconds, isUtc: true)
          .add(offset));
}
