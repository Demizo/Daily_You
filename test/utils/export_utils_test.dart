import 'dart:convert';
import 'dart:typed_data';

import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/storage/in_memory_file_store.dart';
import 'package:daily_you/utils/export_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  late InMemoryFileStore noteStore;
  late InMemoryFileStore imageStore;
  late MarkdownExportWriter writer;

  setUpAll(() => initializeDateFormatting('en'));

  setUp(() {
    noteStore = InMemoryFileStore();
    imageStore = InMemoryFileStore();
    writer = MarkdownExportWriter(
        noteStore: noteStore, imageStore: imageStore, locale: 'en');
  });

  Entry entryOn(DateTime timeCreate, {String text = ''}) =>
      Entry(text: text, timeCreate: timeCreate, timeModified: timeCreate);

  Future<String> noteNamed(String name) async =>
      utf8.decode((await noteStore.read(name))!);

  test('names a note after the day it was written', () async {
    await writer.write(entryOn(DateTime(2026, 3, 4), text: 'a good day'), []);

    expect(await noteStore.list(), equals(['log_2026-03-04.md']));
    expect(await noteNamed('log_2026-03-04.md'),
        equals('Wed, Mar 4, 2026\na good day\n'));
  });

  test('numbers later notes that share a day', () async {
    await writer.write(entryOn(DateTime(2026, 3, 4, 8)), []);
    await writer.write(entryOn(DateTime(2026, 3, 4, 20)), []);
    await writer.write(entryOn(DateTime(2026, 3, 5)), []);

    expect(
        await noteStore.list(),
        unorderedEquals(
            ['log_2026-03-04.md', 'log_2026-03-04_2.md', 'log_2026-03-05.md']));
  });

  test('writes images beside the note and links them by rank', () async {
    final timeCreate = DateTime(2026, 3, 4);
    await writer.write(entryOn(timeCreate, text: 'body'), [
      (
        EntryImage(
            entryId: 1,
            imgPath: 'daily_you_a.png',
            imgRank: 1,
            timeCreate: timeCreate),
        Uint8List.fromList([1, 2])
      ),
      (
        EntryImage(
            entryId: 1,
            imgPath: 'daily_you_b.jpg',
            imgRank: 0,
            timeCreate: timeCreate),
        Uint8List.fromList([3, 4])
      ),
    ]);

    expect(await imageStore.list(),
        equals(['image_2026-03-04_1.png', 'image_2026-03-04_0.jpg']));
    expect(await imageStore.read('image_2026-03-04_1.png'),
        equals(Uint8List.fromList([1, 2])));
    expect(
        await noteNamed('log_2026-03-04.md'),
        startsWith('![](Images/image_2026-03-04_1.png)\n'
            '![](Images/image_2026-03-04_0.jpg)\n'));
  });

  test('carries the note suffix into its image names', () async {
    final timeCreate = DateTime(2026, 3, 4);
    final image = EntryImage(
        entryId: 1,
        imgPath: 'daily_you_a.png',
        imgRank: 0,
        timeCreate: timeCreate);
    final bytes = Uint8List.fromList([1]);

    await writer.write(entryOn(timeCreate), [(image, bytes)]);
    await writer.write(entryOn(timeCreate), [(image, bytes)]);

    expect(await imageStore.list(),
        equals(['image_2026-03-04_0.png', 'image_2026-03-04_2_0.png']));
  });
}
