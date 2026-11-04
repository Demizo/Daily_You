// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:daily_you/models/mood.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/utils/imports/import_bundle.dart';
import 'package:daily_you/utils/imports/import_registry.dart';
import 'package:daily_you/utils/imports/import_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' show basename, join;

import '../../support/import_fixture_staging.dart';
import '../../support/import_fixtures.dart';
import '../../support/pinned_time_zone.dart';

void main() {
  usePinnedTimeZone();

  late ImportBundle bundle;
  late Directory stagedDirectory;

  setUp(() async {
    final source = await stageDaylioFixture();
    stagedDirectory = Directory(source.directoryPath);
    bundle = await ImportRegistry.instance
        .optionFor(ImportFormat.daylio)
        .parse(source);
  });

  test('matches the expected bundle', () async {
    await expectMatchesExpectedBundle(ImportFormat.daylio, bundle,
        inputDirectory: stagedDirectory);
  });

  test('is a valid bundle', () => expectValidBundle(bundle));

  test('ranks mood from best to worst', () {
    expect(
        bundle.entries.map((imported) => imported.entry.mood),
        equals([
          null,
          Mood.veryPleasant,
          Mood.veryUnpleasant,
          Mood.neutral,
          Mood.pleasant,
        ]));
  });

  test('reads the wall-clock time as the instant plus the recorded offset', () {
    final times = bundle.entries.map((imported) => imported.entry.timeCreate);

    expect(
        times,
        equals([
          DateTime(2026, 1, 2, 4),
          DateTime(2026, 1, 2, 5),
          DateTime(2026, 1, 3, 3),
          DateTime(2026, 1, 3, 3),
          DateTime(2026, 1, 3, 2),
        ]));
    expect(times.every((time) => !time.isUtc), isTrue);
  });

  test('builds the text from the title and the note converted to markdown', () {
    expect(
        bundle.entries.map((imported) => imported.entry.text),
        equals([
          'First **entry**',
          '# Best mood, title only',
          '# Worst mood\n\nOffset missing',
          'Duplicate time',
          '# Evening\n\nSame day as the entry above',
        ]));
  });

  test('orders categories and tags by their recorded order', () {
    expect(bundle.categories.map((category) => category.name),
        equals(['Feelings', 'Activities']));
    expect(
        bundle.tagDefinitions.map((definition) =>
            (definition.name, definition.categoryName, definition.tagType)),
        equals([
          ('Exercise', 'Activities', TagType.label),
          ('Calm', 'Feelings', TagType.label),
          ('Orphan', null, TagType.label),
          ('exercise', 'Activities', TagType.label),
          ('BadName', null, TagType.label),
        ]));
  });

  test('attaches the tags of an entry and skips unknown ones', () {
    expect(
        bundle.entries
            .map((imported) => imported.tags.map((tag) => tag.name).toList()),
        equals([
          ['Exercise', 'Calm'],
          ['Orphan', 'exercise'],
          ['BadName'],
          [],
          [],
        ]));
  });

  test('ranks photos with the first listed photo highest', () {
    final photos = bundle.entries[2].attachments;

    expect(
        photos.map((photo) => basename((photo.media as FileMedia).file.path)),
        equals(['aaa111.jpg', 'bbb222.jpg']));
    expect(photos.map((photo) => photo.rank), equals([1, 0]));
  });

  test('rejects an archive without a backup', () async {
    final emptyDirectory = await Directory.systemTemp.createTemp('no_backup');
    addTearDown(() => emptyDirectory.delete(recursive: true));
    File(join(emptyDirectory.path, 'other.txt')).writeAsStringSync('x');

    expect(
        ImportRegistry.instance
            .optionFor(ImportFormat.daylio)
            .parse(ImportSource(emptyDirectory.path, 'fixture.zip')),
        throwsException);
  });
}
