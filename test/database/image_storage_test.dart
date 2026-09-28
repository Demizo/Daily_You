import 'dart:async';
import 'dart:typed_data';

import 'package:daily_you/database/entry_store.dart';
import 'package:daily_you/database/image_storage.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/image.dart';
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

class FakeImageFolder extends InMemoryFileStore {
  FakeImageFolder({super.reportsSizes, super.uniqueNamesOnCollision});

  final List<String> lookups = [];
  final List<String> writes = [];
  final List<String> deletes = [];
  final Map<String, Completer<void>> heldWrites = {};

  Completer<void> holdWritesOf(String name) =>
      heldWrites[name] = Completer<void>();

  @override
  Future<bool> exists(String name) {
    lookups.add('exists $name');
    return super.exists(name);
  }

  @override
  Future<Uint8List?> read(String name) {
    lookups.add('read $name');
    return super.read(name);
  }

  @override
  Future<bool> delete(String name) {
    deletes.add(name);
    return super.delete(name);
  }

  @override
  Future<bool> write(String name, Uint8List bytes) async {
    writes.add(name);
    await heldWrites[name]?.future;
    return super.write(name, bytes);
  }
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
    EntryStore.instance.entries = [
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

  group('capture', () {
    final captureTime = DateTime(2026, 1, 2, 3, 4, 5);
    const capturedName = 'daily_you_2026-01-02T03-04-05.jpg';

    test('uploads without looking anything up first', () async {
      final externalStore = FakeImageFolder();
      useStores(internalStore, externalStore);

      final name =
          await storage.create(null, bytesOf('photo'), currTime: captureTime);
      await pumpEventQueue();

      expect(name, capturedName);
      expect(externalStore.lookups, isEmpty);
      expect(await externalStore.list(), equals([capturedName]));
      expect(await externalStore.read(capturedName), equals(bytesOf('photo')));
    });

    test('leaves an existing file with the same name untouched', () async {
      final externalStore = InMemoryFileStore(uniqueNamesOnCollision: true);
      useStores(internalStore, externalStore);
      await externalStore.write(capturedName, bytesOf('other device'));

      await storage.create(null, bytesOf('photo'), currTime: captureTime);
      await pumpEventQueue();

      expect(await externalStore.list(), equals([capturedName]));
      expect(await externalStore.read(capturedName),
          equals(bytesOf('other device')));
    });

    test('that is interrupted is reported', () async {
      final externalStore = InMemoryFileStore()..writesStopAfter = 0;
      useStores(internalStore, externalStore);

      await storage.create(null, bytesOf('photo'), currTime: captureTime);
      await pumpEventQueue();

      expect(storage.externalSyncHealth.lastAttempt!.failureReason,
          contains('stopped'));
    });

    test('that times out is reported and deletes nothing', () async {
      final externalStore = FakeImageFolder();
      useStores(internalStore, externalStore);
      externalStore.holdWritesOf(capturedName);
      storage.externalCreateTimeout = const Duration(milliseconds: 10);
      addTearDown(
          () => storage.externalCreateTimeout = const Duration(seconds: 60));

      await storage.create(null, bytesOf('photo'), currTime: captureTime);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(storage.externalSyncHealth.lastAttempt!.failureReason,
          contains('TimeoutException'));
      expect(externalStore.deletes, isEmpty);
      expect(await internalStore.read(capturedName), equals(bytesOf('photo')));
    });

    test('with skipExternalUpload writes internally only', () async {
      final externalStore = FakeImageFolder();
      useStores(internalStore, externalStore);

      await storage.create(null, bytesOf('photo'),
          currTime: captureTime, skipExternalUpload: true);
      await pumpEventQueue();

      expect(await internalStore.read(capturedName), equals(bytesOf('photo')));
      expect(externalStore.writes, isEmpty);
    });
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
