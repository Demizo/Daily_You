import 'dart:typed_data';

import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/database/entry_store.dart';
import 'package:daily_you/database/image_storage.dart';
import 'package:daily_you/database/tag_dao.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/storage/in_memory_file_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  final store = EntryStore.instance;
  final time = DateTime(2025, 6, 2, 9, 30);

  late Database database;
  late InMemoryFileStore imageFiles;

  Entry draftEntry({int? id, String text = 'draft', int? mood}) => Entry(
      id: id, text: text, mood: mood, timeCreate: time, timeModified: time);

  Future<void> reloadEverything() async {
    await store.load();
    await TagsProvider.instance.load();
    await EntryImagesProvider.instance.load();
  }

  Future<Tag> addTag(String name) => TagDao.add(Tag(
      name: name,
      tagType: TagType.label,
      timeCreate: time,
      timeModified: time));

  Future<EntryImage> writeImageFile(String name) async {
    await imageFiles.write(name, Uint8List.fromList(name.codeUnits));
    return EntryImage(
        entryId: null, imgPath: name, imgRank: 0, timeCreate: time);
  }

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    databaseFactory = databaseFactoryFfi;
    database = await databaseFactory.openDatabase(inMemoryDatabasePath);
    AppDatabase.instance.database = database;
    await AppDatabase.instance.createSchema(database);

    imageFiles = InMemoryFileStore();
    ImageStorage.instance.overrideStores(imageFiles, InMemoryFileStore());

    await reloadEverything();
  });

  tearDown(() async {
    ImageStorage.instance.clearStoreOverrides();
    AppDatabase.instance.database = null;
    await database.close();
  });

  test('persists an entry with its tags and images together', () async {
    final tag = await addTag('walk');
    await TagsProvider.instance.load();
    final image = await writeImageFile('photo.jpg');

    final saved = await store.save((_) => EntryDraft(
          entry: draftEntry(text: 'a good day', mood: 1),
          tags: [
            EntryTag(entryId: 0, tagId: tag.id!, value: '2', timeCreate: time)
          ],
          images: [image],
        ));

    await reloadEverything();

    expect(store.entries.single.id, saved.id);
    expect(store.entries.single.text, 'a good day');
    expect(store.entries.single.mood, 1);

    final entryTags = TagsProvider.instance.getEntryTagsForEntry(saved.id!);
    expect(entryTags.single.tagId, tag.id);
    expect(entryTags.single.value, '2');

    final entryImages =
        EntryImagesProvider.instance.getForEntry(store.entries.single);
    expect(entryImages.single.imgPath, 'photo.jpg');
  });

  test('reconciles tags and images on a later save', () async {
    final kept = await addTag('walk');
    final dropped = await addTag('run');
    await TagsProvider.instance.load();
    final keptImage = await writeImageFile('kept.jpg');
    final droppedImage = await writeImageFile('dropped.jpg');

    final saved = await store.save((_) => EntryDraft(
          entry: draftEntry(),
          tags: [
            EntryTag(entryId: 0, tagId: kept.id!, timeCreate: time),
            EntryTag(entryId: 0, tagId: dropped.id!, timeCreate: time),
          ],
          images: [keptImage, droppedImage],
        ));

    final survivingImage = EntryImagesProvider.instance
        .getForEntry(store.entries.single)
        .firstWhere((image) => image.imgPath == 'kept.jpg');

    await store.save((_) => EntryDraft(
          entry: saved.copy(text: 'trimmed'),
          tags: [
            EntryTag(
                entryId: saved.id!,
                tagId: kept.id!,
                value: '4',
                timeCreate: time)
          ],
          images: [survivingImage],
        ));

    await reloadEverything();

    final entryTags = TagsProvider.instance.getEntryTagsForEntry(saved.id!);
    expect(entryTags.single.tagId, kept.id);
    expect(entryTags.single.value, '4');

    final entryImages =
        EntryImagesProvider.instance.getForEntry(store.entries.single);
    expect(entryImages.single.imgPath, 'kept.jpg');
    expect(await imageFiles.exists('dropped.jpg'), isFalse);
    expect(await imageFiles.exists('kept.jpg'), isTrue);
  });

  test('leaves no entry behind when the tag write fails', () async {
    final tag = await addTag('walk');
    await TagsProvider.instance.load();
    await database.execute('DROP TABLE $entryTagsTable');

    await expectLater(
      store.save((_) => EntryDraft(
            entry: draftEntry(),
            tags: [EntryTag(entryId: 0, tagId: tag.id!, timeCreate: time)],
          )),
      throwsA(isA<DatabaseException>()),
    );

    expect(await database.query(entriesTable), isEmpty);
  });

  test('replays a save requested while another is in flight', () async {
    var entry = draftEntry(text: 'draft');
    var text = 'first edit';
    int? mood;
    var editAgain = true;
    late Future<Entry> secondSave;

    EntryDraft buildDraft(Entry? saved) {
      if (saved != null) entry = saved;
      final draft = EntryDraft(
          entry: entry.copy(text: text, mood: mood, timeModified: time));
      if (editAgain) {
        editAgain = false;
        text = 'second edit';
        mood = 2;
        secondSave = store.save(buildDraft);
      }
      return draft;
    }

    expect((await store.save(buildDraft)).text, 'first edit');
    await secondSave;

    await reloadEverything();

    expect(store.entries, hasLength(1));
    expect(store.entries.single.text, 'second edit');
    expect(store.entries.single.mood, 2);
  });

  test('gives each concurrent saver its own queue slot', () async {
    var firstEntry = draftEntry(text: 'first');
    var secondEntry = draftEntry(text: 'second');
    var queueOthers = true;
    late Future<Entry> firstReplay;
    late Future<Entry> secondSave;

    EntryDraft buildSecond(Entry? saved) {
      if (saved != null) secondEntry = saved;
      return EntryDraft(entry: secondEntry.copy(text: 'second'));
    }

    EntryDraft buildFirst(Entry? saved) {
      if (saved != null) firstEntry = saved;
      if (queueOthers) {
        queueOthers = false;
        firstReplay = store.save(buildFirst);
        secondSave = store.save(buildSecond);
      }
      return EntryDraft(entry: firstEntry.copy(text: 'first'));
    }

    final first = await store.save(buildFirst);
    final replayed = await firstReplay;
    final second = await secondSave;

    expect(replayed.id, first.id);
    expect(replayed.text, 'first');
    expect(second.id, isNot(first.id));
    expect(second.text, 'second');

    await reloadEverything();

    expect(store.entries.map((entry) => entry.text),
        containsAll(['first', 'second']));
  });

  test('removes an entry with its tags, image rows, and image files', () async {
    final tag = await addTag('walk');
    await TagsProvider.instance.load();
    final image = await writeImageFile('photo.jpg');

    final saved = await store.save((_) => EntryDraft(
          entry: draftEntry(),
          tags: [EntryTag(entryId: 0, tagId: tag.id!, timeCreate: time)],
          images: [image],
        ));

    await store.delete(saved);
    await reloadEverything();

    expect(store.entries, isEmpty);
    expect(TagsProvider.instance.entryTags, isEmpty);
    expect(EntryImagesProvider.instance.images, isEmpty);
    expect(await imageFiles.exists('photo.jpg'), isFalse);
  });
}
