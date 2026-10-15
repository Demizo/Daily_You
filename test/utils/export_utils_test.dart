// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:convert';
import 'dart:io';

import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/storage/in_memory_file_store.dart';
import 'package:daily_you/storage/local_file_store.dart';
import 'package:daily_you/utils/export_utils.dart';
import 'package:daily_you/utils/zip_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path/path.dart' show join;

void main() {
  late InMemoryFileStore noteStore;
  late MarkdownExportWriter writer;
  late Directory sources;

  setUpAll(() => initializeDateFormatting('en'));

  setUp(() {
    sources = Directory.systemTemp.createTempSync('export_sources');
    noteStore = InMemoryFileStore();
    writer = MarkdownExportWriter(noteStore: noteStore, locale: 'en');
  });

  tearDown(() => sources.deleteSync(recursive: true));

  var sourceCount = 0;

  String sourceFile(List<int> bytes) {
    final file = File('${sources.path}/source_${sourceCount++}');
    file.writeAsBytesSync(bytes);
    return file.path;
  }

  Entry entryOn(DateTime timeCreate, {String text = ''}) =>
      Entry(text: text, timeCreate: timeCreate, timeModified: timeCreate);

  Future<String> noteNamed(String name) async =>
      utf8.decode((await noteStore.read(name))!);

  test('names a note after the day it was written', () async {
    await writer.write(entryOn(DateTime(2026, 3, 4), text: 'a good day'), []);

    expect(await noteStore.list(), equals(['log_2026-03-04.md']));
    expect(await noteNamed('log_2026-03-04.md'),
        equals('Wed, Mar 4, 2026\na good day\n'));
  });

  test('numbers later notes that share a day', () async {
    await writer.write(entryOn(DateTime(2026, 3, 4, 8)), []);
    await writer.write(entryOn(DateTime(2026, 3, 4, 20)), []);
    await writer.write(entryOn(DateTime(2026, 3, 5)), []);

    expect(
        await noteStore.list(),
        unorderedEquals(
            ['log_2026-03-04.md', 'log_2026-03-04_2.md', 'log_2026-03-05.md']));
  });

  test('links images by rank and points each at its source file', () async {
    final timeCreate = DateTime(2026, 3, 4);
    final first = sourceFile([1, 2]);
    final second = sourceFile([3, 4]);
    await writer.write(entryOn(timeCreate, text: 'body'), [
      (
        EntryAttachment(
            entryId: 1,
            type: AttachmentType.image,
            filePath: 'daily_you_a.png',
            rank: 1,
            timeCreate: timeCreate),
        first,
      ),
      (
        EntryAttachment(
            entryId: 1,
            type: AttachmentType.image,
            filePath: 'daily_you_b.jpg',
            rank: 0,
            timeCreate: timeCreate),
        second,
      ),
    ]);

    expect(writer.attachmentSources, {
      'Images/image_2026-03-04_1.png': first,
      'Images/image_2026-03-04_0.jpg': second,
    });
    expect(
        await noteNamed('log_2026-03-04.md'),
        startsWith('![](Images/image_2026-03-04_1.png)\n'
            '![](Images/image_2026-03-04_0.jpg)\n'));
  });

  test('carries the note suffix into its image names', () async {
    final timeCreate = DateTime(2026, 3, 4);
    final image = EntryAttachment(
        entryId: 1,
        type: AttachmentType.image,
        filePath: 'daily_you_a.png',
        rank: 0,
        timeCreate: timeCreate);
    final source = sourceFile([1]);

    await writer.write(entryOn(timeCreate), [(image, source)]);
    await writer.write(entryOn(timeCreate), [(image, source)]);

    expect(
        writer.attachmentSources.keys,
        equals([
          'Images/image_2026-03-04_0.png',
          'Images/image_2026-03-04_2_0.png'
        ]));
  });

  test('links a video into its own folder as a plain link, not an image',
      () async {
    final timeCreate = DateTime(2026, 3, 4);
    await writer.write(entryOn(timeCreate, text: 'body'), [
      (
        EntryAttachment(
            entryId: 1,
            type: AttachmentType.video,
            filePath: 'daily_you_a.mp4',
            rank: 0,
            timeCreate: timeCreate),
        sourceFile([1, 2]),
      ),
    ]);

    expect(writer.attachmentSources.keys,
        equals(['Video/video_2026-03-04_0.mp4']));
    expect(await noteNamed('log_2026-03-04.md'),
        startsWith('[video_2026-03-04_0.mp4](Video/video_2026-03-04_0.mp4)\n'));
  });

  test('copies no attachment bytes into the note folder', () async {
    final timeCreate = DateTime(2026, 3, 4);
    await writer.write(entryOn(timeCreate), [
      (
        EntryAttachment(
            entryId: 1,
            type: AttachmentType.audio,
            filePath: 'daily_you_a.m4a',
            rank: 0,
            timeCreate: timeCreate),
        sourceFile([1, 2]),
      ),
    ]);

    expect(await noteStore.list(), equals(['log_2026-03-04.md']));
  });

  test('zipped, the notes and attachments sit where the links point', () async {
    final timeCreate = DateTime(2026, 3, 4);
    final noteFolder = Directory(join(sources.path, 'logs'))..createSync();
    final diskWriter = MarkdownExportWriter(
        noteStore: LocalFileStore(noteFolder.path), locale: 'en');
    await diskWriter.write(entryOn(timeCreate, text: 'body'), [
      (
        EntryAttachment(
            entryId: 1,
            type: AttachmentType.video,
            filePath: 'daily_you_a.mp4',
            rank: 0,
            timeCreate: timeCreate),
        sourceFile([9, 8, 7]),
      ),
    ]);
    final archive = join(sources.path, 'export.zip');

    await ZipUtils.compress(archive, [], [
      noteFolder.path
    ], filesByArchivePath: {
      for (final entry in diskWriter.attachmentSources.entries)
        'logs/${entry.key}': entry.value
    });
    await ZipUtils.extract(archive, join(sources.path, 'extracted'));

    final extracted = join(sources.path, 'extracted', 'logs');
    expect(File(join(extracted, 'log_2026-03-04.md')).existsSync(), isTrue);
    expect(
        File(join(extracted, 'Video', 'video_2026-03-04_0.mp4'))
            .readAsBytesSync(),
        equals([9, 8, 7]));
  });
}
