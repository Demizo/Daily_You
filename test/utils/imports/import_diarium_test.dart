// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/database/entry_tag_dao.dart';
import 'package:daily_you/database/tag_dao.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/utils/imports/import_diarium.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  final time = DateTime(2025, 6, 2, 9, 30);

  Map<String, Object?> diariumTag(int id, int type, String value,
          {String? color}) =>
      {'DiaryTagId': id, 'Type': type, 'Value': value, 'Color': color};

  Map<String, Object?> diariumEntryTag(int tagId, {String? value}) =>
      {'DiaryTagId': tagId, 'TrackingValue': value};

  late Database database;

  Future<int> insertEntry() async => await database.insert('entries', {
        'text': '',
        'time_create': time.toIso8601String(),
        'time_modified': time.toIso8601String(),
      });

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    databaseFactory = databaseFactoryFfi;
    database = await databaseFactory.openDatabase(inMemoryDatabasePath);
    AppDatabase.instance.database = database;
    await AppDatabase.instance.createSchema(database);
    await TagsProvider.instance.load();
  });

  tearDown(() async {
    AppDatabase.instance.database = null;
    await database.close();
  });

  group('parseDiariumColor', () {
    test('reads #AARRGGBB', () {
      expect(parseDiariumColor('#FFFFE600'), equals(0xFFFFE600));
    });

    test('returns null for missing or malformed colors', () {
      expect(parseDiariumColor(null), isNull);
      expect(parseDiariumColor(''), isNull);
      expect(parseDiariumColor('yellow'), isNull);
    });
  });

  group('importDiariumTags', () {
    test('maps tags to labels and numeric trackers to trackers', () async {
      final mapping = await importDiariumTags([
        diariumTag(1, 0, 'Thoughts', color: '#FFFFE600'),
        diariumTag(2, 2, 'stress'),
      ]);

      expect(mapping.keys, unorderedEquals([1, 2]));
      expect(mapping[1]!.tagType, equals(TagType.label));
      expect(mapping[1]!.color, equals(0xFFFFE600));
      expect(mapping[1]!.icon, isNull);
      expect(mapping[2]!.tagType, equals(TagType.tracker));
      expect(mapping[2]!.color, isNull);
      expect(await TagDao.getAll(), hasLength(2));
    });

    test('skips text trackers and unknown types', () async {
      final mapping = await importDiariumTags([
        diariumTag(1, 3, 'Text Tracker'),
        diariumTag(2, 1, 'Someone'),
      ]);

      expect(mapping, isEmpty);
      expect(await TagDao.getAll(), isEmpty);
    });

    test('reuses an existing tag with the same name and type', () async {
      final existing = await TagDao.add(Tag(
          name: 'Thoughts',
          tagType: TagType.label,
          color: 0xFF112233,
          timeCreate: time,
          timeModified: time));
      await TagsProvider.instance.load();

      final mapping = await importDiariumTags(
          [diariumTag(1, 0, 'thoughts ', color: '#FFFFE600')]);

      expect(mapping[1]!.id, equals(existing.id));
      final stored = await TagDao.getAll();
      expect(stored, hasLength(1));
      expect(stored.single.color, equals(0xFF112233));
    });

    test('keeps a label and a tracker with the same name separate', () async {
      await TagDao.add(Tag(
          name: 'stress',
          tagType: TagType.label,
          timeCreate: time,
          timeModified: time));
      await TagsProvider.instance.load();

      final mapping = await importDiariumTags([diariumTag(1, 2, 'stress')]);

      expect(mapping[1]!.tagType, equals(TagType.tracker));
      expect(await TagDao.getAll(), hasLength(2));
    });

    test('merges tags in the file that share a name', () async {
      final mapping = await importDiariumTags([
        diariumTag(1, 0, 'Memories'),
        diariumTag(2, 0, 'memories'),
      ]);

      expect(mapping[1]!.id, equals(mapping[2]!.id));
      expect(await TagDao.getAll(), hasLength(1));
    });

    test('appends new tags after existing ones', () async {
      await TagDao.add(Tag(
          name: 'old',
          tagType: TagType.label,
          sortOrder: 4,
          timeCreate: time,
          timeModified: time));
      await TagsProvider.instance.load();

      final mapping = await importDiariumTags([
        diariumTag(1, 0, 'first'),
        diariumTag(2, 0, 'second'),
      ]);

      expect(mapping[1]!.sortOrder, equals(5));
      expect(mapping[2]!.sortOrder, equals(6));
    });
  });

  group('addDiariumEntryTags', () {
    test('attaches labels and tracker values', () async {
      final mapping = await importDiariumTags([
        diariumTag(1, 0, 'Thoughts'),
        diariumTag(2, 2, 'stress'),
      ]);
      final entryId = await insertEntry();

      await addDiariumEntryTags(
          entryId,
          time,
          [
            diariumEntryTag(1),
            diariumEntryTag(2, value: '2.31'),
          ],
          mapping);

      final entryTags = await EntryTagDao.getAll();
      expect(entryTags, hasLength(2));
      final label =
          entryTags.firstWhere((entryTag) => entryTag.tagId == mapping[1]!.id);
      final tracker =
          entryTags.firstWhere((entryTag) => entryTag.tagId == mapping[2]!.id);
      expect(label.value, isNull);
      expect(tracker.value, equals('2.31'));
      expect(tracker.timeCreate, equals(time));
    });

    test('skips tags that were not imported', () async {
      final mapping = await importDiariumTags([diariumTag(1, 3, 'Text')]);
      final entryId = await insertEntry();

      await addDiariumEntryTags(
          entryId, time, [diariumEntryTag(1, value: 'some tag text')], mapping);

      expect(await EntryTagDao.getAll(), isEmpty);
    });

    test('skips trackers without a numeric value', () async {
      final mapping = await importDiariumTags([diariumTag(1, 2, 'stress')]);
      final entryId = await insertEntry();

      await addDiariumEntryTags(
          entryId,
          time,
          [
            diariumEntryTag(1),
            diariumEntryTag(1, value: 'n/a'),
            diariumEntryTag(1, value: 'NaN'),
            diariumEntryTag(1, value: 'Infinity'),
          ],
          mapping);

      expect(await EntryTagDao.getAll(), isEmpty);
    });

    test('attaches a merged tag once per entry', () async {
      final mapping = await importDiariumTags([
        diariumTag(1, 0, 'Memories'),
        diariumTag(2, 0, 'memories'),
      ]);
      final entryId = await insertEntry();

      await addDiariumEntryTags(
          entryId, time, [diariumEntryTag(1), diariumEntryTag(2)], mapping);

      expect(await EntryTagDao.getAll(), hasLength(1));
    });
  });
}
