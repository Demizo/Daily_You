// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:daily_you/database/attachment_storage.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/storage/external_sync_settings.dart';
import 'package:daily_you/storage/local_file_store.dart';
import 'package:daily_you/storage/sync_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' show join;

import '../support/config_provider_harness.dart';

void main() {
  useTemporaryConfig();

  final storage = AttachmentStorage.instance;
  late Directory external;

  setUp(() => external = Directory.systemTemp.createTempSync('external_sync'));
  tearDown(() => external.deleteSync(recursive: true));

  Future<String?> directoryOf(AttachmentType type) async =>
      ((await storage.externalStore(type)) as LocalFileStore?)?.directoryPath;

  test('has no external store while sync is off', () async {
    for (final type in AttachmentType.values) {
      expect(await storage.externalStore(type), isNull);
    }
    expect(storage.usingExternalLocation(), isFalse);
  });

  test('uses a subfolder per type by default', () async {
    await ExternalSyncSettings.withDefaults(external.path).save();

    expect(storage.usingExternalLocation(), isTrue);
    expect(
        await directoryOf(AttachmentType.image), join(external.path, 'Images'));
    expect(
        await directoryOf(AttachmentType.video), join(external.path, 'Video'));
    expect(
        await directoryOf(AttachmentType.audio), join(external.path, 'Audio'));
  });

  test('a custom folder holds the files directly', () async {
    final photos = Directory(join(external.path, 'photos'))..createSync();
    await ExternalSyncSettings.withDefaults(external.path)
        .withChoice(SyncItem.images, const SyncChoice().withFolder(photos.path))
        .save();

    expect(await directoryOf(AttachmentType.image), photos.path);
  });

  test('concurrent requests share one subfolder', () async {
    await ExternalSyncSettings.withDefaults(external.path).save();

    final stores = await Future.wait([
      storage.externalStore(AttachmentType.image),
      storage.externalStore(AttachmentType.image),
    ]);

    expect(stores.first, isNotNull);
    expect(stores.first, same(stores.last));
  });

  test('a disabled type has no external store', () async {
    await ExternalSyncSettings.withDefaults(external.path)
        .withChoice(SyncItem.video, const SyncChoice())
        .save();

    expect(await storage.externalStore(AttachmentType.video), isNull);
    expect(await storage.externalStore(AttachmentType.audio), isNotNull);
  });

  test('a type with its own folder syncs without an external folder', () async {
    await const ExternalSyncSettings()
        .withChoice(
            SyncItem.images, const SyncChoice().withFolder(external.path))
        .save();

    expect(storage.usingExternalLocation(), isTrue);
    expect(await directoryOf(AttachmentType.image), external.path);
    expect(await storage.externalStore(AttachmentType.video), isNull);
  });

  test('every folder attachments sync to must be available', () async {
    final photos = Directory(join(external.path, 'photos'))..createSync();
    await ExternalSyncSettings.withDefaults(external.path)
        .withChoice(SyncItem.images, const SyncChoice().withFolder(photos.path))
        .save();
    expect(await storage.hasExternalLocationPermission(), isTrue);

    photos.deleteSync();

    expect(await storage.hasExternalLocationPermission(), isFalse);
  });
}
