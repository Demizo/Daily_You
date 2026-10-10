// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/database/attachment_storage.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/storage/file_store.dart';
import 'package:daily_you/storage/in_memory_file_store.dart';
import 'package:daily_you/storage/local_file_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' show basename, join;
import '../support/source_file.dart';

class ListingCountingStore extends InMemoryFileStore {
  int listings = 0;

  @override
  Future<List<String>> list() {
    listings += 1;
    return super.list();
  }
}

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

class UploadSignalingStore extends InMemoryFileStore {
  final uploaded = Completer<void>();

  @override
  Future<CreateResult> createNewFromFile(String name, File source) async {
    final result = await super.createNewFromFile(name, source);
    uploaded.complete();
    return result;
  }
}

class StuckStore extends InMemoryFileStore {
  @override
  Future<bool> delete(String name) async =>
      throw const FileSystemException('read-only');
}

void main() {
  final storage = AttachmentStorage.instance;
  late InMemoryFileStore internalStore;

  Uint8List bytesOf(String text) => Uint8List.fromList(text.codeUnits);

  void useStores(FileStore internal, FileStore external) {
    storage.overrideStores(internal, external);
    addTearDown(storage.clearStoreOverrides);
  }

  void useImages(List<String> imageNames) {
    EntryAttachmentsProvider.instance.isLoaded = true;
    addTearDown(() => EntryAttachmentsProvider.instance.isLoaded = false);
    final createdTime = DateTime(2026, 1, 1);
    EntryAttachmentsProvider.instance.attachments = [
      for (final (rank, name) in imageNames.indexed)
        EntryAttachment(
            entryId: 1,
            type: AttachmentType.image,
            filePath: name,
            rank: rank,
            timeCreate: createdTime)
    ];
  }

  void useAttachments(List<(AttachmentType, String)> attachments) {
    EntryAttachmentsProvider.instance.isLoaded = true;
    addTearDown(() => EntryAttachmentsProvider.instance.isLoaded = false);
    final createdTime = DateTime(2026, 1, 1);
    EntryAttachmentsProvider.instance.attachments = [
      for (final (rank, (type, name)) in attachments.indexed)
        EntryAttachment(
            entryId: 1,
            type: type,
            filePath: name,
            rank: rank,
            timeCreate: createdTime)
    ];
  }

  setUp(() {
    internalStore = InMemoryFileStore();
    storage.bytesCache.clear();
  });

  group('getBytes', () {
    test('caches an external copy without writing it internally', () async {
      final externalStore = InMemoryFileStore();
      useStores(internalStore, externalStore);
      await externalStore.write('photo.jpg', bytesOf('photo'));

      expect(await storage.getBytes('photo.jpg', AttachmentType.image),
          equals(bytesOf('photo')));

      expect(await internalStore.exists('photo.jpg'), isFalse);
      expect(storage.bytesCache.get('photo.jpg'), equals(bytesOf('photo')));
    });

    test('falls back to the external copy when the internal one is empty',
        () async {
      final externalStore = InMemoryFileStore();
      useStores(internalStore, externalStore);
      await internalStore.write('photo.jpg', Uint8List(0));
      await externalStore.write('photo.jpg', bytesOf('photo'));

      expect(await storage.getBytes('photo.jpg', AttachmentType.image),
          equals(bytesOf('photo')));
      expect(await internalStore.read('photo.jpg'), isEmpty);
    });

    test('never returns or caches empty bytes', () async {
      final externalStore = InMemoryFileStore();
      useStores(internalStore, externalStore);
      await internalStore.write('photo.jpg', Uint8List(0));
      await externalStore.write('photo.jpg', Uint8List(0));

      expect(await storage.getBytes('photo.jpg', AttachmentType.image), isNull);
      expect(storage.bytesCache.get('photo.jpg'), isNull);
    });
  });

  group('delete', () {
    test('forgets the cached bytes so a reused name shows new content',
        () async {
      useStores(internalStore, InMemoryFileStore());
      final first = await storage.create(
          'photo.jpg', bytesOf('first'), AttachmentType.image,
          keepFileName: true);
      expect(await storage.getBytes(first!, AttachmentType.image),
          equals(bytesOf('first')));

      await storage.delete(first, AttachmentType.image);
      final second = await storage.create(
          'photo.jpg', bytesOf('second'), AttachmentType.image,
          keepFileName: true);

      expect(second, first);
      expect(await storage.getBytes(second!, AttachmentType.image),
          equals(bytesOf('second')));
    });

    test('announces the deleted file', () async {
      useStores(internalStore, InMemoryFileStore());
      final name =
          await storage.create('clip.mp4', bytesOf('a'), AttachmentType.video);
      final announced = storage.deletions.first;

      await storage.delete(name!, AttachmentType.video);

      expect(await announced, (type: AttachmentType.video, fileName: name));
    });
  });

  group('getLocalPath', () {
    late Directory support;
    late Directory imageFolder;
    late FakeImageFolder externalStore;

    setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

    setUp(() async {
      support = await Directory.systemTemp.createTemp('local_path');
      imageFolder = await Directory(join(support.path, 'Images')).create();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('plugins.flutter.io/path_provider'),
              (call) async => support.path);
      externalStore = FakeImageFolder();
      useStores(LocalFileStore(imageFolder.path), externalStore);
    });

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('plugins.flutter.io/path_provider'), null);
      await support.delete(recursive: true);
    });

    test('returns the internal file without asking the external location',
        () async {
      await File(join(imageFolder.path, 'photo.jpg')).writeAsString('photo');

      final path =
          await storage.getLocalPath('photo.jpg', AttachmentType.image);

      expect(path, join(imageFolder.path, 'photo.jpg'));
      expect(externalStore.lookups, isEmpty);
    });

    test('copies a file only the external location has into the folder',
        () async {
      await externalStore.write('photo.jpg', bytesOf('photo'));

      final path =
          await storage.getLocalPath('photo.jpg', AttachmentType.image);

      expect(File(path!).readAsStringSync(), 'photo');
      expect(imageFolder.listSync().map((entity) => basename(entity.path)),
          equals(['photo.jpg']));
    });

    test('fetches without caching the bytes in memory', () async {
      await externalStore.write('photo.jpg', bytesOf('photo'));

      await storage.getLocalPath('photo.jpg', AttachmentType.image);

      expect(storage.bytesCache.get('photo.jpg'), isNull);
    });

    test('is null and leaves nothing behind when no copy exists', () async {
      expect(await storage.getLocalPath('photo.jpg', AttachmentType.image),
          isNull);
      expect(imageFolder.listSync(), isEmpty);
    });

    test('is null and leaves nothing behind for an empty external copy',
        () async {
      await externalStore.write('photo.jpg', Uint8List(0));

      expect(await storage.getLocalPath('photo.jpg', AttachmentType.image),
          isNull);
      expect(imageFolder.listSync(), isEmpty);
    });

    test('is null when the external copy cannot be read', () async {
      await externalStore.write('photo.jpg', bytesOf('photo'));
      externalStore.unreadableNames.add('photo.jpg');

      expect(await storage.getLocalPath('photo.jpg', AttachmentType.image),
          isNull);
      expect(imageFolder.listSync(), isEmpty);
    });
  });

  group('capture', () {
    final captureTime = DateTime(2026, 1, 2, 3, 4, 5);
    const capturedName = 'daily_you_2026-01-02T03-04-05.jpg';

    test('uploads without looking anything up first', () async {
      final externalStore = FakeImageFolder();
      useStores(internalStore, externalStore);

      final name = await storage.create(
          null, bytesOf('photo'), AttachmentType.image,
          currTime: captureTime);
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

      await storage.create(null, bytesOf('photo'), AttachmentType.image,
          currTime: captureTime);
      await pumpEventQueue();

      expect(await externalStore.list(), equals([capturedName]));
      expect(await externalStore.read(capturedName),
          equals(bytesOf('other device')));
    });

    test('that is interrupted is reported', () async {
      final externalStore = InMemoryFileStore()..writesStopAfter = 0;
      useStores(internalStore, externalStore);

      await storage.create(null, bytesOf('photo'), AttachmentType.image,
          currTime: captureTime);
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

      await storage.create(null, bytesOf('photo'), AttachmentType.image,
          currTime: captureTime);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(storage.externalSyncHealth.lastAttempt!.failureReason,
          contains('TimeoutException'));
      expect(externalStore.deletes, isEmpty);
      expect(await internalStore.read(capturedName), equals(bytesOf('photo')));
    });
  });

  group('a large upload', () {
    test('gets longer to finish than a small one', () async {
      final externalStore = FakeImageFolder();
      useStores(internalStore, externalStore);
      const name = 'daily_you_2026-01-02T03-04-05.jpg';
      final upload = externalStore.holdUploadOf(name);
      storage.externalTimeout = const Duration(milliseconds: 10);
      addTearDown(() => storage.externalTimeout = const Duration(seconds: 60));

      await storage.create(
          null, Uint8List(8 * 1024 * 1024), AttachmentType.image,
          currTime: DateTime(2026, 1, 2, 3, 4, 5));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      upload.complete();
      await pumpEventQueue();

      expect(storage.externalSyncHealth.lastAttempt!.succeeded, isTrue);
    });
  });

  group('attachment types', () {
    final captureTime = DateTime(2026, 1, 2, 3, 4, 5);
    const stamp = 'daily_you_2026-01-02T03-04-05';

    Future<FileStore> internalOf(AttachmentType type) =>
        storage.internalStore(type);
    Future<FileStore> externalOf(AttachmentType type) async =>
        (await storage.externalStore(type))!;

    setUp(() => useStores(internalStore, InMemoryFileStore()));

    test('routes each type to its own folder', () async {
      for (final type in AttachmentType.values) {
        await storage.create('x.bin', bytesOf(type.name), type,
            currTime: captureTime);
      }
      await pumpEventQueue();

      for (final type in AttachmentType.values) {
        final names = await (await internalOf(type)).list();
        expect(names, hasLength(1), reason: type.name);
        expect(await (await internalOf(type)).read(names.single),
            equals(bytesOf(type.name)));
        final external = await (await externalOf(type)).list();
        expect(external, equals(names), reason: type.name);
      }
    });

    test('names a new file with the extension of the one given', () async {
      final name = await storage.create(
          'song.flac', bytesOf('a'), AttachmentType.audio,
          currTime: captureTime);

      expect(name, '$stamp.flac');
    });

    test('falls back to the default extension of the type', () async {
      for (final (type, extension) in [
        (AttachmentType.image, '.jpg'),
        (AttachmentType.audio, '.m4a'),
        (AttachmentType.video, '.mp4'),
      ]) {
        expect(
            await storage.create(null, bytesOf('a'), type,
                currTime: captureTime),
            '$stamp$extension');
        expect(
            await storage.create('content-name', bytesOf('a'), type,
                currTime: captureTime),
            '${stamp}_1$extension');
      }
    });

    test('never reuses a file already in the folder', () async {
      await internalStore.write('photo.jpg', bytesOf('first'));

      final name = await storage.create(
          'photo.jpg', bytesOf('second'), AttachmentType.image,
          currTime: captureTime);

      expect(name, '$stamp.jpg');
      expect(await internalStore.read('photo.jpg'), equals(bytesOf('first')));
      expect(await internalStore.read(name!), equals(bytesOf('second')));
    });

    test('keeps the given name when asked', () async {
      final name = await storage.create(
          'Holiday photo.JPG', bytesOf('a'), AttachmentType.image,
          keepFileName: true, currTime: captureTime);

      expect(name, 'Holiday photo.JPG');
      expect(await internalStore.read(name!), equals(bytesOf('a')));
    });

    test('numbers a kept name that is already taken', () async {
      final names = [
        for (final content in ['a', 'b', 'c'])
          await storage.create(
              'photo.jpg', bytesOf(content), AttachmentType.image,
              keepFileName: true, currTime: captureTime)
      ];

      expect(names, ['photo.jpg', 'photo_1.jpg', 'photo_2.jpg']);
      expect(await internalStore.read('photo.jpg'), equals(bytesOf('a')));
      expect(await internalStore.read('photo_2.jpg'), equals(bytesOf('c')));
    });

    test('keeps only the file name of a given path and limits its length',
        () async {
      final nested = await storage.create(
          'albums/2026/trip.mp3', bytesOf('a'), AttachmentType.audio,
          keepFileName: true, currTime: captureTime);
      final long = await storage.create(
          '${'x' * 300}.mp3', bytesOf('b'), AttachmentType.audio,
          keepFileName: true, currTime: captureTime);

      expect(nested, 'trip.mp3');
      expect(long, '${'x' * 100}.mp3');
    });

    test('treats names that differ only by case as taken', () async {
      final names = [
        for (final name in ['Photo.JPG', 'photo.jpg', 'PHOTO.jpg'])
          await storage.create(name, bytesOf(name), AttachmentType.image,
              keepFileName: true, currTime: captureTime)
      ];

      expect(names, ['Photo.JPG', 'photo_1.jpg', 'PHOTO_2.jpg']);
    });

    group('with a shared set of taken names', () {
      test('keeps names from one import apart, ignoring case', () async {
        final takenNames =
            await storage.takenLowerCaseNames(AttachmentType.image);

        final names = [
          for (final name in [
            'Photo.JPG',
            'photo.jpg',
            'PHOTO.jpg',
            'photo_1.jpg'
          ])
            await storage.create(name, bytesOf(name), AttachmentType.image,
                keepFileName: true,
                currTime: captureTime,
                takenNames: takenNames)
        ];

        expect(names,
            ['Photo.JPG', 'photo_1.jpg', 'PHOTO_2.jpg', 'photo_1_1.jpg']);
        expect(takenNames,
            {'photo.jpg', 'photo_1.jpg', 'photo_2.jpg', 'photo_1_1.jpg'});
      });

      test('lists the folder once per import', () async {
        final countingStore = ListingCountingStore();
        useStores(countingStore, InMemoryFileStore());
        useAttachments([(AttachmentType.image, 'Synced.jpg')]);
        final takenNames =
            await storage.takenLowerCaseNames(AttachmentType.image);

        final names = [
          for (var count = 0; count < 3; count++)
            await storage.create(null, bytesOf('$count'), AttachmentType.image,
                currTime: captureTime,
                skipExternalUpload: true,
                takenNames: takenNames),
          await storage.create('synced.jpg', bytesOf('a'), AttachmentType.image,
              keepFileName: true, takenNames: takenNames),
        ];

        expect(names, [
          '$stamp.jpg',
          '${stamp}_1.jpg',
          '${stamp}_2.jpg',
          'synced_1.jpg',
        ]);
        expect(countingStore.listings, 1);
      });

      test('lists the folder for every file without it', () async {
        final countingStore = ListingCountingStore();
        useStores(countingStore, InMemoryFileStore());

        for (var count = 0; count < 3; count++) {
          await storage.create(null, bytesOf('$count'), AttachmentType.image,
              currTime: captureTime, skipExternalUpload: true);
        }

        expect(countingStore.listings, 3);
      });
    });

    test('does not reuse a name an entry already references', () async {
      useAttachments([(AttachmentType.image, 'Synced.jpg')]);

      final name = await storage.create(
          'synced.jpg', bytesOf('a'), AttachmentType.image,
          keepFileName: true, currTime: captureTime);

      expect(name, 'synced_1.jpg');
    });

    test('a referenced name only blocks its own type', () async {
      useAttachments([(AttachmentType.audio, 'clip.mp4')]);

      final name = await storage.create(
          'clip.mp4', bytesOf('a'), AttachmentType.video,
          keepFileName: true, currTime: captureTime);

      expect(name, 'clip.mp4');
    });

    test('stores a name with rejected characters under a safe one', () async {
      final name = await storage.create(
          'what?:*.m<p>4', bytesOf('a'), AttachmentType.video,
          keepFileName: true, currTime: captureTime);

      expect(name, 'what___.m_p_4');
      expect(await (await internalOf(AttachmentType.video)).list(), [name]);
    });

    test('keeps a long multibyte name within the file name limit', () async {
      final name = await storage.create(
          '${'音' * 200}.m4a', bytesOf('a'), AttachmentType.audio,
          keepFileName: true, currTime: captureTime);

      expect(utf8.encode(name!).length, lessThanOrEqualTo(255));
      expect(name, endsWith('.m4a'));
    });

    test('createFromFile keeps the given name when asked', () async {
      final name = await storage.createFromFile(
          'clip.mov', sourceFile('clip bytes'), AttachmentType.video,
          keepFileName: true, currTime: captureTime);

      expect(name, 'clip.mov');
      final folder = await internalOf(AttachmentType.video);
      expect(await folder.read(name!), equals(bytesOf('clip bytes')));
    });

    test('gives two captures in the same second different files', () async {
      final first = await storage.create(
          null, bytesOf('one'), AttachmentType.video,
          currTime: captureTime);
      final second = await storage.create(
          null, bytesOf('two'), AttachmentType.video,
          currTime: captureTime);

      expect(second, isNot(first));
      final folder = await internalOf(AttachmentType.video);
      expect(await folder.read(first!), equals(bytesOf('one')));
      expect(await folder.read(second!), equals(bytesOf('two')));
    });

    test('createFromFile copies a file that may then be deleted', () async {
      final source = sourceFile('clip bytes');

      final name = await storage.createFromFile(
          'clip.mov', source, AttachmentType.video,
          currTime: captureTime);
      source.deleteSync();
      await pumpEventQueue();

      expect(name, '$stamp.mov');
      expect(await (await internalOf(AttachmentType.video)).read(name!),
          equals(bytesOf('clip bytes')));
      expect(await (await externalOf(AttachmentType.video)).read(name),
          equals(bytesOf('clip bytes')));
    });

    test('createFromFile uploads from the internal copy of a real folder',
        () async {
      final folder = Directory.systemTemp.createTempSync('internal_videos');
      addTearDown(() => folder.deleteSync(recursive: true));
      final external = UploadSignalingStore();
      useStores(LocalFileStore(folder.path), external);
      final source = sourceFile('real bytes');

      final name = await storage.createFromFile(
          null, source, AttachmentType.image,
          currTime: captureTime);
      source.deleteSync();
      await external.uploaded.future;

      expect(File(join(folder.path, name!)).readAsStringSync(), 'real bytes');
      expect(await external.read(name), equals(bytesOf('real bytes')));
    });

    test('createFromFile skips the upload when asked', () async {
      final name = await storage.createFromFile(
          null, sourceFile('a'), AttachmentType.audio,
          currTime: captureTime, skipExternalUpload: true);
      await pumpEventQueue();

      expect(await (await externalOf(AttachmentType.audio)).list(), isEmpty);
      expect(
          await (await internalOf(AttachmentType.audio)).exists(name!), isTrue);
    });

    test('sizeBytes reads the local copy, then the external one', () async {
      await (await internalOf(AttachmentType.video))
          .write('local.mp4', bytesOf('12345'));
      await (await externalOf(AttachmentType.video))
          .write('remote.mp4', bytesOf('123'));

      expect(await storage.sizeBytes('local.mp4', AttachmentType.video), 5);
      expect(await storage.sizeBytes('remote.mp4', AttachmentType.video), 3);
      expect(await storage.sizeBytes('gone.mp4', AttachmentType.video), isNull);
    });

    test('delete removes the file from both folders of its type only',
        () async {
      for (final type in [AttachmentType.audio, AttachmentType.video]) {
        await (await internalOf(type)).write('same.bin', bytesOf('a'));
        await (await externalOf(type)).write('same.bin', bytesOf('a'));
      }

      await storage.delete('same.bin', AttachmentType.audio);
      await pumpEventQueue();

      expect(await (await internalOf(AttachmentType.audio)).list(), isEmpty);
      expect(await (await externalOf(AttachmentType.audio)).list(), isEmpty);
      expect((await internalOf(AttachmentType.video)).list(),
          completion(['same.bin']));
      expect((await externalOf(AttachmentType.video)).list(),
          completion(['same.bin']));
    });

    test('delete reports a failure instead of throwing', () async {
      final stuck = StuckStore();
      useStores(stuck, InMemoryFileStore());

      expect(await storage.delete('a.jpg', AttachmentType.image), isFalse);
    });

    group('reconcile', () {
      test('uploads and downloads audio and video through their own folders',
          () async {
        useAttachments([
          (AttachmentType.audio, 'voice.m4a'),
          (AttachmentType.video, 'clip.mp4'),
        ]);
        await (await internalOf(AttachmentType.audio))
            .write('voice.m4a', bytesOf('voice'));
        await (await externalOf(AttachmentType.video))
            .write('clip.mp4', bytesOf('clip'));

        final summary = await storage.reconcileAttachmentFolders();

        expect(summary.uploaded, 1);
        expect(summary.downloaded, 1);
        expect(await (await externalOf(AttachmentType.audio)).read('voice.m4a'),
            equals(bytesOf('voice')));
        expect(await (await internalOf(AttachmentType.video)).read('clip.mp4'),
            equals(bytesOf('clip')));
        expect(await internalStore.list(), isEmpty);
      });

      test('only reconciles the requested types', () async {
        useAttachments([
          (AttachmentType.audio, 'voice.m4a'),
          (AttachmentType.video, 'clip.mp4'),
        ]);
        await (await internalOf(AttachmentType.audio))
            .write('voice.m4a', bytesOf('voice'));
        await (await internalOf(AttachmentType.video))
            .write('clip.mp4', bytesOf('clip'));

        await storage.reconcileAttachmentFolders(types: [AttachmentType.video]);

        expect(await (await externalOf(AttachmentType.video)).list(),
            ['clip.mp4']);
        expect(await (await externalOf(AttachmentType.audio)).list(), isEmpty);
      });

      test('reports each type as a stage with its counts', () async {
        useAttachments([
          (AttachmentType.video, 'clip.mp4'),
          (AttachmentType.audio, 'voice.m4a'),
          (AttachmentType.audio, 'note.m4a'),
        ]);
        for (final (type, name) in [
          (AttachmentType.video, 'clip.mp4'),
          (AttachmentType.audio, 'voice.m4a'),
          (AttachmentType.audio, 'note.m4a'),
        ]) {
          await (await internalOf(type)).write(name, bytesOf(name));
        }
        final reported = <String>[];

        await storage.reconcileAttachmentFolders(
            types: [AttachmentType.video, AttachmentType.audio],
            onProgress: (progress) =>
                reported.add('${progress.item.name} ${progress.counts}'));

        expect(reported, [
          'video null',
          'video 0/1',
          'video 1/1',
          'audio null',
          'audio 0/2',
          'audio 1/2',
          'audio 2/2',
        ]);
      });

      test('a name referenced as audio does not cover the same video name',
          () async {
        useAttachments([(AttachmentType.audio, 'same.bin')]);
        await (await internalOf(AttachmentType.video))
            .write('same.bin', bytesOf('video'));

        await storage.garbageCollectAttachments();

        expect(await (await internalOf(AttachmentType.video)).list(), isEmpty);
      });
    });

    test('garbage collection keeps referenced files of every type', () async {
      useAttachments([
        (AttachmentType.image, 'kept.jpg'),
        (AttachmentType.audio, 'kept.m4a'),
        (AttachmentType.video, 'kept.mp4'),
      ]);
      for (final (type, name) in [
        (AttachmentType.image, 'kept.jpg'),
        (AttachmentType.image, 'orphan.jpg'),
        (AttachmentType.audio, 'kept.m4a'),
        (AttachmentType.audio, 'orphan.m4a'),
        (AttachmentType.video, 'kept.mp4'),
        (AttachmentType.video, 'orphan.mp4'),
      ]) {
        await (await internalOf(type)).write(name, bytesOf(name));
      }

      await storage.garbageCollectAttachments();

      expect(await (await internalOf(AttachmentType.image)).list(),
          equals(['kept.jpg']));
      expect(await (await internalOf(AttachmentType.audio)).list(),
          equals(['kept.m4a']));
      expect(await (await internalOf(AttachmentType.video)).list(),
          equals(['kept.mp4']));
    });
  });

  group('reconcile', () {
    late FakeImageFolder folder;
    final captureTime = DateTime(2026, 1, 2, 3, 4, 5);
    const capturedName = 'daily_you_2026-01-02T03-04-05.jpg';

    Future<AttachmentSyncSummary> reconcile() async =>
        storage.reconcileAttachmentFolders();

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

    void expectNothingDone(AttachmentSyncSummary summary) {
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

        await storage.syncAttachmentFolders(false);

        for (final name in names) {
          expect(await folder.read(name), equals(bytesOf(name)));
        }
        expect(storage.externalSyncHealth.isStale, isFalse);
      });

      test('downloads images this device is missing', () async {
        useFolder(FakeImageFolder(), ['a.jpg']);
        await folder.write('a.jpg', bytesOf('a'));

        await storage.syncAttachmentFolders(false);

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

    group('with one copy missing and a folder on disk', () {
      late Directory disk;

      setUp(() async {
        disk = await Directory.systemTemp.createTemp('reconcile_disk');
        addTearDown(() => disk.delete(recursive: true));
        useFolder(FakeImageFolder(), ['a.jpg']);
        storage.overrideStores(LocalFileStore(disk.path), folder);
      });

      List<String> onDisk() =>
          disk.listSync().map((entity) => basename(entity.path)).toList();

      test('downloads through a staged file beside the folder', () async {
        await folder.write('a.jpg', bytesOf('a'));

        expect((await reconcile()).downloaded, 1);

        expect(File(join(disk.path, 'a.jpg')).readAsStringSync(), 'a');
        expect(onDisk(), equals(['a.jpg']));
      });

      test('refuses a copy shorter than the listed size and keeps nothing',
          () async {
        await folder.write('a.jpg', bytesOf('photo'));
        folder.shortReads.add('a.jpg');

        final summary = await reconcile();

        expect(summary.failures, 1);
        expect(summary.downloaded, 0);
        expect(onDisk(), isEmpty);
      });

      test('never copies an empty Image Folder file in', () async {
        await folder.write('a.jpg', Uint8List(0));

        final summary = await reconcile();

        expect(summary.unavailable, 1);
        expect(summary.downloaded, 0);
        expect(onDisk(), isEmpty);
      });

      test('counts an unreadable Image Folder file as a failure', () async {
        await folder.write('a.jpg', bytesOf('a'));
        folder.unreadableNames.add('a.jpg');

        final summary = await reconcile();

        expect(summary.failures, 1);
        expect(onDisk(), isEmpty);
      });
    });

    group('with both copies', () {
      test('does nothing when both copies have the same size', () async {
        useFolder(FakeImageFolder(), ['a.jpg']);
        await writeBoth('a.jpg', 'a', 'b');
        folder.writes.clear();

        expectNothingDone(await reconcile());
        expect(folder.writes, isEmpty);
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
      await expectLater(storage.syncAttachmentFolders(false), throwsException);
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

      await storage.syncAttachmentFolders(false);

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

      await storage.create(null, bytesOf('photo'), AttachmentType.image,
          currTime: captureTime);
      await pumpEventQueue();
      expect(await folder.read(capturedName), equals(bytesOf('photo')));

      slowUpload.complete();
      expect((await run).uploaded, 1);
    });

    test('a capture and a run uploading the same image leave one file',
        () async {
      useFolder(FakeImageFolder(uniqueNamesOnCollision: true), ['a.jpg']);
      await internalStore.write('a.jpg', bytesOf('a'));
      final capture = folder.holdUploadOf(capturedName);
      folder.hiddenFromListing.add(capturedName);
      await storage.create(null, bytesOf('photo'), AttachmentType.image,
          currTime: captureTime);
      useImages(['a.jpg', capturedName]);
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
      useFolder(FakeImageFolder(), []);
      await storage.create(null, bytesOf('photo'), AttachmentType.image,
          currTime: captureTime, skipExternalUpload: true);
      useImages([capturedName]);
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

    expect(EntryAttachmentsProvider.instance.isLoaded, isFalse);
    await expectLater(storage.garbageCollectAttachments(), throwsStateError);
    expect(await internalStore.exists('photo.jpg'), isTrue);
  });

  test('deletes only unreferenced images', () async {
    useStores(internalStore, InMemoryFileStore());
    useImages(['kept.jpg']);
    await internalStore.write('kept.jpg', bytesOf('kept'));
    await internalStore.write('orphan.jpg', bytesOf('orphan'));

    expect(await storage.garbageCollectAttachments(), isTrue);

    expect(await internalStore.list(), equals(['kept.jpg']));
  });

  test('garbage collection leaves the external folder alone', () async {
    final externalStore = InMemoryFileStore();
    useStores(internalStore, externalStore);
    useImages(['kept.jpg']);
    await internalStore.write('orphan.jpg', bytesOf('orphan'));
    await externalStore.write('orphan.jpg', bytesOf('orphan'));
    await externalStore.write('unknown.jpg', bytesOf('unknown'));

    await storage.garbageCollectAttachments();

    expect(await internalStore.exists('orphan.jpg'), isFalse);
    expect(await externalStore.list(),
        unorderedEquals(['orphan.jpg', 'unknown.jpg']));
  });

  test('garbage collection leaves a download in progress alone', () async {
    useStores(internalStore, InMemoryFileStore());
    useImages(['kept.jpg']);
    await internalStore.write(
        'kept.jpg.1760000000000000.partial', bytesOf('half'));
    await internalStore.write('orphan.jpg', bytesOf('orphan'));

    await storage.garbageCollectAttachments();

    expect(await internalStore.list(),
        equals(['kept.jpg.1760000000000000.partial']));
  });

  group('deleteOrphanedAttachments', () {
    final inTwoDays = DateTime.now().add(const Duration(days: 2));
    late InMemoryFileStore externalStore;

    Future<FileStore> internalOf(AttachmentType type) =>
        storage.internalStore(type);

    setUp(() {
      externalStore = InMemoryFileStore();
      useStores(internalStore, externalStore);
    });

    test('refuses to run before the attachments load', () async {
      await internalStore.write('photo.jpg', bytesOf('photo'));

      expect(EntryAttachmentsProvider.instance.isLoaded, isFalse);
      await expectLater(
          storage.deleteOrphanedAttachments(now: inTwoDays), throwsStateError);
      expect(await internalStore.exists('photo.jpg'), isTrue);
    });

    test('deletes old unreferenced files of every type and keeps the rest',
        () async {
      useAttachments([
        (AttachmentType.image, 'kept.jpg'),
        (AttachmentType.audio, 'kept.m4a'),
        (AttachmentType.video, 'kept.mp4'),
      ]);
      for (final (type, name) in [
        (AttachmentType.image, 'kept.jpg'),
        (AttachmentType.image, 'orphan.jpg'),
        (AttachmentType.audio, 'kept.m4a'),
        (AttachmentType.audio, 'orphan.m4a'),
        (AttachmentType.video, 'kept.mp4'),
        (AttachmentType.video, 'orphan.mp4'),
      ]) {
        await (await internalOf(type)).write(name, bytesOf(name));
      }

      expect(await storage.deleteOrphanedAttachments(now: inTwoDays), 3);

      expect(
          await (await internalOf(AttachmentType.image)).list(), ['kept.jpg']);
      expect(
          await (await internalOf(AttachmentType.audio)).list(), ['kept.m4a']);
      expect(
          await (await internalOf(AttachmentType.video)).list(), ['kept.mp4']);
    });

    test('keeps every file while no attachment is referenced', () async {
      useAttachments([]);
      await internalStore.write('photo.jpg', bytesOf('photo'));

      expect(await storage.deleteOrphanedAttachments(now: inTwoDays), 0);

      expect(await internalStore.exists('photo.jpg'), isTrue);
    });

    test('keeps every file when the database was replaced this session',
        () async {
      useAttachments([(AttachmentType.image, 'kept.jpg')]);
      await internalStore.write('orphan.jpg', bytesOf('orphan'));
      AppDatabase.instance.databaseReplacedThisSession = true;
      addTearDown(
          () => AppDatabase.instance.databaseReplacedThisSession = false);

      expect(await storage.deleteOrphanedAttachments(now: inTwoDays), 0);

      expect(await internalStore.exists('orphan.jpg'), isTrue);
    });

    test('keeps unreferenced files younger than the minimum age', () async {
      useAttachments([]);
      await internalStore.write('new.jpg', bytesOf('new'));

      expect(await storage.deleteOrphanedAttachments(), 0);

      expect(await internalStore.exists('new.jpg'), isTrue);
    });

    test('a name referenced as audio does not cover the same video name',
        () async {
      useAttachments([(AttachmentType.audio, 'same.bin')]);
      await (await internalOf(AttachmentType.video))
          .write('same.bin', bytesOf('video'));

      await storage.deleteOrphanedAttachments(now: inTwoDays);

      expect(await (await internalOf(AttachmentType.video)).list(), isEmpty);
    });

    test('leaves the external copy of a deleted orphan alone', () async {
      useAttachments([(AttachmentType.image, 'kept.jpg')]);
      await internalStore.write('orphan.jpg', bytesOf('orphan'));
      await externalStore.write('orphan.jpg', bytesOf('orphan'));

      await storage.deleteOrphanedAttachments(now: inTwoDays);
      await pumpEventQueue();

      expect(await internalStore.exists('orphan.jpg'), isFalse);
      expect(await externalStore.exists('orphan.jpg'), isTrue);
    });
  });
}
