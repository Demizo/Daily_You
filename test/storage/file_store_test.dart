import 'dart:io';
import 'dart:typed_data';

import 'package:daily_you/storage/file_store.dart';
import 'package:daily_you/storage/in_memory_file_store.dart';
import 'package:daily_you/storage/local_file_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' show join;

void main() {
  group('InMemoryFileStore', () {
    late InMemoryFileStore store;

    setUp(() => store = InMemoryFileStore());

    fileStoreContract(() => store,
        breakWritesOf: (_) async => store.writesStopAfter = 0);

    test('an interrupted createNew leaves the final name cut off', () async {
      store.writesStopAfter = 2;

      expect(
          await orOnFailure(store.createNew('photo.jpg', bytesOf('photo')),
              CreateResult.failed),
          CreateResult.failed);
      expect(await store.read('photo.jpg'), equals(bytesOf('ph')));
    });
  });

  group('InMemoryFileStore with provider naming', () {
    late InMemoryFileStore store;

    setUp(() => store = InMemoryFileStore(uniqueNamesOnCollision: true));

    fileStoreContract(() => store,
        breakWritesOf: (_) async => store.writesStopAfter = 0);
  });

  group('LocalFileStore', () {
    late Directory directory;
    late FileStore store;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('file_store_test');
      store = LocalFileStore(directory.path);
    });

    tearDown(() => directory.delete(recursive: true));

    fileStoreContract(() => store,
        breakWritesOf: (name) =>
            Directory(join(directory.path, name)).create());

    test('is unavailable when the directory is missing', () async {
      expect(await LocalFileStore(join(directory.path, 'gone')).isAvailable(),
          isFalse);
    });

    test('listFiles throws when the directory is missing', () async {
      await expectLater(
          LocalFileStore(join(directory.path, 'gone')).listFiles(),
          throwsA(isA<FileSystemException>()));
    });

    test('write recreates a directory that disappeared', () async {
      await store.write('note.txt', bytesOf('hello'));
      await directory.delete(recursive: true);

      expect(await store.write('note.txt', bytesOf('again')), isTrue);
      expect(await store.read('note.txt'), equals(bytesOf('again')));
    });
  });
}

Uint8List bytesOf(String text) => Uint8List.fromList(text.codeUnits);

/// A write that [breakWritesOf] broke may throw or report failure.
Future<T> orOnFailure<T>(Future<T> operation, T failure) =>
    operation.catchError((Object _) => failure);

void fileStoreContract(FileStore Function() storeOf,
    {required Future<void> Function(String name) breakWritesOf}) {
  test('is available', () async {
    expect(await storeOf().isAvailable(), isTrue);
  });

  test('write then read round-trips bytes', () async {
    final store = storeOf();
    await store.write('note.txt', bytesOf('hello'));

    expect(await store.read('note.txt'), equals(bytesOf('hello')));
  });

  test('write replaces the bytes of an existing name', () async {
    final store = storeOf();
    await store.write('note.txt', bytesOf('first'));
    await store.write('note.txt', bytesOf('second'));

    expect(await store.read('note.txt'), equals(bytesOf('second')));
  });

  test('read of a missing name returns null', () async {
    expect(await storeOf().read('missing.txt'), isNull);
  });

  test('exists follows writes and deletes', () async {
    final store = storeOf();
    expect(await store.exists('note.txt'), isFalse);

    await store.write('note.txt', bytesOf('hello'));
    expect(await store.exists('note.txt'), isTrue);

    await store.delete('note.txt');
    expect(await store.exists('note.txt'), isFalse);
  });

  test('list names every written file', () async {
    final store = storeOf();
    await store.write('one.txt', bytesOf('1'));
    await store.write('two.txt', bytesOf('2'));

    expect(await store.list(), unorderedEquals(['one.txt', 'two.txt']));
  });

  test('listFiles reports every file with its size', () async {
    final store = storeOf();
    await store.write('one.txt', bytesOf('1'));
    await store.write('two.txt', bytesOf('22'));

    final files = await store.listFiles();

    expect({for (final file in files) file.name: file.size},
        equals({'one.txt': 1, 'two.txt': 2}));
  });

  test('listFiles of an empty store is empty', () async {
    expect(await storeOf().listFiles(), isEmpty);
  });

  test('createNew writes the file under its final name', () async {
    final store = storeOf();

    expect(await store.createNew('photo.jpg', bytesOf('photo')),
        CreateResult.created);

    expect(await store.read('photo.jpg'), equals(bytesOf('photo')));
    expect(await store.list(), equals(['photo.jpg']));
  });

  test('createNew never replaces an existing file', () async {
    final store = storeOf();
    await store.write('photo.jpg', bytesOf('original'));

    expect(await store.createNew('photo.jpg', bytesOf('other')),
        CreateResult.alreadyExists);

    expect(await store.read('photo.jpg'), equals(bytesOf('original')));
    expect(await store.list(), equals(['photo.jpg']));
  });

  test('a failed createNew reports failure', () async {
    final store = storeOf();
    await breakWritesOf('photo.jpg');

    expect(
        await orOnFailure(store.createNew('photo.jpg', bytesOf('photo')),
            CreateResult.failed),
        CreateResult.failed);
  });

  test('rename moves the bytes to the new name', () async {
    final store = storeOf();
    await store.write('old.txt', bytesOf('hello'));

    expect(await store.rename('old.txt', 'new.txt'), isTrue);
    expect(await store.exists('old.txt'), isFalse);
    expect(await store.read('new.txt'), equals(bytesOf('hello')));
  });

  test('rename of a missing name fails', () async {
    expect(await storeOf().rename('missing.txt', 'new.txt'), isFalse);
  });

  test('delete of a missing name succeeds', () async {
    expect(await storeOf().delete('missing.txt'), isTrue);
  });

  test('modifiedTime is only known for written files', () async {
    final store = storeOf();
    expect(await store.modifiedTime('note.txt'), isNull);

    await store.write('note.txt', bytesOf('hello'));
    expect(await store.modifiedTime('note.txt'), isNotNull);
  });
}
