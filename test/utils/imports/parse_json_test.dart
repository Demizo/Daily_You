// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:convert';
import 'dart:io';

import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/models/mood.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/models/tag_icon_type.dart';
import 'package:daily_you/utils/imports/import_bundle.dart';
import 'package:daily_you/utils/imports/import_json.dart';
import 'package:daily_you/utils/imports/import_registry.dart';
import 'package:daily_you/utils/imports/import_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' show join;

import '../../support/import_fixtures.dart';
import '../../support/import_run_harness.dart';
import '../../support/pinned_time_zone.dart';

void main() {
  usePinnedTimeZone();

  late ImportBundle bundle;

  setUpAll(() async => bundle = await parseFixture(ImportFormat.dailyYouJson));

  test('matches the expected bundle', () async {
    await expectMatchesExpectedBundle(ImportFormat.dailyYouJson, bundle);
  });

  test('is a valid bundle', () => expectValidBundle(bundle));

  test('reads the legacy mood scale from worst to best', () {
    expect(
        bundle.entries.map((imported) => imported.entry.mood),
        equals([
          null,
          Mood.veryUnpleasant,
          Mood.veryPleasant,
          Mood.neutral,
          null,
          null,
          null,
          null
        ]));
  });

  test('reads times as local wall-clock times', () {
    expect(bundle.entries.first.entry.timeCreate, DateTime(2026, 1, 2, 9));
    expect(bundle.entries.first.entry.timeModified, DateTime(2026, 1, 2, 9, 5));
  });

  test('keeps the images list in file order as references', () {
    final attachments = bundle.entries[3].attachments;

    expect(
        attachments
            .map((attachment) => (attachment.media as ReferenceMedia).fileName),
        equals(['second.jpg', 'first.jpg']));
    expect(attachments.map((attachment) => attachment.rank), equals([1, 0]));
  });

  test('reads the deprecated image field as the first rank', () {
    final attachment = bundle.entries[4].attachments.single;

    expect((attachment.media as ReferenceMedia).fileName, 'legacy.jpg');
    expect(attachment.rank, 0);
  });

  test('ranks the deprecated image field below the images list', () {
    final attachments = bundle.entries[5].attachments;

    expect(
        attachments
            .map((attachment) => (attachment.media as ReferenceMedia).fileName),
        equals(['legacy.jpg', 'listed.jpg']));
    expect(attachments.map((attachment) => attachment.rank), equals([0, 1]));
  });

  test('converts times stored with a zone to local wall-clock times', () {
    final entry = bundle.entries[6].entry;

    expect(entry.timeCreate, DateTime(2026, 1, 7, 10));
    expect(entry.timeModified, DateTime(2026, 1, 7, 11));
    expect(bundle.entries[6].attachments.single.timeCreate,
        DateTime(2026, 1, 7, 10, 30));
  });

  test('rejects a document that is not a list of entries', () async {
    final directory = Directory.systemTemp.createTempSync('parse_json');
    addTearDown(() => directory.deleteSync(recursive: true));
    File(join(directory.path, 'other.json'))
        .writeAsStringSync(jsonEncode({'diary': []}));

    expect(parseJson(ImportSource(directory.path, 'other.json')),
        throwsFormatException);
  });

  group('version 2', () {
    const exportedDocument = 'test/fixtures/exports/export.json';
    const documentName = 'daily_you_export.json';

    Future<Directory> stagingDirectory() async {
      final directory = Directory.systemTemp.createTempSync('parse_json_v2');
      addTearDown(() => directory.deleteSync(recursive: true));
      return directory;
    }

    Future<ImportBundle> parseDocument(
        String contents, Directory directory) async {
      File(join(directory.path, documentName)).writeAsStringSync(contents);
      return parseJson(ImportSource(directory.path, documentName));
    }

    Future<ImportBundle> parseExported() async => parseDocument(
        File(exportedDocument).readAsStringSync(), await stagingDirectory());

    Future<String> exportedArchive() async {
      final directory = await stagingDirectory();
      File(join(directory.path, documentName))
          .writeAsStringSync(File(exportedDocument).readAsStringSync());
      for (final (path, bytes) in [
        ('Video/video_2026-03-04_2.mp4', [1]),
        ('Images/image_2026-03-04_1.png', [2, 2]),
        ('Audio/audio_2026-03-04_0.m4a', [3, 3, 3]),
      ]) {
        File(join(directory.path, path))
          ..createSync(recursive: true)
          ..writeAsBytesSync(bytes);
      }
      return zipDirectoryContents(directory);
    }

    Future<ImportBundle> parseArchive(String archive) async {
      final directory = await stagingDirectory();
      File(archive).copySync(join(directory.path, 'export.zip'));
      return parseJson(ImportSource(directory.path, 'export.zip'));
    }

    test('is a valid bundle', () async {
      expectValidBundle(await parseExported());
    });

    test('reads categories and tag definitions by name', () async {
      final bundle = await parseExported();

      expect(bundle.categories.map((category) => category.name),
          ['Life', 'Health']);
      expect(bundle.categories.first.color, 0xFF2196F3);
      expect(bundle.categories.last.iconType, TagIconType.materialIcon);
      expect(
          bundle.tagDefinitions.map((definition) =>
              (definition.name, definition.tagType, definition.categoryName)),
          [
            ('Work', TagType.label, 'Life'),
            ('Gym', TagType.label, null),
            ('Water', TagType.tracker, 'Health'),
            ('Sleep', TagType.tracker, null),
            ('date', TagType.tracker, null),
          ]);
      expect(bundle.tagDefinitions.first.icon, '💼');
      expect(bundle.tagDefinitions[2].color, 0xFF03A9F4);
    });

    test('reads entries with local times, moods and exact text', () async {
      final bundle = await parseExported();

      final first = bundle.entries.first.entry;
      expect(
          first.text, 'He said "hi", then left\r\nsecond line\nthird line 🙂');
      expect(first.mood, 4);
      expect(first.timeCreate, DateTime(2026, 3, 4, 8, 30));
      expect(first.timeModified, DateTime(2026, 3, 4, 9));
      expect(bundle.entries[1].entry.mood, isNull);
    });

    test('reads entry tags with tracker values as numbers', () async {
      final bundle = await parseExported();

      expect(
          bundle.entries.first.tags
              .map((tag) => (tag.name, tag.tagType, tag.value)),
          [
            ('Work', TagType.label, null),
            ('Gym', TagType.label, null),
            ('Water', TagType.tracker, '3'),
            ('Sleep', TagType.tracker, '7.5'),
            ('date', TagType.tracker, '1'),
          ]);
    });

    test('drops a tracker that has no value', () async {
      final bundle = await parseExported();

      expect(bundle.entries[2].tags, isEmpty);
    });

    test('skips attachments whose files are not in the folder', () async {
      final bundle = await parseExported();

      expect(bundle.entries.first.attachments, isEmpty);
    });

    test('reads the attachments of a zip from the extracted files', () async {
      final bundle = await parseArchive(await exportedArchive());

      final attachments = bundle.entries.first.attachments;
      expect(
          attachments.map((attachment) => (attachment.type, attachment.rank)), [
        (AttachmentType.video, 2),
        (AttachmentType.image, 1),
        (AttachmentType.audio, 0),
      ]);
      expect(attachments.first.timeCreate, DateTime(2026, 3, 4, 8, 32));
      expect([
        for (final attachment in attachments)
          (attachment.media as FileMedia).file.readAsBytesSync()
      ], [
        [1],
        [2, 2],
        [3, 3, 3]
      ]);
      expectValidBundle(bundle);
    });

    test('rejects a version it does not know', () async {
      final directory = await stagingDirectory();

      expect(
          parseDocument(
              jsonEncode({'format': 'daily-you', 'version': 3}), directory),
          throwsFormatException);
    });

    test('rejects an attachment path that leaves the archive', () async {
      final directory = await stagingDirectory();
      final document = jsonDecode(File(exportedDocument).readAsStringSync())
          as Map<String, dynamic>;
      document['entries'][0]['attachments'][0]['path'] = '../outside.mp4';

      expect(parseDocument(jsonEncode(document), directory),
          throwsFormatException);
    });

    test('rejects a zip without a single JSON document', () async {
      final directory = await stagingDirectory();
      File(join(directory.path, 'notes.txt')).writeAsStringSync('x');

      expect(parseArchive(await zipDirectoryContents(directory)),
          throwsFormatException);
    });
  });
}
