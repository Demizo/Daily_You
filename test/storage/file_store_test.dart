import 'dart:io';
import 'dart:typed_data';

import 'package:daily_you/storage/file_store.dart';
import 'package:daily_you/storage/in_memory_file_store.dart';
import 'package:daily_you/storage/local_file_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' show join;

void main() {
  group('InMemoryFileStore', () {
    late FileStore store;

    setUp(() => store = InMemoryFileStore());

    fileStoreContract(() => store);
  });

  group('LocalFileStore', () {
    late Directory directory;
    late FileStore store;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('file_store_test');
      store = LocalFileStore(directory.path);
    });

    tearDown(() => directory.delete(recursive: true));

    fileStoreContract(() => store);

    test('is unavailable when the directory is missing', () async {
      expect(await LocalFileStore(join(directory.path, 'gone')).isAvailable(),
          isFalse);
    });
  });
}

Uint8List bytesOf(String text) => Uint8List.fromList(text.codeUnits);

void fileStoreContract(FileStore Function() storeOf) {
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
