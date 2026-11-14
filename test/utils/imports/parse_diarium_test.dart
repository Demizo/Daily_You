// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations_en.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/models/mood.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/utils/imports/import_bundle.dart';
import 'package:daily_you/utils/imports/import_registry.dart';
import 'package:daily_you/utils/generated/tag_icon_registry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../support/import_fixture_staging.dart';
import '../../support/import_fixtures.dart';
import '../../support/pinned_time_zone.dart';

void main() {
  usePinnedTimeZone();
  setUpAll(sqfliteFfiInit);

  late ImportBundle bundle;

  setUp(() async {
    bundle = await ImportRegistry.instance
        .optionFor(ImportFormat.diarium)
        .parse(await stageDiariumFixture(), AppLocalizationsEn());
  });

  test('matches the expected bundle', () async {
    await expectMatchesExpectedBundle(ImportFormat.diarium, bundle);
  });

  test('is a valid bundle', () => expectValidBundle(bundle));

  test('ranks mood from worst to best', () {
    expect(
        bundle.entries.map((imported) => imported.entry.mood),
        equals([
          Mood.veryUnpleasant,
          Mood.veryPleasant,
          null,
          Mood.neutral,
          Mood.pleasant,
        ]));
  });

  test('keeps the wall-clock time recorded in the entry id', () {
    final times = bundle.entries.map((imported) => imported.entry.timeCreate);

    expect(
        times,
        equals([
          DateTime(2026, 1, 2, 9),
          DateTime(2026, 1, 2, 21, 30),
          DateTime(2026, 1, 3, 8),
          DateTime(2026, 1, 4, 10),
          DateTime(2026, 1, 4, 10),
        ]));
    expect(times.every((time) => !time.isUtc), isTrue);
  });

  test('builds the text from the heading and the body converted to markdown',
      () {
    expect(
        bundle.entries.map((imported) => imported.entry.text),
        equals([
          '# Morning\n\nFirst **entry**',
          'Evening text only',
          '# Title only',
          '# With photos\n\nTwo photos',
          '# Duplicate time\n\nSame moment as the entry above',
        ]));
  });

  test('maps tags to labels and numeric trackers and skips other types', () {
    expect(
        bundle.tagDefinitions.map((definition) =>
            (definition.name, definition.tagType, definition.color)),
        equals([
          ('Thoughts', TagType.label, 0xFFFFE600),
          ('stress', TagType.tracker, null),
          ('Someone', TagType.label, null),
          ('BadName', TagType.label, null),
          ('thoughts', TagType.label, null),
        ]));
  });

  test('gives the people category an icon', () {
    expect(bundle.categories.map((category) => (category.name, category.icon)),
        equals([('People', TagIconKey.groups)]));
  });

  test('puts people in the people category', () {
    expect(
        bundle.tagDefinitions
            .where((definition) => definition.categoryName != null)
            .map((definition) => (definition.name, definition.categoryName)),
        equals([('Someone', 'People')]));
    expect(
        bundle.tagDefinitions
            .where((definition) => definition.categoryName != null)
            .map((definition) => definition.icon),
        equals([TagIconKey.accountCircle]));
  });

  test('keeps tracker values that are finite numbers', () {
    expect(
        bundle.entries.map((imported) =>
            imported.tags.map((tag) => (tag.name, tag.value)).toList()),
        equals([
          [('Thoughts', null), ('stress', '2.31')],
          [('stress', '4'), ('Someone', null)],
          [],
          [('Thoughts', null), ('thoughts', null), ('BadName', null)],
          [],
        ]));
  });

  Future<List<int>> bytesOf(ImportedAttachment attachment) =>
      (attachment.media as BytesMedia).read();

  test('keeps image blobs with the first image highest and skips other media',
      () async {
    final images = bundle.entries[3].attachments;

    expect(
        await Future.wait(images.map(bytesOf)),
        equals([
          [10, 11],
          [12, 13]
        ]));
    expect(images.map((image) => image.rank), equals([1, 0]));
  });

  test('imports audio with the extension it was recorded with', () async {
    final audio = bundle.entries[1].attachments.single;

    expect(audio.type, AttachmentType.audio);
    expect((audio.media as BytesMedia).fileName, 'recording.mp3');
    expect(await bytesOf(audio), equals([0x30, 0x41, 0x42]));
  });

  test('ranks images without a usable index into unique non-negative ranks',
      () async {
    final images = bundle.entries[2].attachments;

    expect(
        (await Future.wait(images.map(bytesOf))).map((bytes) => bytes.single),
        equals([0x21, 0x22, 0x20]));
    expect(images.map((image) => image.rank), equals([2, 1, 0]));
  });
}
