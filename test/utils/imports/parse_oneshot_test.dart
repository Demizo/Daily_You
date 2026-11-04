// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/models/mood.dart';
import 'package:daily_you/utils/imports/import_bundle.dart';
import 'package:daily_you/utils/imports/import_registry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/import_fixtures.dart';
import '../../support/pinned_time_zone.dart';

void main() {
  usePinnedTimeZone();

  late ImportBundle bundle;

  setUpAll(() async => bundle = await parseFixture(ImportFormat.oneShot));

  test('matches the expected bundle', () async {
    await expectMatchesExpectedBundle(ImportFormat.oneShot, bundle);
  });

  test('is a valid bundle', () => expectValidBundle(bundle));

  test('maps happiness from worst to best', () {
    expect(
        bundle.entries.map((imported) => imported.entry.mood),
        equals([
          Mood.veryUnpleasant,
          Mood.veryPleasant,
          Mood.unpleasant,
          Mood.neutral,
          Mood.pleasant,
          Mood.pleasant,
          null,
          null,
        ]));
  });

  test('reads the creation second as local wall-clock time', () {
    final first = bundle.entries.first.entry;

    expect(first.timeCreate, DateTime(2026, 1, 2, 10));
    expect(first.timeModified, first.timeCreate);
  });

  test('keeps the photo path as a reference', () {
    final attachment = bundle.entries.first.attachments.single;

    expect(attachment.type, AttachmentType.image);
    expect(attachment.rank, 0);
    expect((attachment.media as ReferenceMedia).fileName, 'photos/worst.jpg');
    expect(bundle.entries[1].attachments, isEmpty);
  });
}
