// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:async';
import 'dart:typed_data';

import 'package:daily_you/database/image_storage.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
import 'package:daily_you/storage/file_store.dart';
import 'package:daily_you/storage/in_memory_file_store.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeImageFolder extends InMemoryFileStore {
  FakeImageFolder({super.reportsSizes, super.uniqueNamesOnCollision});

  final List<String> lookups = [];
  final List<String> writes = [];
  final List<String> deletes = [];
  final Map<String, Completer<void>> heldWrites = {};
  final Map<String, Completer<void>> heldReads = {};
  final Set<String> failingUploads = {};
  final Set<String> failingDeletes = {};
  final Set<String> listedAsEmpty = {};
  final Set<String> hiddenFromListing = {};
  final Set<String> shortReads = {};
  final Set<String> unreadableNames = {};
  bool listingFails = false;

  List<String> get reads => [
        for (final lookup in lookups)
          if (lookup.startsWith('read ')) lookup
      ];

  /// Only the first byte is written until the hold is released. Released
  /// when the test ends, so no upload outlives it.
  Completer<void> holdUploadOf(String name) {
    final hold = heldWrites[name] = Completer<void>();
    addTearDown(() async {
      if (!hold.isCompleted) hold.complete();
      await pumpEventQueue();
    });
    return hold;
  }

  @override
  Future<List<StoredFile>> listFiles() async {
    if (listingFails) throw Exception('listing failed');
    return [
      for (final file in await super.listFiles())
        if (!hiddenFromListing.contains(file.name))
          listedAsEmpty.contains(file.name) ? StoredFile(file.name, 0) : file
    ];
  }

  @override
  Future<bool> exists(String name) {
    lookups.add('exists $name');
    return super.exists(name);
  }

  @override
  Future<Uint8List?> read(String name) async {
    lookups.add('read $name');
    final bytes = await super.read(name);
    await heldReads[name]?.future;
    if (unreadableNames.contains(name)) return null;
    return shortReads.contains(name) ? bytes?.sublist(1) : bytes;
  }

  @override
  Future<bool> delete(String name) async {
    deletes.add(name);
    if (failingDeletes.contains(name)) return false;
    return super.delete(name);
  }

  @override
  Future<bool> write(String name, Uint8List bytes) async {
    writes.add(name);
    if (failingUploads.contains(name)) {
      throw Exception('provider refused $name');
    }
    final hold = heldWrites[name];
    if (hold != null) {
      await super.write(name, bytes.sublist(0, 1));
      await hold.future;
    }
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
    EntryImagesProvider.instance.isLoaded = true;
    addTearDown(() => EntryImagesProvider.instance.isLoaded = false);
    final createdTime = DateTime(2026, 1, 1);
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

  group('getBytes', () {
    test('caches an external copy without writing it internally', () async {
      final externalStore = InMemoryFileStore();
      useStores(internalStore, externalStore);
      await externalStore.write('photo.jpg', bytesOf('photo'));

      expect(await storage.getBytes('photo.jpg'), equals(bytesOf('photo')));

      expect(await internalStore.exists('photo.jpg'), isFalse);
      expect(storage.imageCache.get('photo.jpg'), equals(bytesOf('photo')));
    });

    test('falls back to the external copy when the internal one is empty',
        () async {
      final externalStore = InMemoryFileStore();
      useStores(internalStore, externalStore);
      await internalStore.write('photo.jpg', Uint8List(0));
      await externalStore.write('photo.jpg', bytesOf('photo'));

      expect(await storage.getBytes('photo.jpg'), equals(bytesOf('photo')));
      expect(await internalStore.read('photo.jpg'), isEmpty);
    });

    test('never returns or caches empty bytes', () async {
      final externalStore = InMemoryFileStore();
      useStores(internalStore, externalStore);
      await internalStore.write('photo.jpg', Uint8List(0));
      await externalStore.write('photo.jpg', Uint8List(0));

      expect(await storage.getBytes('photo.jpg'), isNull);
      expect(storage.imageCache.get('photo.jpg'), isNull);
    });
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
      externalStore.holdUploadOf(capturedName);
      storage.externalTimeout = const Duration(milliseconds: 10);
      addTearDown(() => storage.externalTimeout = const Duration(seconds: 60));

      await storage.create(null, bytesOf('photo'), currTime: captureTime);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(storage.externalSyncHealth.lastAttempt!.failureReason,
          contains('TimeoutException'));
      expect(externalStore.deletes, isEmpty);
      expect(await internalStore.read(capturedName), equals(bytesOf('photo')));
    });
  });

  group('reconcile', () {
    late FakeImageFolder folder;
    final captureTime = DateTime(2026, 1, 2, 3, 4, 5);
    const capturedName = 'daily_you_2026-01-02T03-04-05.jpg';

    Future<ImageSyncSummary> reconcile() async =>
        (await storage.reconcileImageFolder())!;

    void useFolder(FakeImageFolder imageFolder, List<String> images) {
      folder = imageFolder;
      useStores(internalStore, folder);
      useImages(images);
    }

    Future<void> writeBoth(
        String name, String internal, String external) async {
      await internalStore.write(name, bytesOf(internal));
      await folder.write(name, bytesOf(external));
    }

    void expectNothingDone(ImageSyncSummary summary) {
      expect([
        summary.uploaded,
        summary.downloaded,
        summary.repaired,
        summary.collisions,
        summary.failures
      ], everyElement(0));
    }

    group('with one copy missing', () {
      test('uploads images the Image Folder is missing', () async {
        final names = ['a.jpg', 'b.jpg', 'c.jpg'];
        useFolder(FakeImageFolder(), names);
        for (final name in names) {
          await internalStore.write(name, bytesOf(name));
        }

        expect(await storage.syncImageFolder(false), isTrue);

        for (final name in names) {
          expect(await folder.read(name), equals(bytesOf(name)));
        }
        expect(storage.externalSyncHealth.isStale, isFalse);
      });

      test('downloads images this device is missing', () async {
        useFolder(FakeImageFolder(), ['a.jpg']);
        await folder.write('a.jpg', bytesOf('a'));

        expect(await storage.syncImageFolder(false), isTrue);

        expect(await internalStore.read('a.jpg'), equals(bytesOf('a')));
      });

      test('downloads an Image Folder copy listed as 0 bytes that has bytes',
          () async {
        useFolder(FakeImageFolder(), ['a.jpg', 'b.jpg']);
        await folder.write('a.jpg', bytesOf('a'));
        await writeBoth('b.jpg', 'b', 'b');
        folder.listedAsEmpty.add('a.jpg');

        expect((await reconcile()).downloaded, 1);
        expect(await internalStore.read('a.jpg'), equals(bytesOf('a')));
      });

      test('never copies an empty Image Folder file in', () async {
        useFolder(FakeImageFolder(), ['a.jpg', 'b.jpg']);
        await folder.write('a.jpg', Uint8List(0));
        await writeBoth('b.jpg', 'b', 'b');

        final summary = await reconcile();

        expect(summary.unavailable, 1);
        expectNothingDone(summary);
        expect(await internalStore.exists('a.jpg'), isFalse);
        expect(await folder.exists('a.jpg'), isTrue);
      });

      test('counts an image with no usable copy as unavailable', () async {
        useFolder(FakeImageFolder(), ['a.jpg', 'b.jpg']);
        await internalStore.write('b.jpg', Uint8List(0));

        final summary = await reconcile();

        expect(summary.unavailable, 2);
        expectNothingDone(summary);
      });

      test('a download shorter than the listed size is refused', () async {
        useFolder(FakeImageFolder(), ['a.jpg']);
        await folder.write('a.jpg', bytesOf('photo'));
        folder.shortReads.add('a.jpg');

        final summary = await reconcile();

        expect(summary.failures, 1);
        expect(summary.downloaded, 0);
        expect(await internalStore.exists('a.jpg'), isFalse);
      });
    });

    group('with both copies', () {
      test('does nothing when both copies have the same size', () async {
        useFolder(FakeImageFolder(), ['a.jpg']);
        await writeBoth('a.jpg', 'a', 'b');
        folder.writes.clear();

        expectNothingDone(await reconcile());
        expect(folder.writes, isEmpty);
        expect(folder.reads, isEmpty);
      });

      test('does nothing when a copy listed as 0 bytes matches', () async {
        useFolder(FakeImageFolder(), ['a.jpg', 'b.jpg']);
        await writeBoth('a.jpg', 'a', 'a');
        await writeBoth('b.jpg', 'b', 'b');
        folder.listedAsEmpty.add('a.jpg');
        folder.writes.clear();

        final summary = await reconcile();

        expectNothingDone(summary);
        expect(summary.conflicts, 0);
        expect(folder.writes, isEmpty);
      });

      test('replaces a shorter Image Folder copy', () async {
        useFolder(
            FakeImageFolder(uniqueNamesOnCollision: true), ['a.jpg', 'b.jpg']);
        await writeBoth('a.jpg', 'photo a', '');
        await writeBoth('b.jpg', 'photo b', 'photo');

        final summary = await reconcile();

        expect(summary.repaired, 2);
        expect(summary.conflicts, 0);
        expect(await folder.list(), unorderedEquals(['a.jpg', 'b.jpg']));
        expect(await folder.read('a.jpg'), equals(bytesOf('photo a')));
        expect(await folder.read('b.jpg'), equals(bytesOf('photo b')));
      });

      test('replaces a shorter internal copy', () async {
        useFolder(FakeImageFolder(), ['a.jpg', 'b.jpg']);
        await writeBoth('a.jpg', '', 'photo a');
        await writeBoth('b.jpg', 'photo', 'photo b');
        folder.writes.clear();

        final summary = await reconcile();

        expect(summary.repaired, 2);
        expect(summary.conflicts, 0);
        expect(await internalStore.read('a.jpg'), equals(bytesOf('photo a')));
        expect(await internalStore.read('b.jpg'), equals(bytesOf('photo b')));
        expect(folder.writes, isEmpty);
      });

      test('counts two empty copies as unavailable', () async {
        useFolder(FakeImageFolder(), ['a.jpg', 'b.jpg']);
        await writeBoth('a.jpg', '', '');
        await writeBoth('b.jpg', 'b', 'b');

        final summary = await reconcile();

        expect(summary.unavailable, 1);
        expectNothingDone(summary);
      });

      test('reports a conflict and touches neither copy', () async {
        useFolder(FakeImageFolder(), ['a.jpg']);
        await writeBoth('a.jpg', 'mine', 'theirs!');
        folder.writes.clear();

        final summary = await reconcile();

        expect(summary.conflicts, 1);
        expectNothingDone(summary);
        expect(await internalStore.read('a.jpg'), equals(bytesOf('mine')));
        expect(await folder.read('a.jpg'), equals(bytesOf('theirs!')));
        expect(folder.writes, isEmpty);
      });

      test('reports a conflict when either copy cannot be fully read',
          () async {
        final internal = FakeImageFolder();
        internalStore = internal;
        useFolder(FakeImageFolder(),
            ['a.jpg', 'b.jpg', 'c.jpg', 'd.jpg', 'e.jpg', 'f.jpg']);
        await writeBoth('a.jpg', 'photo a', 'photo');
        await writeBoth('b.jpg', 'photo', 'photo b');
        await writeBoth('c.jpg', 'photo c', 'photo');
        await writeBoth('d.jpg', 'photo d', '');
        await writeBoth('e.jpg', 'e', 'e');
        await writeBoth('f.jpg', '', 'photo f');
        folder.unreadableNames.addAll(['a.jpg', 'd.jpg', 'f.jpg']);
        internal.unreadableNames.add('b.jpg');
        folder.shortReads.add('c.jpg');
        folder.writes.clear();
        internal.writes.clear();

        final summary = await reconcile();

        expect(summary.conflicts, 5);
        expectNothingDone(summary);
        expect(folder.writes, isEmpty);
        expect(internal.writes, isEmpty);
        expect(folder.deletes, isEmpty);
        expect(internal.deletes, isEmpty);
      });

      test('writes nothing when a shorter copy cannot be deleted', () async {
        final internal = FakeImageFolder();
        internalStore = internal;
        useFolder(FakeImageFolder(), ['a.jpg', 'b.jpg']);
        await writeBoth('a.jpg', 'photo a', 'photo');
        await writeBoth('b.jpg', 'photo', 'photo b');
        folder.failingDeletes.add('a.jpg');
        internal.failingDeletes.add('b.jpg');
        folder.writes.clear();
        internal.writes.clear();

        final summary = await reconcile();

        expect(summary.failures, 2);
        expect(summary.repaired, 0);
        expect(folder.writes, isEmpty);
        expect(internal.writes, isEmpty);
        expect(await folder.read('a.jpg'), equals(bytesOf('photo')));
        expect(await internal.read('b.jpg'), equals(bytesOf('photo')));
      });

      test(
          'a folder repair whose create fails after the delete is uploaded '
          'by the next run', () async {
        useFolder(FakeImageFolder(), ['a.jpg']);
        await writeBoth('a.jpg', 'photo a', 'photo');
        folder.failingUploads.add('a.jpg');

        final failed = await reconcile();
        expect(failed.failures, 1);
        expect(failed.repaired, 0);
        expect(await folder.exists('a.jpg'), isFalse);

        folder.failingUploads.clear();
        expect((await reconcile()).uploaded, 1);
        expect(await folder.read('a.jpg'), equals(bytesOf('photo a')));
      });

      test('a failed repair of a shorter internal copy is completed later',
          () async {
        final internal = FakeImageFolder();
        internalStore = internal;
        useFolder(FakeImageFolder(), ['a.jpg']);
        await writeBoth('a.jpg', 'photo', 'photo a');
        internal.failingUploads.add('a.jpg');

        final failed = await reconcile();
        expect(failed.failures, 1);
        expect(failed.repaired, 0);
        expect(await internal.exists('a.jpg'), isFalse);
        expect(await folder.read('a.jpg'), equals(bytesOf('photo a')));

        internal.failingUploads.clear();
        expect((await reconcile()).downloaded, 1);
        expect(await internal.read('a.jpg'), equals(bytesOf('photo a')));
      });

      test('a cut-off internal download is repaired by the next run', () async {
        useFolder(FakeImageFolder(), ['a.jpg']);
        await folder.write('a.jpg', bytesOf('photo a'));
        internalStore.writesStopAfter = 2;

        expect((await reconcile()).failures, 1);
        expect(await internalStore.read('a.jpg'), equals(bytesOf('ph')));

        internalStore.writesStopAfter = null;
        expect((await reconcile()).repaired, 1);
        expect(await internalStore.read('a.jpg'), equals(bytesOf('photo a')));
      });
    });

    group('size reporting', () {
      test('a folder listing every size as 0 is checked for presence only',
          () async {
        useFolder(
            FakeImageFolder(reportsSizes: false), ['a.jpg', 'b.jpg', 'c.jpg']);
        await writeBoth('a.jpg', 'a', 'folder a');
        await writeBoth('b.jpg', 'b', 'folder b');
        await folder.write('c.jpg', bytesOf('c'));
        folder.writes.clear();

        final summary = await reconcile();

        expect(summary.skippedSizeUnknown, 2);
        expect(summary.downloaded, 1);
        expect(summary.uploaded + summary.repaired, 0);
        expect(await internalStore.read('c.jpg'), equals(bytesOf('c')));
        expect(folder.reads, equals(['read c.jpg']));
        expect(folder.writes, isEmpty);
      });

      test('an empty internal copy is replaced when sizes are unknown',
          () async {
        useFolder(FakeImageFolder(reportsSizes: false), ['a.jpg']);
        await writeBoth('a.jpg', '', 'a');

        expect((await reconcile()).repaired, 1);
        expect(await internalStore.read('a.jpg'), equals(bytesOf('a')));
      });

      test('only differing copies are read', () async {
        useFolder(FakeImageFolder(), ['a.jpg', 'b.jpg']);
        await writeBoth('a.jpg', 'a', 'a');
        await writeBoth('b.jpg', 'b', '');

        await reconcile();
        expect(folder.reads, equals(['read b.jpg']));
      });
    });

    test('a failed listing aborts with nothing uploaded or downloaded',
        () async {
      useFolder(FakeImageFolder(), ['a.jpg', 'b.jpg']);
      await internalStore.write('a.jpg', bytesOf('a'));
      await folder.write('b.jpg', bytesOf('b'));
      folder.listingFails = true;
      folder.writes.clear();

      await expectLater(reconcile(), throwsException);
      await expectLater(storage.syncImageFolder(false), throwsException);
      expect(folder.writes, isEmpty);
      expect(await internalStore.exists('b.jpg'), isFalse);
    });

    test('an empty listing of a full folder stops after 3 collisions',
        () async {
      final names = ['a.jpg', 'b.jpg', 'c.jpg', 'd.jpg', 'e.jpg'];
      useFolder(FakeImageFolder(uniqueNamesOnCollision: true), names);
      for (final name in names) {
        await writeBoth(name, name, name);
      }
      folder.hiddenFromListing.addAll(names);
      folder.writes.clear();

      final summary = await reconcile();

      expect(summary.collisions, 3);
      expect(folder.writes, hasLength(3));
      expect(await folder.list(), unorderedEquals(names));
      for (final name in names) {
        expect(await folder.read(name), equals(bytesOf(name)));
      }
    });

    test('a truncated listing replaces and deletes nothing', () async {
      final names = ['a.jpg', 'b.jpg', 'c.jpg', 'd.jpg'];
      useFolder(FakeImageFolder(uniqueNamesOnCollision: true), names);
      for (final name in names) {
        await writeBoth(name, name, 'folder $name');
      }
      folder.hiddenFromListing.addAll(['b.jpg', 'c.jpg']);

      final summary = await reconcile();

      expect(summary.collisions, 2);
      expect(await folder.list(), unorderedEquals(names));
      for (final name in names) {
        expect(await folder.read(name), equals(bytesOf('folder $name')));
      }
    });

    group('circuit breaker', () {
      final names = ['a.jpg', 'b.jpg', 'c.jpg', 'd.jpg', 'e.jpg'];

      setUp(() async {
        useFolder(FakeImageFolder(), names);
        for (final name in names) {
          await internalStore.write(name, bytesOf(name));
        }
      });

      test('stops after 3 consecutive failures, and the next run starts over',
          () async {
        folder.failingUploads.addAll(['a.jpg', 'b.jpg', 'c.jpg']);

        final stopped = await reconcile();
        expect(stopped.failures, 3);
        expect(folder.writes, hasLength(3));
        expect(await folder.list(), isEmpty);

        folder.failingUploads.clear();
        expect((await reconcile()).uploaded, 5);
      });

      test('is reset by a success', () async {
        folder.failingUploads.addAll(['a.jpg', 'b.jpg', 'd.jpg', 'e.jpg']);

        final summary = await reconcile();

        expect(summary.failures, 4);
        expect(summary.uploaded, 1);
      });

      test('ignores files that cannot be read', () async {
        for (final name in ['a.jpg', 'b.jpg', 'c.jpg']) {
          await internalStore.delete(name);
          await folder.write(name, bytesOf(name));
          folder.unreadableNames.add(name);
        }

        final summary = await reconcile();

        expect(summary.failures, 3);
        expect(summary.uploaded, 2);
      });

      test('counts timeouts as failures', () async {
        storage.externalTimeout = const Duration(milliseconds: 10);
        addTearDown(
            () => storage.externalTimeout = const Duration(seconds: 60));
        for (final name in names) {
          folder.holdUploadOf(name);
        }

        final summary = await reconcile();

        expect(summary.failures, 3);
        expect(folder.writes, hasLength(3));
        expect(folder.deletes, isEmpty);
      });
    });

    test('records an upload that throws', () async {
      useFolder(
          FakeImageFolder()..failingUploads.add('photo.jpg'), ['photo.jpg']);
      await internalStore.write('photo.jpg', bytesOf('photo'));

      await storage.syncImageFolder(false);

      expect(storage.externalSyncHealth.lastAttempt!.failureReason,
          contains('provider refused'));
    });

    test('a timed-out upload is left alone until it lands', () async {
      useFolder(FakeImageFolder(), ['a.jpg']);
      await internalStore.write('a.jpg', bytesOf('photo a'));
      storage.externalTimeout = const Duration(milliseconds: 10);
      addTearDown(() => storage.externalTimeout = const Duration(seconds: 60));
      final upload = folder.holdUploadOf('a.jpg');

      expect((await reconcile()).failures, 1);
      folder.writes.clear();

      expectNothingDone(await reconcile());
      expect(folder.writes, isEmpty);
      expect(folder.deletes, isEmpty);

      upload.complete();
      await pumpEventQueue();
      expectNothingDone(await reconcile());
      expect(await folder.read('a.jpg'), equals(bytesOf('photo a')));
    });

    test('counts a name differing only by case as present', () async {
      useFolder(FakeImageFolder(), ['photo.jpg']);
      await internalStore.write('photo.jpg', bytesOf('photo'));
      await folder.write('PHOTO.JPG', bytesOf('photo'));
      folder.writes.clear();

      expectNothingDone(await reconcile());
      expect(folder.writes, isEmpty);
    });

    test('the newest request stops running and queued passes, then runs',
        () async {
      useFolder(FakeImageFolder(), ['a.jpg', 'b.jpg', 'c.jpg']);
      for (final name in ['a.jpg', 'b.jpg', 'c.jpg']) {
        await internalStore.write(name, bytesOf(name));
      }
      final slowUpload = folder.holdUploadOf('a.jpg');
      final first = reconcile();
      await pumpEventQueue();

      final second = reconcile();
      final third = reconcile();
      slowUpload.complete();

      expect((await first).uploaded, 1);
      expectNothingDone(await second);
      expect((await third).uploaded, 2);
      expect(await folder.list(), unorderedEquals(['a.jpg', 'b.jpg', 'c.jpg']));
    });

    test('an Image Folder read that never answers times out', () async {
      useFolder(FakeImageFolder(), ['a.jpg']);
      await folder.write('a.jpg', bytesOf('a'));
      storage.externalTimeout = const Duration(milliseconds: 10);
      addTearDown(() => storage.externalTimeout = const Duration(seconds: 60));
      folder.heldReads['a.jpg'] = Completer<void>();

      expect((await reconcile()).failures, 1);
      expect(await internalStore.exists('a.jpg'), isFalse);
    });

    test('whileNotSyncing runs once the running upload ends, then alone',
        () async {
      useFolder(FakeImageFolder(), ['a.jpg', 'b.jpg']);
      await internalStore.write('a.jpg', bytesOf('a'));
      await internalStore.write('b.jpg', bytesOf('b'));
      final slowUpload = folder.holdUploadOf('a.jpg');
      final run = reconcile();
      await pumpEventQueue();

      final seen = storage.whileNotSyncing(() => folder.list());
      slowUpload.complete();

      expect(await seen, equals(['a.jpg']));
      expect((await run).uploaded, 1);
      expect(await folder.list(), equals(['a.jpg']));
    });

    test('a download keeps an internal copy written during the run', () async {
      useFolder(FakeImageFolder(), ['a.jpg']);
      await folder.write('a.jpg', bytesOf('folder a'));
      final slowRead = folder.heldReads['a.jpg'] = Completer<void>();
      final run = reconcile();
      await pumpEventQueue();

      await internalStore.write('a.jpg', bytesOf('restored a'));
      slowRead.complete();

      final summary = await run;
      expect(summary.downloaded, 0);
      expect(summary.collisions, 1);
      expect(await internalStore.read('a.jpg'), equals(bytesOf('restored a')));
    });

    test('a capture during a long run uploads right away', () async {
      useFolder(FakeImageFolder(), ['a.jpg']);
      await internalStore.write('a.jpg', bytesOf('a'));
      final slowUpload = folder.holdUploadOf('a.jpg');
      final run = reconcile();
      await pumpEventQueue();

      await storage.create(null, bytesOf('photo'), currTime: captureTime);
      await pumpEventQueue();
      expect(await folder.read(capturedName), equals(bytesOf('photo')));

      slowUpload.complete();
      expect((await run).uploaded, 1);
    });

    test('a capture and a run uploading the same image leave one file',
        () async {
      useFolder(FakeImageFolder(uniqueNamesOnCollision: true),
          ['a.jpg', capturedName]);
      await internalStore.write('a.jpg', bytesOf('a'));
      final capture = folder.holdUploadOf(capturedName);
      folder.hiddenFromListing.add(capturedName);
      await storage.create(null, bytesOf('photo'), currTime: captureTime);
      await pumpEventQueue();
      final slowUpload = folder.holdUploadOf('a.jpg');
      final run = reconcile();
      await pumpEventQueue();

      capture.complete();
      await pumpEventQueue();
      slowUpload.complete();
      final summary = await run;

      expect(summary.collisions, 1);
      expect(await folder.list(), unorderedEquals(['a.jpg', capturedName]));
      expect(await folder.read(capturedName), equals(bytesOf('photo')));
    });

    test('an image created without an upload is uploaded by the next run',
        () async {
      useFolder(FakeImageFolder(), [capturedName]);
      await storage.create(null, bytesOf('photo'),
          currTime: captureTime, skipExternalUpload: true);
      await pumpEventQueue();
      expect(folder.writes, isEmpty);
      expect(await internalStore.read(capturedName), equals(bytesOf('photo')));

      expect((await reconcile()).uploaded, 1);
      expect(await folder.read(capturedName), equals(bytesOf('photo')));
    });

    test('a second run with no changes does nothing', () async {
      useFolder(
          FakeImageFolder(), ['a.jpg', 'b.jpg', 'c.jpg', 'd.jpg', 'e.jpg']);
      await internalStore.write('a.jpg', bytesOf('a'));
      await folder.write('b.jpg', bytesOf('b'));
      await writeBoth('c.jpg', 'c', '');
      await writeBoth('d.jpg', 'photo d', 'photo');
      await writeBoth('e.jpg', 'photo', 'photo e');
      await reconcile();
      folder.writes.clear();
      folder.lookups.clear();

      expectNothingDone(await reconcile());
      expect(folder.writes, isEmpty);
      expect(folder.reads, isEmpty);
    });

    test('repairs a library with scattered missing and empty files', () async {
      final names = [for (var i = 0; i < 30; i++) 'photo_$i.jpg'];
      useFolder(FakeImageFolder(), names);
      for (final (index, name) in names.indexed) {
        await internalStore.write(name, bytesOf(name));
        if (index % 3 == 1) await folder.write(name, Uint8List(0));
        if (index % 3 == 2) await folder.write(name, bytesOf(name));
      }

      final summary = await reconcile();

      expect(summary.uploaded, 10);
      expect(summary.repaired, 10);
      for (final name in names) {
        expect(await folder.read(name), equals(bytesOf(name)));
      }
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
    await internalStore.write('kept.jpg', bytesOf('kept'));
    await internalStore.write('orphan.jpg', bytesOf('orphan'));

    expect(await storage.garbageCollectImages(), isTrue);

    expect(await internalStore.list(), equals(['kept.jpg']));
  });
}
