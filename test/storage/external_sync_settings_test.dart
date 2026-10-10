// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/storage/external_sync_settings.dart';
import 'package:daily_you/storage/sync_item.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/config_provider_harness.dart';

void main() {
  useTemporaryConfig();

  const off = ExternalSyncSettings();
  final everything = ExternalSyncSettings.withDefaults('folder');

  test('starts with nothing syncing', () {
    final settings = ExternalSyncSettings.load();

    expect(settings.isOn, isFalse);
    for (final item in SyncItem.values) {
      expect(settings.location(item), isNull);
      expect(settings.hasLocation(item), isFalse);
    }
  });

  test('the defaults sync everything inside the log folder', () {
    expect(
        everything.location(SyncItem.logs), (uri: 'folder', subfolder: null));
    expect(everything.location(SyncItem.images),
        (uri: 'folder', subfolder: 'Images'));
    expect(everything.location(SyncItem.video),
        (uri: 'folder', subfolder: 'Video'));
    expect(everything.location(SyncItem.audio),
        (uri: 'folder', subfolder: 'Audio'));
  });

  test('a custom folder holds the files directly', () {
    final settings = everything.withChoice(
        SyncItem.images, const SyncChoice().withFolder('photos'));

    expect(
        settings.location(SyncItem.images), (uri: 'photos', subfolder: null));
  });

  test('an item with its own folder syncs without an external folder', () {
    final settings = off.withChoice(
        SyncItem.images, const SyncChoice().withFolder('photos'));

    expect(settings.isOn, isTrue);
    expect(settings.hasLocation(SyncItem.images), isTrue);
    expect(settings.hasLocation(SyncItem.video), isFalse);
    expect(settings.location(SyncItem.video), isNull);
  });

  test('a disabled item still has a destination', () {
    final settings = everything.withChoice(SyncItem.video, const SyncChoice());

    expect(settings.location(SyncItem.video), isNull);
    expect(settings.destination(SyncItem.video),
        (uri: 'folder', subfolder: 'Video'));
    expect(off.destination(SyncItem.video), isNull);
  });

  test('a disabled item has no location but remembers its folder', () {
    final settings = everything
        .withChoice(SyncItem.audio, const SyncChoice().withFolder('sounds'))
        .withChoice(SyncItem.audio,
            const SyncChoice().withFolder('sounds').withEnabled(false));

    expect(settings.location(SyncItem.audio), isNull);
    expect(settings.choice(SyncItem.audio).folderUri, 'sounds');
  });

  test('resetting the folder keeps whether the item is on', () {
    final off = const SyncChoice(folderUri: 'sounds');

    expect(off.withFolder(null).enabled, isFalse);
    expect(
        const SyncChoice(enabled: true, folderUri: 'sounds')
            .withFolder(null)
            .enabled,
        isTrue);
  });

  test('picking a folder turns the item on', () {
    expect(const SyncChoice().withFolder('sounds').enabled, isTrue);
  });

  test('nothing syncs once every item is off', () {
    var settings = everything;
    for (final item in SyncItem.values) {
      settings = settings.withChoice(item, const SyncChoice());
    }

    expect(settings.isOn, isFalse);
  });

  test('round-trips through the config', () async {
    final saved = everything
        .withChoice(SyncItem.images, const SyncChoice().withFolder('photos'))
        .withChoice(SyncItem.video, const SyncChoice());

    await saved.save();

    expect(ExternalSyncSettings.load(), saved);
  });

  test('an image folder alone round-trips', () async {
    final saved = off.withChoice(
        SyncItem.images, const SyncChoice().withFolder('photos'));

    await saved.save();

    expect(ExternalSyncSettings.load(), saved);
  });

  test('a log folder alone is enough for items to follow it', () async {
    await ConfigProvider.instance.set(Settings.logSyncFolderUri, 'folder');
    await ConfigProvider.instance.set(Settings.syncAudio, true);

    expect(ExternalSyncSettings.load().location(SyncItem.audio),
        (uri: 'folder', subfolder: 'Audio'));
  });

  test('switching logs off keeps the folder the other items follow', () {
    final settings = everything.withChoice(
        SyncItem.logs, everything.choice(SyncItem.logs).withEnabled(false));

    expect(settings.location(SyncItem.logs), isNull);
    expect(settings.location(SyncItem.images),
        (uri: 'folder', subfolder: 'Images'));
  });

  test('an enabled item with nowhere to sync loads as off', () async {
    await ConfigProvider.instance.set(Settings.syncAudio, true);

    expect(ExternalSyncSettings.load().choice(SyncItem.audio).enabled, isFalse);
  });

  test('turning sync off reads back as off', () async {
    await everything.save();
    await off.save();

    expect(ExternalSyncSettings.load(), off);
  });
}
