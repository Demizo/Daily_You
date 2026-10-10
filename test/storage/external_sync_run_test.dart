// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:typed_data';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/database/attachment_storage.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/storage/external_sync.dart';
import 'package:daily_you/storage/external_sync_settings.dart';
import 'package:daily_you/storage/file_store.dart';
import 'package:daily_you/storage/in_memory_file_store.dart';
import 'package:daily_you/storage/sync_item.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/config_provider_harness.dart';

class _UnlistableStore extends InMemoryFileStore {
  @override
  Future<List<StoredFile>> listFiles() async =>
      throw Exception('folder unreachable');
}

void main() {
  useTemporaryConfig();

  final storage = AttachmentStorage.instance;
  final folder = ExternalSyncSettings.withDefaults('folder');
  final withoutImages = folder.withChoice(SyncItem.images, const SyncChoice());
  late InMemoryFileStore internal;

  void useStores(FileStore external) {
    storage.overrideStores(internal, external);
    addTearDown(storage.clearStoreOverrides);
    EntryAttachmentsProvider.instance.isLoaded = true;
    addTearDown(() => EntryAttachmentsProvider.instance.isLoaded = false);
    EntryAttachmentsProvider.instance.attachments = [
      EntryAttachment(
          entryId: 1,
          type: AttachmentType.image,
          filePath: 'a.jpg',
          rank: 0,
          timeCreate: DateTime(2026, 1, 1)),
    ];
  }

  setUp(() async {
    internal = InMemoryFileStore();
    await internal.write('a.jpg', Uint8List.fromList([1, 2, 3]));
  });

  test('enabling a type saves the choice and syncs only that type', () async {
    final external = InMemoryFileStore();
    useStores(external);
    await withoutImages.save();
    final items = <SyncItem>[];

    final outcome = await ExternalSync(withoutImages, folder)
        .run((progress) => items.add(progress.item));

    expect(outcome.succeeded, isTrue);
    expect(ExternalSyncSettings.load(), folder);
    expect(items.toSet(), {SyncItem.images});
    expect(await external.read('a.jpg'), Uint8List.fromList([1, 2, 3]));
  });

  test('a failed sync puts the previous settings back', () async {
    useStores(_UnlistableStore());
    await withoutImages.save();

    final outcome = await ExternalSync(withoutImages, folder).run((_) {});

    expect(outcome.failed, isTrue);
    expect(ExternalSyncSettings.load(), withoutImages);
    expect(ConfigProvider.instance.get(Settings.syncImages), isFalse);
  });

  test('turning sync off saves without syncing', () async {
    final external = InMemoryFileStore();
    useStores(external);
    await folder.save();

    final outcome =
        await ExternalSync(folder, const ExternalSyncSettings()).run((_) {});

    expect(outcome.succeeded, isTrue);
    expect(ExternalSyncSettings.load().isOn, isFalse);
    expect(await external.list(), isEmpty);
  });
}
