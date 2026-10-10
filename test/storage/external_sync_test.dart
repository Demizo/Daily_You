// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/storage/external_sync.dart';
import 'package:daily_you/storage/external_sync_settings.dart';
import 'package:daily_you/storage/sync_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const off = ExternalSyncSettings();
  final everything = ExternalSyncSettings.withDefaults('folder');
  const disabled = SyncChoice();

  test('setting up syncs every item in order', () {
    final sync = ExternalSync(off, everything);

    expect(sync.items, SyncItem.values);
    expect(sync.syncsLogs, isTrue);
    expect(sync.attachmentTypes, [
      AttachmentType.image,
      AttachmentType.video,
      AttachmentType.audio,
    ]);
  });

  test('a disabled item is skipped', () {
    final sync =
        ExternalSync(off, everything.withChoice(SyncItem.video, disabled));

    expect(sync.items, [SyncItem.logs, SyncItem.images, SyncItem.audio]);
  });

  test('enabling one item syncs only that item', () {
    final sync = ExternalSync(
        everything.withChoice(SyncItem.audio, disabled), everything);

    expect(sync.items, [SyncItem.audio]);
    expect(sync.syncsLogs, isFalse);
  });

  test('a new folder for an item syncs only that item', () {
    final sync = ExternalSync(
        everything,
        everything.withChoice(
            SyncItem.video, const SyncChoice().withFolder('clips')));

    expect(sync.items, [SyncItem.video]);
  });

  test('a new log folder also moves items that follow it', () {
    final sync = ExternalSync(
        everything,
        everything.withChoice(
            SyncItem.logs, const SyncChoice().withFolder('diary')));

    expect(sync.items, SyncItem.values);
    expect(sync.syncsLogs, isTrue);
  });

  test('a new log folder leaves items with their own folder alone', () {
    final overridden = everything
        .withChoice(SyncItem.images, const SyncChoice().withFolder('photos'))
        .withChoice(SyncItem.audio, const SyncChoice().withFolder('sounds'));
    final sync = ExternalSync(
        overridden,
        overridden.withChoice(
            SyncItem.logs, const SyncChoice().withFolder('diary')));

    expect(sync.items, [SyncItem.logs, SyncItem.video]);
  });

  test('a new log folder skips items that are switched off', () {
    final withoutVideo = everything.withChoice(SyncItem.video, disabled);
    final sync = ExternalSync(
        withoutVideo,
        withoutVideo.withChoice(
            SyncItem.logs, const SyncChoice().withFolder('diary')));

    expect(sync.items, [SyncItem.logs, SyncItem.images, SyncItem.audio]);
  });

  test('an item with its own folder syncs without logs', () {
    final sync = ExternalSync(
        off,
        off.withChoice(
            SyncItem.images, const SyncChoice().withFolder('photos')));

    expect(sync.items, [SyncItem.images]);
    expect(sync.syncsLogs, isFalse);
  });

  test('turning items off or sync off needs no sync', () {
    expect(
        ExternalSync(
                everything, everything.withChoice(SyncItem.video, disabled))
            .hasWork,
        isFalse);
    expect(ExternalSync(everything, off).hasWork, isFalse);
  });

  test('keeping the same settings needs no sync', () {
    expect(ExternalSync(everything, everything).hasWork, isFalse);
  });
}
