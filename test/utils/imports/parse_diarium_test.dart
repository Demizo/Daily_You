// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:typed_data';

import 'package:daily_you/models/mood.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/utils/imports/import_bundle.dart';
import 'package:daily_you/utils/imports/import_registry.dart';
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
        .parse(await stageDiariumFixture());
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
          ('BadName', TagType.label, null),
          ('thoughts', TagType.label, null),
        ]));
  });

  test('keeps tracker values that are finite numbers', () {
    expect(
        bundle.entries.map((imported) =>
            imported.tags.map((tag) => (tag.name, tag.value)).toList()),
        equals([
          [('Thoughts', null), ('stress', '2.31')],
          [('stress', '4')],
          [],
          [('Thoughts', null), ('thoughts', null), ('BadName', null)],
          [],
        ]));
  });

  test('keeps image blobs with the first image highest and skips other media',
      () {
    final images = bundle.entries[3].attachments;

    expect(
        images.map((image) => (image.media as BytesMedia).bytes),
        equals([
          Uint8List.fromList([10, 11]),
          Uint8List.fromList([12, 13])
        ]));
    expect(images.map((image) => image.rank), equals([1, 0]));
  });

  test('ranks images without a usable index into unique non-negative ranks',
      () {
    final images = bundle.entries[2].attachments;

    expect(images.map((image) => (image.media as BytesMedia).bytes.single),
        equals([0x21, 0x22, 0x20]));
    expect(images.map((image) => image.rank), equals([2, 1, 0]));
  });
}
