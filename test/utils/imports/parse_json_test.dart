// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:convert';
import 'dart:io';

import 'package:daily_you/models/mood.dart';
import 'package:daily_you/utils/imports/import_bundle.dart';
import 'package:daily_you/utils/imports/import_json.dart';
import 'package:daily_you/utils/imports/import_registry.dart';
import 'package:daily_you/utils/imports/import_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' show join;

import '../../support/import_fixtures.dart';
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
}
