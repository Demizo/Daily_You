// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:typed_data';

import 'package:daily_you/database/attachment_storage.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/storage/in_memory_file_store.dart';
import 'package:daily_you/widgets/entry_attachment_actions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final storage = AttachmentStorage.instance;
  late List<String> discarded;

  setUp(() {
    storage.overrideStores(InMemoryFileStore(), InMemoryFileStore());
    addTearDown(storage.clearStoreOverrides);
    EntryAttachmentsProvider.instance.isLoaded = true;
    EntryAttachmentsProvider.instance.attachments = [];
    addTearDown(() => EntryAttachmentsProvider.instance.isLoaded = false);
    discarded = [];
  });

  PendingAttachment pending(String name, {bool fails = false}) =>
      PendingAttachment(
        type: AttachmentType.image,
        name: name,
        sizeBytes: 1,
        store: () async {
          if (fails) throw StateError('store failed');
          final stored = await storage.create(
              name, Uint8List.fromList([1]), AttachmentType.image);
          return NewAttachment(type: AttachmentType.image, filePath: stored!);
        },
        discard: () async => discarded.add(name),
      );

  Future<bool> isStored(NewAttachment attachment) async =>
      await storage.sizeBytes(attachment.filePath, attachment.type) != null;

  test('stores every pending attachment', () async {
    final stored = await EntryAttachmentActions.storeAll(
        [pending('a.jpg'), pending('b.jpg')]);

    expect(stored, hasLength(2));
    expect(discarded, isEmpty);
    for (final attachment in stored) {
      expect(await isStored(attachment), isTrue);
    }
  });

  test('stores nothing and discards the sources when cancelled up front',
      () async {
    final stored = await EntryAttachmentActions.storeAll(
        [pending('a.jpg'), pending('b.jpg')],
        isCancelled: () => true);

    expect(stored, isEmpty);
    expect(discarded, ['a.jpg', 'b.jpg']);
  });

  test('deletes what was stored and discards the rest when cancelled midway',
      () async {
    var cancelled = false;
    final first = PendingAttachment(
      type: AttachmentType.image,
      name: 'a.jpg',
      sizeBytes: 1,
      store: () async {
        final stored = await storage.create(
            'a.jpg', Uint8List.fromList([1]), AttachmentType.image);
        cancelled = true;
        return NewAttachment(type: AttachmentType.image, filePath: stored!);
      },
    );

    final stored = await EntryAttachmentActions.storeAll(
        [first, pending('b.jpg'), pending('c.jpg')],
        isCancelled: () => cancelled);

    expect(stored, isEmpty);
    expect(discarded, ['b.jpg', 'c.jpg']);
    expect(await storage.sizeBytes('a.jpg', AttachmentType.image), isNull);
  });

  test('deletes what was stored and discards the rest when one fails',
      () async {
    await expectLater(
        EntryAttachmentActions.storeAll([
          pending('a.jpg'),
          pending('b.jpg', fails: true),
          pending('c.jpg'),
        ]),
        throwsStateError);

    expect(discarded, ['c.jpg']);
    expect(await storage.sizeBytes('a.jpg', AttachmentType.image), isNull);
  });
}
