// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:convert';
import 'dart:io';

import 'package:daily_you/l10n/generated/app_localizations_en.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/utils/imports/import_bundle.dart';
import 'package:daily_you/utils/imports/import_registry.dart';
import 'package:daily_you/utils/imports/import_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' show basename, join;

import '../../support/import_fixture_staging.dart';
import '../../support/import_fixtures.dart';
import '../../support/pinned_time_zone.dart';

Future<ImportBundle> parseSource(ImportSource source) => ImportRegistry.instance
    .optionFor(ImportFormat.dayOne)
    .parse(source, AppLocalizationsEn());

Future<ImportSource> stageJournals(
    Map<String, Object> journalsByFileName) async {
  final directory = await Directory.systemTemp.createTemp('dayone_journals');
  addTearDown(() => directory.delete(recursive: true));
  for (final entry in journalsByFileName.entries) {
    await File(join(directory.path, entry.key))
        .writeAsString(json.encode(entry.value));
  }
  return ImportSource(directory.path, journalsByFileName.keys.first);
}

void main() {
  usePinnedTimeZone();

  late ImportBundle bundle;
  late ImportSource source;

  setUp(() async {
    source = await stageDayOneFixture();
    bundle = await parseSource(source);
  });

  test('matches the expected bundle', () async {
    await expectMatchesExpectedBundle(ImportFormat.dayOne, bundle,
        inputDirectory: extractedDayOneFixture(source));
  });

  test('is a valid bundle', () => expectValidBundle(bundle));

  test('reads the wall-clock time in the time zone of each entry', () {
    expect(
        bundle.entries.map((imported) => imported.entry.timeCreate),
        equals([
          DateTime(2026, 1, 1, 6, 30),
          DateTime(2026, 1, 1, 21, 4, 5),
          DateTime(2026, 3, 29, 1, 30),
          DateTime(2026, 7, 1, 19),
        ]));
    expect(bundle.entries[1].entry.timeModified, DateTime(2026, 1, 1, 22));
  });

  test(
      'turns tags into labels and merges the starred flag into the favorite label',
      () {
    expect(
        bundle.entries
            .map((imported) => imported.tags.map((tag) => tag.name).toList()),
        equals([
          ['Journal'],
          ['Gratitude', 'SlashName', 'gratitude', 'Favorite', 'Journal'],
          ['Gratitude', 'Journal Two'],
          ['Journal'],
        ]));
  });

  test('drops media references and cleans escapes from the text', () {
    expect(
        bundle.entries.map((imported) => imported.entry.text),
        equals([
          '',
          '# First entry\nA well-known (example).\n\n**Bold** stays',
          'Second journal',
          'No time zone',
        ]));
  });

  test('ranks media by its order in the entry and skips missing files', () {
    final attachments = bundle.entries[1].attachments;

    expect(
        attachments.map((attachment) =>
            basename((attachment.media as FileMedia).file.path)),
        equals(['aaaa1111.jpg', 'bbbb2222.png']));
    expect(attachments.map((attachment) => attachment.rank), equals([1, 0]));
  });

  test('imports videos and recordings next to photos', () {
    final attachments = bundle.entries[3].attachments;

    expect(attachments.map((attachment) => attachment.type),
        equals([AttachmentType.audio, AttachmentType.video]));
  });

  test('does not tag entries by journal when there is a single journal',
      () async {
    final single = await parseSource(await stageJournals({
      'Journal.json': {
        'entries': [
          {'creationDate': '2026-01-02T03:04:05Z', 'text': 'One'}
        ]
      }
    }));

    expect(single.entries.single.tags, isEmpty);
  });

  test('imports a single journal file without media', () async {
    final single = await parseSource(await stageJournals({
      'Journal.json': {
        'entries': [
          {
            'creationDate': '2026-01-02T03:04:05Z',
            'timeZone': 'Europe/Berlin',
            'text': 'One',
            'photos': [
              {'md5': 'aaaa1111', 'type': 'jpg', 'orderInEntry': 0}
            ]
          }
        ]
      }
    }));

    expect(
        single.entries.single.entry.timeCreate, DateTime(2026, 1, 2, 4, 4, 5));
    expect(single.entries.single.attachments, isEmpty);
  });

  test('rejects a file that is not a Day One export', () async {
    expect(
        parseSource(await stageJournals({
          'notes.json': {'a': 1}
        })),
        throwsA(isA<FormatException>()));
  });

  test('rejects an empty file', () async {
    final directory = await Directory.systemTemp.createTemp('dayone_empty');
    addTearDown(() => directory.delete(recursive: true));
    await File(join(directory.path, 'Journal.json')).writeAsBytes([]);

    expect(parseSource(ImportSource(directory.path, 'Journal.json')),
        throwsA(isA<FormatException>()));
  });

  test('rejects media that leaves the export folder', () async {
    final escaping = await stageJournals({
      'Journal.json': {
        'entries': [
          {
            'creationDate': '2026-01-02T03:04:05Z',
            'text': 'One',
            'photos': [
              {'md5': '../../secret', 'type': 'jpg', 'orderInEntry': 0}
            ]
          }
        ]
      }
    });

    expect(parseSource(escaping), throwsA(isA<FormatException>()));
  });
}
