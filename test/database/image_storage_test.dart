import 'dart:typed_data';

import 'package:daily_you/database/image_storage.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
import 'package:daily_you/storage/file_store.dart';
import 'package:daily_you/storage/in_memory_file_store.dart';
import 'package:flutter_test/flutter_test.dart';

class RejectingFileStore extends InMemoryFileStore {
  @override
  Future<bool> write(String name, Uint8List bytes) async => false;
}

class UnreachableFileStore extends InMemoryFileStore {
  @override
  Future<bool> write(String name, Uint8List bytes) async =>
      throw Exception('permission revoked');
}

void main() {
  final storage = ImageStorage.instance;
  late InMemoryFileStore internalStore;

  Uint8List bytesOf(String text) => Uint8List.fromList(text.codeUnits);

  void useStores(FileStore internal, FileStore external) {
    storage.overrideStores(internal, external);
    addTearDown(storage.clearStoreOverrides);
  }

  void useImages(List<String> imageNames) {
    final createdTime = DateTime(2026, 1, 1);
    EntriesProvider.instance.entries = [
      Entry(id: 1, text: '', timeCreate: createdTime, timeModified: createdTime)
    ];
    EntryImagesProvider.instance.images = [
      for (final (rank, name) in imageNames.indexed)
        EntryImage(
            entryId: 1, imgPath: name, imgRank: rank, timeCreate: createdTime)
    ];
  }

  setUp(() {
    internalStore = InMemoryFileStore();
    storage.imageCache.clear();
  });

  test('exports images the external location is missing', () async {
    final externalStore = InMemoryFileStore();
    useStores(internalStore, externalStore);
    useImages(['photo.jpg']);
    await internalStore.write('photo.jpg', bytesOf('photo'));

    expect(await storage.syncImageFolder(false), isTrue);

    expect(await externalStore.read('photo.jpg'), equals(bytesOf('photo')));
    expect(storage.externalSyncHealth.isStale, isFalse);
  });

  test('imports images the internal location is missing', () async {
    final externalStore = InMemoryFileStore();
    useStores(internalStore, externalStore);
    useImages(['photo.jpg']);
    await externalStore.write('photo.jpg', bytesOf('photo'));

    expect(await storage.syncImageFolder(false), isTrue);

    expect(await internalStore.read('photo.jpg'), equals(bytesOf('photo')));
  });

  test('records a rejected external write', () async {
    useStores(internalStore, RejectingFileStore());
    useImages(['photo.jpg']);
    await internalStore.write('photo.jpg', bytesOf('photo'));

    await storage.syncImageFolder(false);

    expect(storage.externalSyncHealth.isStale, isTrue);
    expect(storage.externalSyncHealth.lastAttempt!.failureReason, isNotNull);
  });

  test('records an external write that throws', () async {
    useStores(internalStore, UnreachableFileStore());
    useImages(['photo.jpg']);
    await internalStore.write('photo.jpg', bytesOf('photo'));

    await storage.syncImageFolder(false);

    expect(storage.externalSyncHealth.lastAttempt!.failureReason,
        contains('permission revoked'));
  });

  test('refuses to garbage collect before the images load', () async {
    useStores(internalStore, InMemoryFileStore());
    await internalStore.write('photo.jpg', bytesOf('photo'));

    expect(EntryImagesProvider.instance.isLoaded, isFalse);
    await expectLater(storage.garbageCollectImages(), throwsStateError);
    expect(await internalStore.exists('photo.jpg'), isTrue);
  });

  test('deletes only unreferenced images', () async {
    useStores(internalStore, InMemoryFileStore());
    useImages(['kept.jpg']);
    EntryImagesProvider.instance.isLoaded = true;
    addTearDown(() => EntryImagesProvider.instance.isLoaded = false);
    await internalStore.write('kept.jpg', bytesOf('kept'));
    await internalStore.write('orphan.jpg', bytesOf('orphan'));

    expect(await storage.garbageCollectImages(), isTrue);

    expect(await internalStore.list(), equals(['kept.jpg']));
  });
}
