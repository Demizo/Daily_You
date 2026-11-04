// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';
import 'dart:typed_data';

import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/database/attachment_storage.dart';
import 'package:daily_you/database/entry_attachment_dao.dart';
import 'package:daily_you/database/entry_tag_dao.dart';
import 'package:daily_you/database/tag_category_dao.dart';
import 'package:daily_you/database/tag_dao.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/models/tag_category.dart';
import 'package:daily_you/models/tag_icon_type.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/storage/external_sync_settings.dart';
import 'package:daily_you/storage/in_memory_file_store.dart';
import 'package:daily_you/utils/imports/import_bundle.dart';
import 'package:daily_you/utils/imports/import_writer.dart';
import 'package:daily_you/utils/operation_outcome.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' show join;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../support/config_provider_harness.dart';

void main() {
  useTemporaryConfig();

  final time = DateTime(2025, 6, 2, 9, 30);

  late Database database;
  late InMemoryFileStore imageFiles;
  late InMemoryFileStore externalImageFiles;
  late Directory work;
  late List<String> statuses;

  ImportedEntry entryAt(
    DateTime timeCreate, {
    String text = 'text',
    int? mood,
    List<ImportedEntryTag> tags = const [],
    List<ImportedAttachment> attachments = const [],
  }) =>
      ImportedEntry(
        Entry(
            text: text,
            mood: mood,
            timeCreate: timeCreate,
            timeModified: timeCreate),
        tags: tags,
        attachments: attachments,
      );

  ImportedAttachment imageOf(ImportedMedia media,
          {int rank = 0, DateTime? timeCreate}) =>
      ImportedAttachment(
        type: AttachmentType.image,
        rank: rank,
        timeCreate: timeCreate ?? time,
        media: media,
      );

  ImportedEntryTag label(String name) =>
      ImportedEntryTag(name: name, tagType: TagType.label);

  Future<OperationOutcome> write(ImportBundle bundle) =>
      ImportWriter().write(bundle, statuses.add);

  Future<Tag> addTag(String name,
      {TagType tagType = TagType.label,
      int? categoryId,
      int sortOrder = 0,
      int? color}) {
    return TagDao.add(Tag(
        name: name,
        tagType: tagType,
        categoryId: categoryId,
        sortOrder: sortOrder,
        color: color,
        timeCreate: time,
        timeModified: time));
  }

  Future<TagCategory> addCategory(String name, {int sortOrder = 0}) =>
      TagCategoryDao.add(TagCategory(
          name: name,
          sortOrder: sortOrder,
          timeCreate: time,
          timeModified: time));

  Tag storedTag(String name, [TagType tagType = TagType.label]) =>
      TagsProvider.instance.tags
          .singleWhere((tag) => tag.name == name && tag.tagType == tagType);

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    databaseFactory = databaseFactoryFfi;
    database = await databaseFactory.openDatabase(inMemoryDatabasePath);
    AppDatabase.instance.database = database;
    await AppDatabase.instance.createSchema(database);

    imageFiles = InMemoryFileStore();
    externalImageFiles = InMemoryFileStore();
    AttachmentStorage.instance.overrideStores(imageFiles, externalImageFiles);

    work = await Directory.systemTemp.createTemp('import_writer');
    statuses = [];
  });

  tearDown(() async {
    AttachmentStorage.instance.clearStoreOverrides();
    AppDatabase.instance.database = null;
    await database.close();
    await work.delete(recursive: true);
  });

  test('writes entries with their tags, categories and attachments', () async {
    final photo = File(join(work.path, 'clip.png'))
      ..writeAsBytesSync([7, 8, 9]);
    final entryTime = DateTime(2025, 6, 3, 21, 15);

    final outcome = await write(ImportBundle(
      categories: const [
        ImportedCategory(
            name: 'Activities',
            color: 0xFF112233,
            icon: 'run',
            iconType: TagIconType.materialIcon),
      ],
      tagDefinitions: [
        ImportedTagDefinition(
            name: 'Run',
            tagType: TagType.label,
            categoryName: 'Activities',
            color: 0xFF445566,
            icon: 'directions_run',
            iconType: TagIconType.materialIcon,
            timeCreate: DateTime(2024, 1, 2)),
        const ImportedTagDefinition(name: 'Water', tagType: TagType.tracker),
      ],
      entries: [
        ImportedEntry(
          Entry(
              text: '# Title\n\nBody',
              mood: 4,
              timeCreate: entryTime,
              timeModified: DateTime(2025, 6, 4)),
          tags: const [
            ImportedEntryTag(name: 'Run', tagType: TagType.label),
            ImportedEntryTag(
                name: 'Water', tagType: TagType.tracker, value: '2.5'),
          ],
          attachments: [
            imageOf(BytesMedia(Uint8List.fromList([1, 2, 3])),
                rank: 1, timeCreate: entryTime),
            imageOf(FileMedia(photo), rank: 0, timeCreate: entryTime),
            imageOf(const ReferenceMedia('old.jpg'),
                rank: 2, timeCreate: entryTime),
          ],
        ),
      ],
    ));

    expect(outcome.succeeded, isTrue);

    final entry = EntriesProvider.instance.entries.single;
    expect(entry.text, '# Title\n\nBody');
    expect(entry.mood, 4);
    expect(entry.timeCreate, entryTime);
    expect(entry.timeModified, DateTime(2025, 6, 4));

    final category = TagsProvider.instance.categories.single;
    expect(category.name, 'Activities');
    expect(category.color, 0xFF112233);
    expect(category.icon, 'run');
    expect(category.iconType, TagIconType.materialIcon);

    final run = storedTag('Run');
    expect(run.categoryId, category.id);
    expect(run.color, 0xFF445566);
    expect(run.icon, 'directions_run');
    expect(run.iconType, TagIconType.materialIcon);
    expect(run.timeCreate, DateTime(2024, 1, 2));
    expect(run.timeModified, DateTime(2024, 1, 2));
    final water = storedTag('Water', TagType.tracker);
    expect(water.categoryId, isNull);

    final entryTags = TagsProvider.instance.getEntryTagsForEntry(entry.id!);
    expect(entryTags.map((entryTag) => entryTag.tagId),
        unorderedEquals([run.id, water.id]));
    expect(
        entryTags.singleWhere((entryTag) => entryTag.tagId == water.id).value,
        '2.5');
    expect(entryTags.every((entryTag) => entryTag.timeCreate == entryTime),
        isTrue);

    final attachments = [...EntryAttachmentsProvider.instance.attachments]
      ..sort((a, b) => a.rank.compareTo(b.rank));
    expect(attachments.map((attachment) => attachment.entryId),
        everyElement(entry.id));
    expect(attachments.map((attachment) => attachment.type),
        everyElement(AttachmentType.image));
    expect(attachments.map((attachment) => attachment.timeCreate),
        everyElement(entryTime));
    expect(await imageFiles.read(attachments[0].filePath), [7, 8, 9]);
    expect(attachments[0].filePath, endsWith('.png'));
    expect(await imageFiles.read(attachments[1].filePath), [1, 2, 3]);
    expect(attachments[2].filePath, 'old.jpg');
  });

  test('skips an entry at the same time as an existing entry', () async {
    await EntriesProvider.instance
        .add(Entry(text: 'existing', timeCreate: time, timeModified: time));
    await EntriesProvider.instance.load();

    final outcome = await write(ImportBundle(entries: [
      entryAt(time, text: 'duplicate', tags: [
        label('Skipped')
      ], attachments: [
        imageOf(BytesMedia(Uint8List.fromList([1])))
      ]),
      entryAt(time.add(const Duration(hours: 1)), text: 'new'),
    ]));

    expect(outcome.succeeded, isTrue);
    expect(EntriesProvider.instance.entries.map((entry) => entry.text),
        unorderedEquals(['existing', 'new']));
    expect(await EntryAttachmentDao.getAll(), isEmpty);
    expect(await imageFiles.list(), isEmpty);
    expect(await EntryTagDao.getAll(), isEmpty);
  });

  test('skips a later entry at the same time inside the bundle', () async {
    await write(ImportBundle(entries: [
      entryAt(time, text: 'first'),
      entryAt(time, text: 'second'),
    ]));

    expect(EntriesProvider.instance.entries.map((entry) => entry.text),
        equals(['first']));
  });

  test('writes the same bundle only once', () async {
    final bundle = ImportBundle(entries: [
      entryAt(time, tags: [label('Run')]),
    ]);

    await write(bundle);
    await write(bundle);

    expect(EntriesProvider.instance.entries, hasLength(1));
    expect(TagsProvider.instance.tags, hasLength(1));
    expect(await EntryTagDao.getAll(), hasLength(1));
  });

  test('reuses an existing tag with the same type and name', () async {
    final existing = await addTag('Run', color: 0xFF112233);

    await write(ImportBundle(
      tagDefinitions: const [
        ImportedTagDefinition(
            name: 'run', tagType: TagType.label, color: 0xFF999999),
      ],
      entries: [
        entryAt(time, tags: [label('RUN')]),
      ],
    ));

    final tag = TagsProvider.instance.tags.single;
    expect(tag.id, existing.id);
    expect(tag.color, 0xFF112233);
    expect(await EntryTagDao.getAll(), hasLength(1));
  });

  test('keeps a label and a tracker with the same name separate', () async {
    await addTag('Mood', tagType: TagType.label);

    await write(ImportBundle(entries: [
      entryAt(time, tags: const [
        ImportedEntryTag(name: 'Mood', tagType: TagType.tracker, value: '3'),
      ]),
    ]));

    expect(TagsProvider.instance.tags, hasLength(2));
  });

  test('creates a tag that only appears on an entry', () async {
    await write(ImportBundle(entries: [
      entryAt(time, tags: [label('Unlisted')]),
    ]));

    final tag = storedTag('Unlisted');
    expect(tag.categoryId, isNull);
    expect(tag.color, isNull);
  });

  test('attaches a tag listed twice to an entry once', () async {
    await write(ImportBundle(entries: [
      entryAt(time, tags: [label('Run'), label('run')]),
    ]));

    expect(await EntryTagDao.getAll(), hasLength(1));
  });

  test('reuses an existing category by name', () async {
    final existing = await addCategory('Activities');

    await write(ImportBundle(
      categories: const [ImportedCategory(name: 'activities')],
      tagDefinitions: const [
        ImportedTagDefinition(
            name: 'Run', tagType: TagType.label, categoryName: 'ACTIVITIES'),
      ],
    ));

    expect(TagsProvider.instance.categories.single.id, existing.id);
    expect(storedTag('Run').categoryId, existing.id);
  });

  test('creates the category a tag names when the bundle omits it', () async {
    await write(ImportBundle(tagDefinitions: const [
      ImportedTagDefinition(
          name: 'Run', tagType: TagType.label, categoryName: 'Activities'),
    ]));

    expect(TagsProvider.instance.categories.single.name, 'Activities');
    expect(storedTag('Run').categoryId,
        TagsProvider.instance.categories.single.id);
  });

  test('orders new categories and tags after existing ones', () async {
    final existingCategory = await addCategory('Existing', sortOrder: 3);
    await addTag('old uncategorized', sortOrder: 4);
    await addTag('old categorized',
        categoryId: existingCategory.id, sortOrder: 1);

    await write(ImportBundle(
      categories: const [
        ImportedCategory(name: 'Fresh'),
        ImportedCategory(name: 'Second'),
      ],
      tagDefinitions: const [
        ImportedTagDefinition(name: 'a', tagType: TagType.label),
        ImportedTagDefinition(
            name: 'b', tagType: TagType.label, categoryName: 'Existing'),
        ImportedTagDefinition(
            name: 'c', tagType: TagType.label, categoryName: 'Fresh'),
        ImportedTagDefinition(
            name: 'd', tagType: TagType.label, categoryName: 'Existing'),
        ImportedTagDefinition(
            name: 'e', tagType: TagType.label, categoryName: 'Fresh'),
        ImportedTagDefinition(name: 'f', tagType: TagType.label),
      ],
    ));

    int categoryOrder(String name) => TagsProvider.instance.categories
        .singleWhere((category) => category.name == name)
        .sortOrder;
    expect(categoryOrder('Fresh'), 4);
    expect(categoryOrder('Second'), 5);

    final orderByName = {
      for (final tag in TagsProvider.instance.tags) tag.name: tag.sortOrder
    };
    expect(orderByName['a'], 5);
    expect(orderByName['f'], 6);
    expect(orderByName['b'], 2);
    expect(orderByName['d'], 3);
    expect(orderByName['c'], 0);
    expect(orderByName['e'], 1);
  });

  test('gives attachments with the same time different names', () async {
    await write(ImportBundle(entries: [
      entryAt(time, attachments: [
        imageOf(BytesMedia(Uint8List.fromList([1])), rank: 0),
        imageOf(BytesMedia(Uint8List.fromList([2])), rank: 1),
      ]),
      entryAt(time.add(const Duration(minutes: 1)), attachments: [
        imageOf(BytesMedia(Uint8List.fromList([3])), timeCreate: time),
      ]),
    ]));

    final names = EntryAttachmentsProvider.instance.attachments
        .map((attachment) => attachment.filePath)
        .toList();
    expect(names.toSet(), hasLength(3));
    expect(await imageFiles.list(), unorderedEquals(names));
  });

  test('avoids names already used by earlier attachments', () async {
    final stem =
        'daily_you_${time.toIso8601String().split('.').first.replaceAll(':', '-')}';
    await imageFiles.write('$stem.jpg', Uint8List.fromList([9]));

    await write(ImportBundle(entries: [
      entryAt(time, attachments: [
        imageOf(BytesMedia(Uint8List.fromList([1]))),
      ]),
    ]));

    final attachment = EntryAttachmentsProvider.instance.attachments.single;
    expect(attachment.filePath, '${stem}_1.jpg');
    expect(await imageFiles.read('$stem.jpg'), [9]);
  });

  test('writes a reference without checking that the file exists', () async {
    await write(ImportBundle(entries: [
      entryAt(time, attachments: [
        imageOf(const ReferenceMedia('missing/photo.jpg'), rank: 3),
      ]),
    ]));

    final attachment = EntryAttachmentsProvider.instance.attachments.single;
    expect(attachment.filePath, 'missing/photo.jpg');
    expect(attachment.rank, 3);
    expect(await imageFiles.list(), isEmpty);
  });

  test('stores audio and video in their own folders', () async {
    final clip = File(join(work.path, 'clip.mp4'))..writeAsBytesSync([5, 6]);

    await write(ImportBundle(entries: [
      entryAt(time, attachments: [
        ImportedAttachment(
            type: AttachmentType.video,
            rank: 0,
            timeCreate: time,
            media: FileMedia(clip)),
      ]),
    ]));

    final attachment = EntryAttachmentsProvider.instance.attachments.single;
    expect(attachment.type, AttachmentType.video);
    expect(attachment.filePath, endsWith('.mp4'));
    expect(
        await (await AttachmentStorage.instance
                .internalStore(AttachmentType.video))
            .read(attachment.filePath),
        [5, 6]);
    expect(await imageFiles.list(), isEmpty);
  });

  test('reports progress up to 100%', () async {
    await write(ImportBundle(entries: [
      for (var day = 1; day <= 4; day++) entryAt(DateTime(2025, 6, day)),
    ]));

    expect(statuses, equals(['25%', '50%', '75%', '100%']));
  });

  test('reloads entries, attachments and tags in the providers', () async {
    await write(ImportBundle(entries: [
      entryAt(time,
          tags: [label('Run')],
          attachments: [imageOf(const ReferenceMedia('a.jpg'))]),
    ]));

    expect(EntriesProvider.instance.entries, hasLength(1));
    expect(EntryAttachmentsProvider.instance.attachments, hasLength(1));
    expect(TagsProvider.instance.tags, hasLength(1));
    expect(TagsProvider.instance.entryTags, hasLength(1));
  });

  test('syncs attachments to the external location at the end', () async {
    await ExternalSyncSettings.withDefaults(work.path).save();

    final outcome = await write(ImportBundle(entries: [
      entryAt(time, attachments: [
        imageOf(BytesMedia(Uint8List.fromList([1, 2]))),
      ]),
    ]));

    expect(outcome.succeeded, isTrue);
    final name = EntryAttachmentsProvider.instance.attachments.single.filePath;
    expect(await externalImageFiles.read(name), [1, 2]);
  });

  test('keeps what was written and reports failure when an entry fails',
      () async {
    final outcome = await write(ImportBundle(entries: [
      entryAt(time, text: 'written'),
      entryAt(time.add(const Duration(hours: 1)), attachments: [
        imageOf(FileMedia(File(join(work.path, 'missing.jpg')))),
      ]),
      entryAt(time.add(const Duration(hours: 2)), text: 'never reached'),
    ]));

    expect(outcome.failed, isTrue);
    expect(outcome.error, isNotNull);
    expect(EntriesProvider.instance.entries.map((entry) => entry.text),
        containsAll(['written']));
    expect(EntriesProvider.instance.entries.map((entry) => entry.text),
        isNot(contains('never reached')));
  });
}
